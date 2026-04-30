-- BiDi Database Triggers
-- CT60A7660 - Database Systems Management
-- Phase 2: Implementation - Triggers (5 Points)

-- ============================================
-- TRIGGER 1: Prevent Project Budget Reduction
-- Purpose: Ensure project budget can only increase, not decrease
-- Justification: Business rule for BiDi - Once a medical system project 
--              is approved and contracted with customer (per Commissions),
--              budget reductions are contractually prohibited.
--              Only increases (scope additions) are allowed.
--              This protects customer commitments and prevents 
--              accidental modifications that could breach contracts.
-- Business rule: Budget reductions require special approval workflows.
-- ============================================
CREATE OR REPLACE FUNCTION check_budget_increase()
RETURNS TRIGGER AS $$
BEGIN
    -- Only check if budget is being updated
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

-- ============================================
-- TRIGGER 2: Log Employee Salary Changes
-- Purpose: Maintain audit trail of salary modifications
-- Justification: HR compliance and transparency
-- ============================================

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

-- ============================================
-- TRIGGER 3: Auto-update Project Status on Completion
-- Purpose: When all employees are removed from a project,
--          automatically mark project as Completed
-- Justification: Workflow automation - project is considered complete
--              when no employees are assigned (all work handed over)
--
-- Logic: When last employee is removed from project, mark as Completed
-- ============================================
CREATE OR REPLACE FUNCTION check_project_completion()
RETURNS TRIGGER AS $$
DECLARE
    remaining_workers INT;
    project_status VARCHAR(20);
BEGIN
    -- Get current project status
    SELECT Status INTO project_status
    FROM Project WHERE PrID = OLD.PrID;
    
    -- Count remaining workers on this project after deletion
    SELECT COUNT(*) INTO remaining_workers
    FROM Works
    WHERE PrID = OLD.PrID;
    
    -- If no workers remain and project was Active, mark as Completed
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

-- ============================================
-- TRIGGER 4: Prevent Employee Deletion if Has Active Projects
-- Purpose: Data integrity - ensure employees can't be deleted
--          while actively working on projects
-- Justification: Referential integrity at application level
-- ============================================
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
