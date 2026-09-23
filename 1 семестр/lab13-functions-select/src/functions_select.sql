-- ЛР 13. Функции выборки данных

-- 1. Статистика по стоимости договоров. Аргумент — показатель: 'min', 'max' или 'avg'
CREATE FUNCTION contract_cost_stat(_indicator text) RETURNS numeric AS $$
DECLARE
    res numeric;
BEGIN
    IF _indicator = 'min' THEN
        SELECT min(cost) INTO res FROM contract;
    ELSIF _indicator = 'max' THEN
        SELECT max(cost) INTO res FROM contract;
    ELSIF _indicator = 'avg' THEN
        SELECT round(avg(cost), 2) INTO res FROM contract;
    ELSE
        RAISE EXCEPTION 'Неизвестный показатель: %. Допустимо: min, max, avg', _indicator;
    END IF;
    RETURN res;
END;
$$ LANGUAGE plpgsql;

-- 2. Поиск сотрудников по части фразы (в ФИО или адресе)
CREATE FUNCTION find_employees(_part text) RETURNS SETOF employee AS $$
    SELECT * FROM employee
    WHERE full_name ILIKE '%' || _part || '%'
       OR address   ILIKE '%' || _part || '%';
$$ LANGUAGE sql;

-- 3а. Конкатенация: полный адрес организации одной строкой
CREATE FUNCTION organization_full_address(_id integer) RETURNS text AS $$
    SELECT country || ', г. ' || city || ', ' || coalesce(address, 'адрес не указан')
    FROM organization
    WHERE id = _id;
$$ LANGUAGE sql;

-- 3б. Конкатенация полей двух таблиц: «ФИО — должность (отдел)»
CREATE FUNCTION employee_card(_id integer) RETURNS text AS $$
    SELECT e.full_name || ' — ' || e.position || ' (' || d.name || ')'
    FROM employee e
    JOIN department d ON d.id = e.department_id
    WHERE e.id = _id;
$$ LANGUAGE sql;

-- 4. Доля сотрудников с указанной должностью, в процентах
CREATE FUNCTION position_share(_position text) RETURNS numeric AS $$
    SELECT round((SELECT count(*) FROM employee WHERE position = _position) * 100.0
                 / (SELECT count(*) FROM employee), 2);
$$ LANGUAGE sql;
