-- ЛР 12. Функции генерации тестовых данных

-- Случайная строка заданной длины (как в методичке)
CREATE FUNCTION random_string(_length integer) RETURNS text AS $$
DECLARE
    str text;
    res text;
    num integer;
BEGIN
    str := 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890';
    res := '';
    FOR i IN 1.._length LOOP
        num := floor(random() * length(str))::integer + 1;
        res := res || substring(str, num, 1);
    END LOOP;
    RETURN res;
END;
$$ LANGUAGE plpgsql;

-- Случайное целое от _min до _max
CREATE FUNCTION random_int(_min integer, _max integer) RETURNS integer AS $$
BEGIN
    RETURN floor(random() * (_max - _min + 1))::integer + _min;
END;
$$ LANGUAGE plpgsql;

-- Случайная дата между _from и _to
CREATE FUNCTION random_date(_from date, _to date) RETURNS date AS $$
BEGIN
    RETURN _from + random_int(0, _to - _from);
END;
$$ LANGUAGE plpgsql;

-- Случайный элемент массива строк
CREATE FUNCTION random_item(_items text[]) RETURNS text AS $$
BEGIN
    RETURN _items[random_int(1, array_length(_items, 1))];
END;
$$ LANGUAGE plpgsql;

-- Случайное ФИО нужного пола
CREATE FUNCTION random_fio(_gender char(1)) RETURNS text AS $$
BEGIN
    IF _gender = 'М' THEN
        RETURN random_item(ARRAY['Иванов', 'Петров', 'Смирнов', 'Кузнецов', 'Попов', 'Соколов', 'Морозов'])
            || ' ' || random_item(ARRAY['Иван', 'Пётр', 'Алексей', 'Дмитрий', 'Сергей', 'Андрей'])
            || ' ' || random_item(ARRAY['Иванович', 'Петрович', 'Сергеевич', 'Андреевич', 'Олегович']);
    ELSE
        RETURN random_item(ARRAY['Иванова', 'Петрова', 'Смирнова', 'Кузнецова', 'Попова', 'Соколова'])
            || ' ' || random_item(ARRAY['Анна', 'Мария', 'Ольга', 'Елена', 'Ирина', 'Наталья'])
            || ' ' || random_item(ARRAY['Ивановна', 'Петровна', 'Сергеевна', 'Андреевна', 'Олеговна']);
    END IF;
END;
$$ LANGUAGE plpgsql;

-- ===== Заполнение таблиц через функции вставки =====

CREATE FUNCTION generate_departments(_count integer) RETURNS void AS $$
BEGIN
    FOR i IN 1.._count LOOP
        PERFORM insert_department('Отдел ' || random_string(6), random_int(1, 5),
                                  '20-' || random_int(10, 99) || '-' || random_int(10, 99),
                                  random_fio('М'));
    END LOOP;
END;
$$ LANGUAGE plpgsql;

CREATE FUNCTION generate_employees(_count integer) RETURNS void AS $$
DECLARE
    g char(1);
BEGIN
    FOR i IN 1.._count LOOP
        g := random_item(ARRAY['М', 'Ж']);
        PERFORM insert_employee(
            random_fio(g),
            random_item(ARRAY['конструкторы', 'инженеры', 'техники', 'лаборанты', 'прочий обслуживающий персонал']),
            (SELECT id FROM department ORDER BY random() LIMIT 1),
            g,
            'г. ' || random_item(ARRAY['Архангельск', 'Северодвинск', 'Новодвинск']) || ', ул. '
                  || random_item(ARRAY['Ленина', 'Гагарина', 'Морская', 'Садовая']) || ', ' || random_int(1, 120),
            random_date('1960-01-01', '2004-12-31'));
    END LOOP;
END;
$$ LANGUAGE plpgsql;

CREATE FUNCTION generate_organizations(_count integer) RETURNS void AS $$
BEGIN
    FOR i IN 1.._count LOOP
        PERFORM insert_organization(
            random_item(ARRAY['ООО', 'АО', 'ПАО']) || ' "' || random_string(5) || '"',
            random_item(ARRAY['строительство', 'судостроение', 'энергетика', 'транспорт', 'торговля']),
            random_item(ARRAY['Россия', 'Россия', 'Россия', 'Беларусь', 'Казахстан']),
            random_item(ARRAY['Архангельск', 'Москва', 'Минск', 'Астана', 'Мурманск']),
            'ул. ' || random_item(ARRAY['Мира', 'Советская', 'Лесная']) || ', ' || random_int(1, 50),
            random_fio(random_item(ARRAY['М', 'Ж'])));
    END LOOP;
END;
$$ LANGUAGE plpgsql;

CREATE FUNCTION generate_contracts(_count integer) RETURNS void AS $$
BEGIN
    FOR i IN 1.._count LOOP
        PERFORM insert_contract(
            random_date('2020-01-01', current_date),
            (SELECT id FROM organization ORDER BY random() LIMIT 1),
            random_int(50, 2000) * 1000.00);
    END LOOP;
END;
$$ LANGUAGE plpgsql;

CREATE FUNCTION generate_project_works(_count integer) RETURNS void AS $$
DECLARE
    d date;
BEGIN
    FOR i IN 1.._count LOOP
        d := random_date('2020-01-01', current_date);
        PERFORM insert_project_work(
            d,
            CASE WHEN random() < 0.7 THEN d + random_int(30, 365) END,  -- 30% работ ещё не завершены
            (SELECT id FROM contract ORDER BY random() LIMIT 1),
            (SELECT id FROM department ORDER BY random() LIMIT 1));
    END LOOP;
END;
$$ LANGUAGE plpgsql;

-- ===== Вызов: примерно по 100 строк =====
-- SELECT generate_departments(10);
-- SELECT generate_employees(100);
-- SELECT generate_organizations(30);
-- SELECT generate_contracts(100);
-- SELECT generate_project_works(100);
