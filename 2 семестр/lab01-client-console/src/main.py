# ЛР 1. Консольное приложение ИС проектной организации
import os
from getpass import getpass

import psycopg2

import db

POSITIONS = 'конструкторы, инженеры, техники, лаборанты, прочий обслуживающий персонал'


def print_rows(result):
    """Вывод выборки таблицей: заголовок + строки, ширина колонки по самому длинному значению."""
    cols, rows = result
    table = [cols] + [['' if v is None else str(v) for v in row] for row in rows]
    widths = [max(len(r[i]) for r in table) for i in range(len(cols))]
    for i, r in enumerate(table):
        print(' | '.join(v.ljust(w) for v, w in zip(r, widths)))
        if i == 0:
            print('-+-'.join('-' * w for w in widths))
    print('Всего записей:', len(rows))


def added(new_id):
    print('Добавлена запись №', new_id)


def done():
    print('Готово')


def confirm(text):
    return input(text + ' (д/н): ').strip().lower() == 'д'


def run_menu(title, choices, back='Назад'):
    """Меню как в методичке: номер пункта → лямбда с действием; 0 — назад."""
    choice = None
    while choice != 0:
        print()
        print(title)
        for number, (name, _) in choices.items():
            print(f'{number}. {name}')
        print('0.', back)
        text = input('Введите выбранный номер: ')
        choice = int(text) if text.isdigit() else None
        if choice in choices:
            try:
                choices[choice][1]()
            except psycopg2.Error as e:
                print('Ошибка БД:', db.error_text(e))
        elif choice != 0:
            print('Нет такого пункта')


def delete(what, func):
    number = input(f'Номер {what}: ')
    if confirm(f'Удалить запись № {number}?'):
        func(number)
        done()


def department_menu():
    run_menu('Отделы', {
        1: ('Показать отделы', lambda: print_rows(db.get_departments())),
        2: ('Добавить отдел', lambda: added(db.add_department(
            input('Название отдела: '), input('Этаж: '), input('Телефон: '),
            input('ФИО начальника отдела: ')))),
        3: ('Изменить телефон отдела', lambda: (db.change_department_phone(
            input('Номер отдела: '), input('Новый телефон: ')), done())),
        4: ('Удалить отдел', lambda: delete('отдела', db.delete_department)),
        5: ('Поиск отдела', lambda: print_rows(db.find_departments(
            input('Часть названия или ФИО начальника: ')))),
    })


def employee_menu():
    run_menu('Сотрудники', {
        1: ('Показать сотрудников', lambda: print_rows(db.get_employees())),
        2: ('Добавить сотрудника', lambda: added(db.add_employee(
            input('ФИО: '), input(f'Должность ({POSITIONS}): '), input('Номер отдела: '),
            input('Пол (М/Ж): '), input('Адрес: '), input('Дата рождения (ГГГГ-ММ-ДД): ')))),
        3: ('Изменить адрес сотрудника', lambda: (db.change_employee_address(
            input('Номер сотрудника: '), input('Новый адрес: ')), done())),
        4: ('Удалить сотрудника', lambda: delete('сотрудника', db.delete_employee)),
        5: ('Поиск сотрудника', lambda: print_rows(db.find_employees(
            input('Часть ФИО или адреса: ')))),
    })


def organization_menu():
    run_menu('Организации', {
        1: ('Показать организации', lambda: print_rows(db.get_organizations())),
        2: ('Добавить организацию', lambda: added(db.add_organization(
            input('Название: '), input('Тип деятельности: '), input('Страна (пусто — Россия): '),
            input('Город: '), input('Адрес: '), input('ФИО директора: ')))),
        3: ('Изменить директора организации', lambda: (db.change_organization_director(
            input('Номер организации: '), input('ФИО нового директора: ')), done())),
        4: ('Удалить организацию (вместе с её договорами)',
            lambda: delete('организации', db.delete_organization)),
        5: ('Поиск организации', lambda: print_rows(db.find_organizations(
            input('Часть названия, города или ФИО директора: ')))),
    })


def contract_menu():
    run_menu('Договоры', {
        1: ('Показать договоры', lambda: print_rows(db.get_contracts())),
        2: ('Добавить новый договор', lambda: added(db.add_contract(
            input('Дата заключения (ГГГГ-ММ-ДД, пусто — сегодня): '), input('Номер организации: '),
            input('Стоимость: ')))),
        3: ('Изменить стоимость договора', lambda: (db.change_contract_cost(
            input('Номер договора: '), input('Новая стоимость: ')), done())),
        4: ('Удалить договор (вместе с его работами)', lambda: delete('договора', db.delete_contract)),
        5: ('Поиск договора', lambda: print_rows(db.find_contracts(
            input('Часть названия организации: ')))),
    })


def project_work_menu():
    run_menu('Проектные работы', {
        1: ('Показать проектные работы', lambda: print_rows(db.get_project_works())),
        2: ('Добавить проектную работу', lambda: added(db.add_project_work(
            input('Дата начала (ГГГГ-ММ-ДД): '), input('Дата завершения (пусто — не завершена): '),
            input('Номер договора: '), input('Номер отдела: ')))),
        3: ('Изменить дату завершения', lambda: (db.change_project_work_end_date(
            input('Номер проектной работы: '), input('Дата завершения (ГГГГ-ММ-ДД): ')), done())),
        4: ('Удалить проектную работу', lambda: delete('проектной работы', db.delete_project_work)),
        5: ('Поиск проектной работы', lambda: print_rows(db.find_project_works(
            input('Часть названия отдела: ')))),
    })


def restore():
    folders = sorted(os.listdir('backup')) if os.path.isdir('backup') else []
    if not folders:
        print('Резервных копий нет')
        return
    for name in folders:
        print(' ', name)
    folder = input('Имя копии: ')
    if confirm('Текущие данные будут заменены данными копии. Продолжить?'):
        db.restore(os.path.join('backup', folder))
        done()


def admin_menu():
    run_menu('Администрирование', {
        1: ('Показать пользователей', lambda: print_rows(db.get_users())),
        2: ('Создать резервную копию', lambda: print('Копия сохранена в', db.backup())),
        3: ('Восстановить из резервной копии', restore),
    })


def auth():
    """Аутентификация: логин и пароль от БД rpr, 3 попытки."""
    print('Вход в ИС проектной организации')
    for _ in range(3):
        user = input('login: ')
        password = getpass('password: ')
        try:
            db.login(user, password)
            return True
        except psycopg2.OperationalError as e:
            print('Не удалось войти:', db.error_text(e))
    return False


def run():
    if not auth():
        return
    run_menu('Главное меню', {
        1: ('Отделы', department_menu),
        2: ('Сотрудники', employee_menu),
        3: ('Организации', organization_menu),
        4: ('Договоры', contract_menu),
        5: ('Проектные работы', project_work_menu),
        6: ('Администрирование', admin_menu),
    }, back='Выход')


if __name__ == '__main__':
    run()
