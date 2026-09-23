-- ЛР 10. Таблицы ИС проектной организации (PostgreSQL)
-- В DBeaver: открыть SQL-редактор своей схемы и выполнить скрипт (Alt+X)
-- или создать то же самое через Create New Table, как в методичке.

-- 1. Отделы
CREATE TABLE department (
    id         serial PRIMARY KEY,
    name       text    NOT NULL UNIQUE,
    floor      integer NOT NULL DEFAULT 1 CHECK (floor > 0),
    phone      text    NOT NULL,
    head_name  text
);
COMMENT ON TABLE  department           IS 'Отделы проектной организации';
COMMENT ON COLUMN department.id        IS 'Номер отдела (автоинкремент)';
COMMENT ON COLUMN department.name      IS 'Название отдела';
COMMENT ON COLUMN department.floor     IS 'Этаж, на котором расположен отдел';
COMMENT ON COLUMN department.phone     IS 'Телефон отдела';
COMMENT ON COLUMN department.head_name IS 'ФИО начальника отдела';

-- 2. Сотрудники
CREATE TABLE employee (
    id            serial  PRIMARY KEY,
    full_name     text    NOT NULL,
    position      text    NOT NULL DEFAULT 'инженеры'
                  CHECK (position IN ('конструкторы', 'инженеры', 'техники', 'лаборанты',
                                      'прочий обслуживающий персонал')),
    department_id integer NOT NULL REFERENCES department (id),
    gender        char(1) NOT NULL DEFAULT 'М' CHECK (gender IN ('М', 'Ж')),
    address       text,
    birth_date    date    NOT NULL CHECK (birth_date < current_date)
);
COMMENT ON TABLE  employee               IS 'Сотрудники проектной организации';
COMMENT ON COLUMN employee.id            IS 'Номер сотрудника (автоинкремент)';
COMMENT ON COLUMN employee.full_name     IS 'ФИО сотрудника';
COMMENT ON COLUMN employee.position      IS 'Должность: конструкторы, инженеры, техники, лаборанты, прочий обслуживающий персонал';
COMMENT ON COLUMN employee.department_id IS 'Номер отдела, в котором работает сотрудник';
COMMENT ON COLUMN employee.gender        IS 'Пол: М или Ж';
COMMENT ON COLUMN employee.address       IS 'Адрес сотрудника';
COMMENT ON COLUMN employee.birth_date    IS 'Дата рождения (не позже текущей даты)';

-- 3. Организации
CREATE TABLE organization (
    id            serial PRIMARY KEY,
    name          text NOT NULL,
    activity_type text NOT NULL,
    country       text NOT NULL DEFAULT 'Россия',
    city          text NOT NULL,
    address       text,
    director_name text NOT NULL
);
COMMENT ON TABLE  organization               IS 'Организации-заказчики';
COMMENT ON COLUMN organization.id            IS 'Номер организации (автоинкремент)';
COMMENT ON COLUMN organization.name          IS 'Название организации';
COMMENT ON COLUMN organization.activity_type IS 'Тип деятельности';
COMMENT ON COLUMN organization.country       IS 'Страна';
COMMENT ON COLUMN organization.city          IS 'Город';
COMMENT ON COLUMN organization.address       IS 'Адрес организации';
COMMENT ON COLUMN organization.director_name IS 'ФИО директора';

-- 4. Договоры
CREATE TABLE contract (
    id              serial        PRIMARY KEY,
    conclusion_date date          NOT NULL DEFAULT current_date CHECK (conclusion_date <= current_date),
    organization_id integer       NOT NULL REFERENCES organization (id),
    cost            numeric(12,2) NOT NULL CHECK (cost > 0)
);
COMMENT ON TABLE  contract                 IS 'Договоры с организациями';
COMMENT ON COLUMN contract.id              IS 'Номер договора (автоинкремент)';
COMMENT ON COLUMN contract.conclusion_date IS 'Дата заключения договора';
COMMENT ON COLUMN contract.organization_id IS 'Организация, с которой заключён договор';
COMMENT ON COLUMN contract.cost            IS 'Стоимость договора, руб.';

-- 5. Проектные работы
CREATE TABLE project_work (
    id            serial  PRIMARY KEY,
    start_date    date    NOT NULL DEFAULT current_date,
    end_date      date,
    contract_id   integer NOT NULL REFERENCES contract (id),
    department_id integer NOT NULL REFERENCES department (id),
    CHECK (end_date IS NULL OR end_date >= start_date)
);
COMMENT ON TABLE  project_work               IS 'Проектные работы по договорам';
COMMENT ON COLUMN project_work.id            IS 'Номер проектной работы (автоинкремент)';
COMMENT ON COLUMN project_work.start_date    IS 'Дата начала проектной работы';
COMMENT ON COLUMN project_work.end_date      IS 'Дата завершения проектной работы (не раньше даты начала)';
COMMENT ON COLUMN project_work.contract_id   IS 'Номер договора';
COMMENT ON COLUMN project_work.department_id IS 'Отдел, осуществляющий разработку';
