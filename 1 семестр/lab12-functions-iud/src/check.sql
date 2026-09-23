-- ЛР 12. Проверка функций (выполнять по одной строке, результат — на скриншот).
-- 4 — номер, который вернула insert_department; на сервере он может быть другим.
SELECT insert_department('Отдел испытаний', 4, '20-11-09', 'Фёдоров Игорь Олегович');
SELECT update_department_phone('20-11-10', 4);
SELECT * FROM department WHERE id = 4;
SELECT delete_department(4);
SELECT random_string(10);
SELECT random_fio('Ж');
