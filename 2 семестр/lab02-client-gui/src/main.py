# ЛР 2. Приложение с GUI (wxPython) для ИС проектной организации
import wx
import wx.grid
import psycopg2

import db

NEW_ROW_COLOUR = wx.Colour(255, 250, 205)   # новая, ещё не сохранённая строка
EDIT_COLOUR = wx.Colour(220, 245, 220)      # колонка, которую можно изменить
HINT_COLOUR = wx.Colour(128, 128, 128)

# Описание вкладок: колонки таблицы и функции db.py для каждого варианта использования.
# change_col — номер колонки, которую меняет функция update_* из ЛР 12.
ENTITIES = [
    dict(title='Отделы',
         columns=['Номер', 'Название', 'Этаж', 'Телефон', 'Начальник отдела'],
         load=db.get_departments, find=db.find_departments, add=db.add_department,
         change=db.change_department_phone, change_col=3, delete=db.delete_department,
         find_hint='часть названия или ФИО начальника'),
    dict(title='Сотрудники',
         columns=['Номер', 'ФИО', 'Должность', 'Номер отдела', 'Пол', 'Адрес', 'Дата рождения'],
         load=db.get_employees, find=db.find_employees, add=db.add_employee,
         change=db.change_employee_address, change_col=5, delete=db.delete_employee,
         find_hint='часть ФИО или адреса'),
    dict(title='Организации',
         columns=['Номер', 'Название', 'Тип деятельности', 'Страна', 'Город', 'Адрес', 'ФИО директора'],
         load=db.get_organizations, find=db.find_organizations, add=db.add_organization,
         change=db.change_organization_director, change_col=6, delete=db.delete_organization,
         find_hint='часть названия, города или ФИО директора'),
    dict(title='Договоры',
         columns=['Номер договора', 'Дата заключения', 'Номер организации', 'Стоимость'],
         load=db.get_contracts, find=db.find_contracts, add=db.add_contract,
         change=db.change_contract_cost, change_col=3, delete=db.delete_contract,
         find_hint='часть названия организации'),
    dict(title='Проектные работы',
         columns=['Номер', 'Дата начала', 'Дата завершения', 'Номер договора', 'Номер отдела'],
         load=db.get_project_works, find=db.find_project_works, add=db.add_project_work,
         change=db.change_project_work_end_date, change_col=2, delete=db.delete_project_work,
         find_hint='часть названия отдела'),
]


def show_error(e):
    wx.MessageBox(db.error_text(e), 'Ошибка БД', wx.OK | wx.ICON_ERROR)


def hint(parent, text):
    label = wx.StaticText(parent, -1, text)
    label.SetForegroundColour(HINT_COLOUR)
    return label


