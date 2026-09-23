-- ЛР 14. Триггеры

-- ===== 1. DELETE: каскадное удаление строк в дочерних таблицах =====
-- Удаляем договор → сначала удаляются его проектные работы
CREATE FUNCTION contract_delete_cascade() RETURNS trigger AS $$
BEGIN
    DELETE FROM project_work WHERE contract_id = OLD.id;
    RETURN OLD;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_contract_delete
BEFORE DELETE ON contract
FOR EACH ROW EXECUTE FUNCTION contract_delete_cascade();

-- Удаляем организацию → сначала удаляются её договоры (а их работы — триггером выше)
CREATE FUNCTION organization_delete_cascade() RETURNS trigger AS $$
BEGIN
    DELETE FROM contract WHERE organization_id = OLD.id;
    RETURN OLD;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_organization_delete
BEFORE DELETE ON organization
FOR EACH ROW EXECUTE FUNCTION organization_delete_cascade();

-- ===== 2. INSERT: проверка непустых значений, текущая дата, значения по умолчанию =====
CREATE FUNCTION contract_insert_check() RETURNS trigger AS $$
BEGIN
    IF NEW.organization_id IS NULL THEN
        RAISE EXCEPTION 'Не указана организация договора';
    END IF;
    IF NEW.cost IS NULL THEN
        RAISE EXCEPTION 'Не указана стоимость договора';
    END IF;
    IF NEW.conclusion_date IS NULL THEN
        NEW.conclusion_date := current_date;   -- текущая дата
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_contract_insert
BEFORE INSERT ON contract
FOR EACH ROW EXECUTE FUNCTION contract_insert_check();

CREATE FUNCTION organization_insert_check() RETURNS trigger AS $$
BEGIN
    IF NEW.name IS NULL OR trim(NEW.name) = '' THEN
        RAISE EXCEPTION 'Не указано название организации';
    END IF;
    IF NEW.country IS NULL OR trim(NEW.country) = '' THEN
        NEW.country := 'Россия';               -- значение по умолчанию
    END IF;
    IF NEW.address IS NULL OR trim(NEW.address) = '' THEN
        NEW.address := 'не указан';
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_organization_insert
BEFORE INSERT ON organization
FOR EACH ROW EXECUTE FUNCTION organization_insert_check();

-- ===== 3. UPDATE: запрет некорректных значений =====
CREATE FUNCTION project_work_update_check() RETURNS trigger AS $$
BEGIN
    IF NEW.end_date IS NOT NULL AND NEW.end_date < NEW.start_date THEN
        RAISE EXCEPTION 'Дата завершения % раньше даты начала %', NEW.end_date, NEW.start_date;
    END IF;
    IF NEW.start_date > current_date + 365 THEN
        RAISE EXCEPTION 'Дата начала % слишком далеко в будущем', NEW.start_date;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_project_work_update
BEFORE UPDATE ON project_work
FOR EACH ROW EXECUTE FUNCTION project_work_update_check();

-- ===== 4. Аудит: кто, когда, какое действие, старые и новые значения =====
CREATE TABLE audit_log (
    id         serial PRIMARY KEY,
    table_name text      NOT NULL,
    action     text      NOT NULL,
    user_name  text      NOT NULL DEFAULT current_user,
    changed_at timestamp NOT NULL DEFAULT now(),
    old_values text,
    new_values text
);
COMMENT ON TABLE  audit_log            IS 'Журнал изменений данных';
COMMENT ON COLUMN audit_log.id         IS 'Номер записи журнала';
COMMENT ON COLUMN audit_log.table_name IS 'Таблица, в которой произошло изменение';
COMMENT ON COLUMN audit_log.action     IS 'Действие: INSERT, UPDATE или DELETE';
COMMENT ON COLUMN audit_log.user_name  IS 'Пользователь, выполнивший действие';
COMMENT ON COLUMN audit_log.changed_at IS 'Дата и время действия';
COMMENT ON COLUMN audit_log.old_values IS 'Значения строки до изменения';
COMMENT ON COLUMN audit_log.new_values IS 'Значения строки после изменения';

CREATE FUNCTION write_audit() RETURNS trigger AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        INSERT INTO audit_log (table_name, action, new_values) VALUES (TG_TABLE_NAME, TG_OP, NEW::text);
        RETURN NEW;
    ELSIF TG_OP = 'UPDATE' THEN
        INSERT INTO audit_log (table_name, action, old_values, new_values) VALUES (TG_TABLE_NAME, TG_OP, OLD::text, NEW::text);
        RETURN NEW;
    ELSE
        INSERT INTO audit_log (table_name, action, old_values) VALUES (TG_TABLE_NAME, TG_OP, OLD::text);
        RETURN OLD;
    END IF;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_audit_department   AFTER INSERT OR UPDATE OR DELETE ON department   FOR EACH ROW EXECUTE FUNCTION write_audit();
CREATE TRIGGER trg_audit_employee     AFTER INSERT OR UPDATE OR DELETE ON employee     FOR EACH ROW EXECUTE FUNCTION write_audit();
CREATE TRIGGER trg_audit_organization AFTER INSERT OR UPDATE OR DELETE ON organization FOR EACH ROW EXECUTE FUNCTION write_audit();
CREATE TRIGGER trg_audit_contract     AFTER INSERT OR UPDATE OR DELETE ON contract     FOR EACH ROW EXECUTE FUNCTION write_audit();
CREATE TRIGGER trg_audit_project_work AFTER INSERT OR UPDATE OR DELETE ON project_work FOR EACH ROW EXECUTE FUNCTION write_audit();
