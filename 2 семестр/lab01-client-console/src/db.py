# Работа с БД rpr: подключение и вызов хранимых функций из ЛР 12–13
import os
from datetime import datetime

import psycopg2

# Сервер и БД. Для проверки дома: RPR_HOST=localhost RPR_DB=rpr_lab python main.py
HOST = os.environ.get('RPR_HOST', '10.22.31.252')
DBNAME = os.environ.get('RPR_DB', 'rpr')

# Порядок таблиц: сначала родительские, потом дочерние (из-за внешних ключей)
TABLES = ['department', 'organization', 'employee', 'contract', 'project_work']

conn_params = {}


def login(user, password):
    """Аутентификация: пробуем подключиться, при успехе запоминаем параметры."""
    params = dict(host=HOST, dbname=DBNAME, user=user, password=password)
    conn = psycopg2.connect(**params)
    conn.close()
    conn_params.update(params)


def error_text(e):
    """Понятный текст ошибки БД (в т.ч. RAISE EXCEPTION из триггеров ЛР 14)."""
    if getattr(e, 'diag', None) and e.diag.message_primary:
        return e.diag.message_primary
    return str(e).strip()


def fetch(sql, args=None):
    """Выборка: возвращает названия колонок и строки."""
    conn = psycopg2.connect(**conn_params)
    cur = conn.cursor()
    cur.execute(sql, args)
    cols = [d[0] for d in cur.description]
    rows = cur.fetchall()
    cur.close()
    conn.close()
    return cols, rows


def call(func, args):
    """Вызов хранимой функции и фиксация изменений. Пустая строка = NULL."""
    args = [None if a == '' else a for a in args]
    conn = psycopg2.connect(**conn_params)
    cur = conn.cursor()
    try:
        cur.callproc(func, args)
        row = cur.fetchone()
        conn.commit()
    finally:
        cur.close()
        conn.close()
    return row[0] if row else None


def like(part):
    return {'p': '%' + part + '%'}


# ===== Отделы =====

def get_departments():
    return fetch('select * from department order by id')


def find_departments(part):
    return fetch('select * from department where name ilike %(p)s or head_name ilike %(p)s order by id',
                 like(part))


def add_department(name, floor, phone, head_name):
    return call('insert_department', [name, floor, phone, head_name])


def change_department_phone(dep_id, phone):
    call('update_department_phone', [phone, dep_id])


def delete_department(dep_id):
    call('delete_department', [dep_id])


# ===== Сотрудники =====

def get_employees():
    return fetch('select * from employee order by id')


def find_employees(part):
    # функция поиска по части фразы из ЛР 13
    return fetch('select * from find_employees(%s) order by id', [part])


def add_employee(full_name, position, department_id, gender, address, birth_date):
    return call('insert_employee', [full_name, position, department_id, gender, address, birth_date])


def change_employee_address(emp_id, address):
    call('update_employee_address', [address, emp_id])


def delete_employee(emp_id):
    call('delete_employee', [emp_id])


# ===== Организации =====

def get_organizations():
    return fetch('select * from organization order by id')


def find_organizations(part):
    return fetch('select * from organization'
                 ' where name ilike %(p)s or city ilike %(p)s or director_name ilike %(p)s order by id',
                 like(part))


def add_organization(name, activity_type, country, city, address, director_name):
    return call('insert_organization', [name, activity_type, country, city, address, director_name])


def change_organization_director(org_id, director_name):
    call('update_organization_director', [director_name, org_id])


def delete_organization(org_id):
    call('delete_organization', [org_id])


# ===== Договоры =====

def get_contracts():
    return fetch('select * from contract order by id')


def find_contracts(part):
    # по названию организации-заказчика
    return fetch('select c.* from contract c join organization o on o.id = c.organization_id'
                 ' where o.name ilike %(p)s order by c.id', like(part))


def add_contract(conclusion_date, organization_id, cost):
    return call('insert_contract', [conclusion_date, organization_id, cost])


def change_contract_cost(contract_id, cost):
    call('update_contract_cost', [cost, contract_id])


def delete_contract(contract_id):
    call('delete_contract', [contract_id])


# ===== Проектные работы =====

def get_project_works():
    return fetch('select * from project_work order by id')


def find_project_works(part):
    # по названию отдела-разработчика
    return fetch('select w.* from project_work w join department d on d.id = w.department_id'
                 ' where d.name ilike %(p)s order by w.id', like(part))


def add_project_work(start_date, end_date, contract_id, department_id):
    return call('insert_project_work', [start_date, end_date, contract_id, department_id])


def change_project_work_end_date(work_id, end_date):
    call('update_project_work_end_date', [end_date, work_id])


def delete_project_work(work_id):
    call('delete_project_work', [work_id])


# ===== Администрирование =====

def get_users():
    """Пользователи ИС = роли PostgreSQL, которым разрешён вход."""
    return fetch('select rolname as login from pg_roles where rolcanlogin order by rolname')


def backup(parent_dir='backup'):
    """Резервная копия: каждая таблица выгружается в CSV. Возвращает папку копии."""
    folder = os.path.join(parent_dir, datetime.now().strftime('%Y-%m-%d_%H-%M-%S'))
    os.makedirs(folder)
    conn = psycopg2.connect(**conn_params)
    cur = conn.cursor()
    for table in TABLES:
        with open(os.path.join(folder, table + '.csv'), 'w', encoding='utf-8') as f:
            cur.copy_expert(f'copy {table} to stdout with csv header', f)
    cur.close()
    conn.close()
    return folder


def restore(folder):
    """Восстановление: очистить таблицы и загрузить CSV — всё в одной транзакции."""
    conn = psycopg2.connect(**conn_params)
    cur = conn.cursor()
    try:
        cur.execute('truncate ' + ', '.join(TABLES))
        for table in TABLES:
            with open(os.path.join(folder, table + '.csv'), encoding='utf-8') as f:
                cur.copy_expert(f'copy {table} from stdin with csv header', f)
            # счётчик serial продолжает нумерацию после восстановленных id
            cur.execute(f"select setval(pg_get_serial_sequence('{table}', 'id'),"
                        f" coalesce(max(id), 0) + 1, false) from {table}")
        conn.commit()
    finally:
        cur.close()
        conn.close()
