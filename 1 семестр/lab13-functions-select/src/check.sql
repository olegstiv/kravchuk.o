-- ЛР 13. Проверка функций (результат — на скриншот)
SELECT contract_cost_stat('min'), contract_cost_stat('max'), contract_cost_stat('avg');
SELECT * FROM find_employees('Иван');
SELECT organization_full_address(1);
SELECT employee_card(1);
SELECT position_share('инженеры');
