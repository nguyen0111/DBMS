-- Triggers for BiDi Database

-- Trigger 1: Prevent budget reduction
CREATE OR REPLACE FUNCTION check_budget_increase()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'UPDATE' AND NEW.Budget < OLD.Budget THEN
        RAISE EXCEPTION 'Budget reduction not allowed. Old: %, New: %', 
            OLD.Budget, NEW.Budget;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_prevent_budget_reduction
    BEFORE UPDATE ON Project
    FOR EACH ROW
    EXECUTE FUNCTION check_budget_increase();

-- Trigger 2: Log salary changes
CREATE OR REPLACE FUNCTION log_salary_change()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'UPDATE' AND OLD.Salary IS DISTINCT FROM NEW.Salary THEN
        INSERT INTO SalaryLog (EmpID, OldSalary, NewSalary)
        VALUES (OLD.EmpID, OLD.Salary, NEW.Salary);
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_log_salary_change
    AFTER UPDATE ON Employee
    FOR EACH ROW
    EXECUTE FUNCTION log_salary_change();

-- Trigger 3: Auto-complete project when all workers removed
CREATE OR REPLACE FUNCTION check_project_completion()
RETURNS TRIGGER AS $$
DECLARE
    remaining_workers INT;
    project_status VARCHAR(20);
BEGIN
    SELECT Status INTO project_status
    FROM Project WHERE PrID = OLD.PrID;
    
    SELECT COUNT(*) INTO remaining_workers
    FROM Works
    WHERE PrID = OLD.PrID;
    
    IF remaining_workers = 0 AND project_status = 'Active' THEN
        UPDATE Project
        SET Status = 'Completed'
        WHERE PrID = OLD.PrID;
        
        RAISE NOTICE 'Project % auto-completed - all workers removed', OLD.PrID;
    END IF;
    
    RETURN OLD;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_auto_complete_project
    AFTER DELETE ON Works
    FOR EACH ROW
    EXECUTE FUNCTION check_project_completion();

-- Trigger 4: Prevent employee deletion if has projects
CREATE OR REPLACE FUNCTION check_employee_has_projects()
RETURNS TRIGGER AS $$
DECLARE
    project_count INT;
BEGIN
    SELECT COUNT(*) INTO project_count
    FROM Works
    WHERE EmpID = OLD.EmpID;
    
    IF project_count > 0 THEN
        RAISE EXCEPTION 'Cannot delete employee % - has % active project(s)', 
            OLD.EmpID, project_count;
    END IF;
    
    RETURN OLD;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_prevent_employee_delete_with_projects
    BEFORE DELETE ON Employee
    FOR EACH ROW
    EXECUTE FUNCTION check_employee_has_projects();
