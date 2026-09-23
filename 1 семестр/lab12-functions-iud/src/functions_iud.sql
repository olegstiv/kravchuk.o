-- ЛР 12. Функции модификации данных: вставка, удаление, обновление

-- ===== Вставка: значения передаются параметрами, возвращается номер новой записи =====

CREATE FUNCTION insert_department(_name text, _floor integer, _phone text, _head_name text)
RETURNS integer AS $$
    INSERT INTO department (name, floor, phone, head_name)
    VALUES (_name, _floor, _phone, _head_name)
    RETURNING id;
$$ LANGUAGE sql;

CREATE FUNCTION insert_employee(_full_name text, _position text, _department_id integer,
                                _gender char(1), _address text, _birth_date date)
RETURNS integer AS $$
    INSERT INTO employee (full_name, position, department_id, gender, address, birth_date)
    VALUES (_full_name, _position, _department_id, _gender, _address, _birth_date)
    RETURNING id;
$$ LANGUAGE sql;

CREATE FUNCTION insert_organization(_name text, _activity_type text, _country text,
                                    _city text, _address text, _director_name text)
RETURNS integer AS $$
    INSERT INTO organization (name, activity_type, country, city, address, director_name)
    VALUES (_name, _activity_type, _country, _city, _address, _director_name)
    RETURNING id;
$$ LANGUAGE sql;

CREATE FUNCTION insert_contract(_conclusion_date date, _organization_id integer, _cost numeric)
RETURNS integer AS $$
    INSERT INTO contract (conclusion_date, organization_id, cost)
    VALUES (_conclusion_date, _organization_id, _cost)
    RETURNING id;
$$ LANGUAGE sql;

CREATE FUNCTION insert_project_work(_start_date date, _end_date date,
                                    _contract_id integer, _department_id integer)
RETURNS integer AS $$
    INSERT INTO project_work (start_date, end_date, contract_id, department_id)
    VALUES (_start_date, _end_date, _contract_id, _department_id)
    RETURNING id;
$$ LANGUAGE sql;

-- ===== Удаление: параметр — значение для условия удаления (номер записи) =====

CREATE FUNCTION delete_department(_id integer) RETURNS void AS $$
    DELETE FROM department WHERE id = _id;
$$ LANGUAGE sql;

CREATE FUNCTION delete_employee(_id integer) RETURNS void AS $$
    DELETE FROM employee WHERE id = _id;
$$ LANGUAGE sql;

CREATE FUNCTION delete_organization(_id integer) RETURNS void AS $$
    DELETE FROM organization WHERE id = _id;
$$ LANGUAGE sql;

CREATE FUNCTION delete_contract(_id integer) RETURNS void AS $$
    DELETE FROM contract WHERE id = _id;
$$ LANGUAGE sql;

CREATE FUNCTION delete_project_work(_id integer) RETURNS void AS $$
    DELETE FROM project_work WHERE id = _id;
$$ LANGUAGE sql;

-- ===== Обновление: новое значение + параметр условия =====

CREATE FUNCTION update_department_phone(_new_phone text, _id integer) RETURNS void AS $$
    UPDATE department SET phone = _new_phone WHERE id = _id;
$$ LANGUAGE sql;

CREATE FUNCTION update_employee_address(_new_address text, _id integer) RETURNS void AS $$
    UPDATE employee SET address = _new_address WHERE id = _id;
$$ LANGUAGE sql;

CREATE FUNCTION update_organization_director(_new_director text, _id integer) RETURNS void AS $$
    UPDATE organization SET director_name = _new_director WHERE id = _id;
$$ LANGUAGE sql;

CREATE FUNCTION update_contract_cost(_new_cost numeric, _id integer) RETURNS void AS $$
    UPDATE contract SET cost = _new_cost WHERE id = _id;
$$ LANGUAGE sql;

CREATE FUNCTION update_project_work_end_date(_new_end_date date, _id integer) RETURNS void AS $$
    UPDATE project_work SET end_date = _new_end_date WHERE id = _id;
$$ LANGUAGE sql;
