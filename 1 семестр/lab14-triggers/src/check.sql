-- ЛР 14. Проверка триггеров (каждый блок — отдельный скриншот)

-- 1. Каскадное удаление: считаем договоры и работы организации 1, удаляем, считаем снова
SELECT count(*) FROM contract WHERE organization_id = 1;
SELECT count(*) FROM project_work WHERE contract_id IN (SELECT id FROM contract WHERE organization_id = 1);
DELETE FROM organization WHERE id = 1;
SELECT count(*) FROM contract WHERE organization_id = 1;          -- 0

-- 2. Вставка: дата подставится текущая, страна — по умолчанию
INSERT INTO contract (conclusion_date, organization_id, cost) VALUES (NULL, 2, 50000);
SELECT * FROM contract ORDER BY id DESC LIMIT 1;                   -- дата = сегодня
INSERT INTO organization (name, activity_type, country, city, director_name)
VALUES ('ООО "Тест"', 'торговля', '', 'Архангельск', 'Тестов Тест Тестович');
SELECT * FROM organization ORDER BY id DESC LIMIT 1;               -- страна = Россия
INSERT INTO organization (name, activity_type, city, director_name)
VALUES ('   ', 'торговля', 'Архангельск', 'Тестов Тест Тестович'); -- ошибка: пустое название

-- 3. Обновление: дата завершения раньше даты начала — ошибка
UPDATE project_work SET end_date = start_date - 10 WHERE id = 2;

-- 4. Аудит: последние действия
SELECT * FROM audit_log ORDER BY id DESC LIMIT 10;