class EntityPanel(wx.Panel):
    """Вкладка «Управление …»: просмотр, поиск, добавление, изменение, удаление."""

    def __init__(self, parent, entity):
        wx.Panel.__init__(self, parent, -1)
        self.entity = entity
        self.loaded = 0          # сколько строк загружено из БД; ниже них — новые строки
        columns = entity['columns']

        self.search_text = wx.TextCtrl(self, -1, size=(250, -1), style=wx.TE_PROCESS_ENTER)
        self.search = wx.Button(self, -1, 'Найти')
        self.show_all = wx.Button(self, -1, 'Показать все')

        self.grid = wx.grid.Grid(self, -1)
        self.grid.CreateGrid(0, len(columns))
        self.grid.SetRowLabelSize(40)
        for col, name in enumerate(columns):
            self.grid.SetColLabelValue(col, name)

        self.download = wx.Button(self, -1, 'Загрузить')
        self.new_row = wx.Button(self, -1, 'Новая строка')
        self.new = wx.Button(self, -1, 'Добавить')
        self.update = wx.Button(self, -1, 'Изменить')
        self.delete = wx.Button(self, -1, 'Удалить')

        change_name = columns[entity['change_col']]
        help_text = (f'Поиск: {entity["find_hint"]}.\n'
                     f'Добавить: «Новая строка» (или Insert) → заполнить → «Добавить». '
                     f'Изменить можно только колонку «{change_name}» (зелёная) → «Изменить».')

        self.Bind(wx.EVT_BUTTON, self.on_search, self.search)
        self.Bind(wx.EVT_TEXT_ENTER, self.on_search, self.search_text)
        self.Bind(wx.EVT_BUTTON, self.on_download, self.show_all)
        self.Bind(wx.EVT_BUTTON, self.on_download, self.download)
        self.Bind(wx.EVT_BUTTON, self.on_new_row, self.new_row)
        self.Bind(wx.EVT_BUTTON, self.on_new, self.new)
        self.Bind(wx.EVT_BUTTON, self.on_update, self.update)
        self.Bind(wx.EVT_BUTTON, self.on_delete, self.delete)
        self.grid.Bind(wx.EVT_KEY_DOWN, self.keydown)

        search_sizer = wx.BoxSizer(wx.HORIZONTAL)
        search_sizer.Add(wx.StaticText(self, -1, 'Поиск:'), 0, wx.ALIGN_CENTER_VERTICAL | wx.RIGHT, 5)
        search_sizer.AddMany([(self.search_text, 0), (self.search, 0, wx.LEFT, 5),
                              (self.show_all, 0, wx.LEFT, 5)])
        buttons = wx.BoxSizer(wx.HORIZONTAL)
        for button in (self.download, self.new_row, self.new, self.update, self.delete):
            buttons.Add(button, 1, wx.EXPAND)

        sizer = wx.BoxSizer(wx.VERTICAL)
        sizer.Add(search_sizer, 0, wx.ALL, 5)
        sizer.Add(self.grid, 1, wx.EXPAND | wx.LEFT | wx.RIGHT, 5)
        sizer.Add(hint(self, help_text), 0, wx.ALL, 5)
        sizer.Add(buttons, 0, wx.EXPAND | wx.ALL, 5)
        self.SetSizer(sizer)

    def show(self, result):
        """Занести выборку в Grid. Номер и все колонки, кроме изменяемой, — только чтение."""
        cols, rows = result
        grid = self.grid
        if grid.GetNumberRows():
            grid.DeleteRows(0, grid.GetNumberRows())
        grid.AppendRows(len(rows))
        for i, row in enumerate(rows):
            for col in range(len(cols)):
                grid.SetCellValue(i, col, '' if row[col] is None else str(row[col]))
                grid.SetReadOnly(i, col, col != self.entity['change_col'])
            grid.SetCellBackgroundColour(i, self.entity['change_col'], EDIT_COLOUR)
        self.loaded = len(rows)
        grid.AutoSizeColumns(False)
        grid.ForceRefresh()

    def run(self, action):
        """Выполнить действие с БД; ошибку показать сообщением, а не трассировкой."""
        if self.grid.IsCellEditControlEnabled():
            self.grid.DisableCellEditControl()   # сохранить значение, которое ещё редактируется
        try:
            return action()
        except psycopg2.Error as e:
            show_error(e)

    def on_download(self, event):
        self.search_text.SetValue('')
        self.run(lambda: self.show(self.entity['load']()))

    def on_search(self, event):
        self.run(lambda: self.show(self.entity['find'](self.search_text.GetValue())))

    def keydown(self, event):
        if event.GetKeyCode() == wx.WXK_INSERT:
            self.on_new_row(event)
        else:
            event.Skip()

    def on_new_row(self, event):
        row = self.grid.GetNumberRows()
        self.grid.AppendRows(1)
        self.grid.SetReadOnly(row, 0, True)      # номер присвоит БД (serial)
        for col in range(self.grid.GetNumberCols()):
            self.grid.SetCellBackgroundColour(row, col, NEW_ROW_COLOUR)
        self.grid.SetGridCursor(row, 1)
        self.grid.MakeCellVisible(row, 1)
        self.grid.SetFocus()

    def cursor_row(self, new):
        """Строка под курсором: новая (new=True) или загруженная из БД."""
        row = self.grid.GetGridCursorRow()
        if row < 0 or (row >= self.loaded) != new:
            if new:
                text = 'Встаньте на новую строку: «Новая строка» или Insert, затем заполните её.'
            else:
                text = 'Выберите строку, загруженную из БД.'
            wx.MessageBox(text, 'Подсказка', wx.OK | wx.ICON_INFORMATION)
            return None
        return row

    def on_new(self, event):
        row = self.cursor_row(new=True)
        if row is None:
            return
        values = [self.grid.GetCellValue(row, col) for col in range(1, self.grid.GetNumberCols())]
        new_id = self.run(lambda: self.entity['add'](*values))
        if new_id is not None:
            self.on_download(event)
            wx.MessageBox(f'Добавлена запись № {new_id}', 'Готово')

    def on_update(self, event):
        row = self.cursor_row(new=False)
        if row is None:
            return
        record_id = self.grid.GetCellValue(row, 0)
        value = self.grid.GetCellValue(row, self.entity['change_col'])
        self.run(lambda: self.entity['change'](record_id, value))
        self.on_download(event)

    def on_delete(self, event):
        row = self.cursor_row(new=False)
        if row is None:
            return
        record_id = self.grid.GetCellValue(row, 0)
        if wx.MessageBox(f'Удалить запись № {record_id}?', 'Удаление',
                         wx.YES_NO | wx.ICON_QUESTION) == wx.YES:
            self.run(lambda: self.entity['delete'](record_id))
            self.on_download(event)


