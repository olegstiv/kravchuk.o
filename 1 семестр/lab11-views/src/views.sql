-- ЛР 11. Виды (представления)

-- 1. Условие фильтрации: сотрудники-инженеры
CREATE VIEW v_engineers AS
SELECT full_name, department_id, birth_date
FROM employee
WHERE position = 'инженеры';

-- 2а. Перекрёстное объединение: все возможные пары «отдел — организация»
CREATE VIEW v_department_organization_cross AS
SELECT d.name AS department, o.name AS organization
FROM department d
CROSS JOIN organization o;

-- 2б. Внутреннее объединение: сотрудники с названием отдела
CREATE VIEW v_employee_department AS
SELECT e.full_name, e.position, d.name AS department
FROM employee e
INNER JOIN department d ON d.id = e.department_id;

-- 2в. Внешнее объединение: все организации и их договоры (в том числе без договоров)
CREATE VIEW v_organization_contracts AS
SELECT o.name AS organization, c.id AS contract_number, c.cost
FROM organization o
LEFT JOIN contract c ON c.organization_id = o.id;

-- 3. Агрегирование и группировка: число сотрудников в каждом отделе
CREATE VIEW v_department_staff_count AS
SELECT d.name AS department, count(e.id) AS staff_count
FROM department d
LEFT JOIN employee e ON e.department_id = d.id
GROUP BY d.name;

-- 4. Сортировка: договоры от самого дорогого к самому дешёвому
CREATE VIEW v_contracts_by_cost AS
SELECT id AS contract_number, conclusion_date, cost
FROM contract
ORDER BY cost DESC;

-- 5. Интервал записей: 3 самых новых договора
CREATE VIEW v_last_contracts AS
SELECT id AS contract_number, conclusion_date, cost
FROM contract
ORDER BY conclusion_date DESC
LIMIT 3;

-- 6. Исключение дубликатов: список городов организаций без повторов
CREATE VIEW v_cities AS
SELECT DISTINCT city
FROM organization;

-- 7а. Объединение (UNION): все ФИО — сотрудники и директора организаций
CREATE VIEW v_all_people AS
SELECT full_name AS person FROM employee
UNION
SELECT director_name FROM organization;

-- 7б. Пересечение (INTERSECT): отделы, у которых есть и сотрудники, и проектные работы
CREATE VIEW v_departments_with_staff_and_work AS
SELECT department_id FROM employee
INTERSECT
SELECT department_id FROM project_work;

-- 7в. Исключение (EXCEPT): отделы без проектных работ
CREATE VIEW v_departments_without_work AS
SELECT id AS department_id FROM department
EXCEPT
SELECT department_id FROM project_work;

-- 8. Вложенный подзапрос: договоры дороже средней стоимости
CREATE VIEW v_contracts_above_avg AS
SELECT id AS contract_number, cost
FROM contract
WHERE cost > (SELECT avg(cost) FROM contract);