class AdminPanel(wx.Panel):
    """Вкладка «Администрирование»: пользователи ИС и резервное копирование."""

    def __init__(self, parent):
        wx.Panel.__init__(self, parent, -1)
        self.users = wx.ListBox(self, -1)
        self.show_users = wx.Button(self, -1, 'Показать пользователей')
        self.backup = wx.Button(self, -1, 'Создать резервную копию')
        self.restore = wx.Button(self, -1, 'Восстановить из резервной копии')

        self.Bind(wx.EVT_BUTTON, self.on_show_users, self.show_users)
        self.Bind(wx.EVT_BUTTON, self.on_backup, self.backup)
        self.Bind(wx.EVT_BUTTON, self.on_restore, self.restore)

        buttons = wx.BoxSizer(wx.VERTICAL)
        for button in (self.show_users, self.backup, self.restore):
            buttons.Add(button, 0, wx.EXPAND | wx.BOTTOM, 5)
        buttons.Add(hint(self, 'Копия — папка с CSV-файлами всех таблиц.\n'
                               'Восстановление заменяет текущие данные.'), 0, wx.TOP, 5)
        sizer = wx.BoxSizer(wx.HORIZONTAL)
        sizer.Add(self.users, 1, wx.EXPAND | wx.ALL, 5)
        sizer.Add(buttons, 0, wx.ALL, 5)
        self.SetSizer(sizer)

    def on_show_users(self, event):
        try:
            cols, rows = db.get_users()
        except psycopg2.Error as e:
            show_error(e)
            return
        self.users.Set([row[0] for row in rows])

    def on_backup(self, event):
        dlg = wx.DirDialog(self, 'Папка для резервных копий')
        if dlg.ShowModal() == wx.ID_OK:
            try:
                folder = db.backup(dlg.GetPath())
                wx.MessageBox(f'Копия сохранена в\n{folder}', 'Готово')
            except (psycopg2.Error, OSError) as e:
                show_error(e)
        dlg.Destroy()

    def on_restore(self, event):
        dlg = wx.DirDialog(self, 'Папка резервной копии (с CSV-файлами)')
        if dlg.ShowModal() == wx.ID_OK and wx.MessageBox(
                'Текущие данные будут заменены данными копии. Продолжить?', 'Восстановление',
                wx.YES_NO | wx.ICON_WARNING) == wx.YES:
            try:
                db.restore(dlg.GetPath())
                wx.MessageBox('Данные восстановлены', 'Готово')
            except (psycopg2.Error, OSError) as e:
                show_error(e)
        dlg.Destroy()


class LoginDialog(wx.Dialog):
    """Аутентификация: логин и пароль от БД rpr."""

    def __init__(self):
        wx.Dialog.__init__(self, None, -1, 'Вход в ИС проектной организации')
        self.login = wx.TextCtrl(self, -1, size=(200, -1))
        self.password = wx.TextCtrl(self, -1, size=(200, -1), style=wx.TE_PASSWORD)

        fields = wx.FlexGridSizer(2, 2, 5, 5)
        fields.AddMany([(wx.StaticText(self, -1, 'login'), 0, wx.ALIGN_CENTER_VERTICAL), (self.login, 1),
                        (wx.StaticText(self, -1, 'password'), 0, wx.ALIGN_CENTER_VERTICAL),
                        (self.password, 1)])
        sizer = wx.BoxSizer(wx.VERTICAL)
        sizer.Add(fields, 0, wx.ALL, 10)
        sizer.Add(self.CreateButtonSizer(wx.OK | wx.CANCEL), 0, wx.EXPAND | wx.ALL, 10)
        self.SetSizerAndFit(sizer)
        self.Centre()


class DatabaseFrame(wx.Frame):
    """Главное окно: вкладка на каждую сущность + администрирование."""

    def __init__(self, user):
        wx.Frame.__init__(self, None, -1, f'ИС проектной организации — {user}', size=(950, 600))
        self.notebook = wx.Notebook(self, -1)
        for entity in ENTITIES:
            panel = EntityPanel(self.notebook, entity)
            self.notebook.AddPage(panel, entity['title'])
            panel.on_download(None)
        self.notebook.AddPage(AdminPanel(self.notebook), 'Администрирование')
        self.Centre()


def main():
    app = wx.App()
    dlg = LoginDialog()
    while True:
        if dlg.ShowModal() != wx.ID_OK:
            dlg.Destroy()
            return
        try:
            db.login(dlg.login.GetValue(), dlg.password.GetValue())
            break
        except psycopg2.OperationalError as e:
            wx.MessageBox(db.error_text(e), 'Не удалось войти', wx.OK | wx.ICON_ERROR)
    user = dlg.login.GetValue()
    dlg.Destroy()
    frame = DatabaseFrame(user)
    frame.Show()
    app.MainLoop()


if __name__ == '__main__':
    main()
