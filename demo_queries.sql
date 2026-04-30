-- BiDi Database Demonstration Queries
-- These queries demonstrate constraint violations, triggers, and features

-- ============================================
-- CONSTRAINT VIOLATIONS DEMONSTRATION
-- ============================================

-- 1. CHECK Constraint Violation - Invalid email format
-- This will FAIL: Email must contain @
INSERT INTO Employee (Email, Name, DepID, Salary)
VALUES ('invalid.email.com', 'Test User', 1, 3000.00);
-- ERROR: new row for relation "employee" violates check constraint "chk_employee_email"

-- 2. CHECK Constraint Violation - Negative salary
-- This will FAIL: Salary must be positive
INSERT INTO Employee (Email, Name, DepID, Salary)
VALUES ('test@bidi.fi', 'Test User', 1, -1000.00);
-- ERROR: new row for relation "employee" violates check constraint "chk_salary_positive"

-- 3. CHECK Constraint Violation - Negative budget
-- This will FAIL: Budget must be positive
INSERT INTO Project (Name, Budget, Status)
VALUES ('Bad Project', -50000, 'Planning');
-- ERROR: new row for relation "project" violates check constraint "chk_budget_positive"

-- 4. CHECK Constraint Violation - Invalid status
-- This will FAIL: Status must be in the allowed list
INSERT INTO Project (Name, Budget, Status)
VALUES ('Bad Project', 50000, 'InvalidStatus');
-- ERROR: new row for relation "project" violates check constraint "chk_status_valid"

-- 5. CHECK Constraint Violation - Deadline before start
-- This will FAIL: Deadline must be after start date
-- NOTE: Per ER fix, deadline is now in Project table (not Commissions)
INSERT INTO Project (Name, Budget, Status, CID, startDate, deadline)
VALUES ('Test Project', 50000.00, 'Planning', 1, '2024-12-31', '2024-01-01');
-- ERROR: new row for relation "project" violates check constraint "chk_project_deadline"

-- 6. FOREIGN KEY Violation - Non-existent department
-- This will FAIL: DepID 999 does not exist
INSERT INTO Employee (Email, Name, DepID, Salary)
VALUES ('test@bidi.fi', 'Test User', 999, 3000.00);
-- ERROR: insert or update on table "employee" violates foreign key constraint

-- 7. NOT NULL Violation
-- This will FAIL: Name cannot be NULL
INSERT INTO Employee (Email, Name, DepID, Salary)
VALUES ('test@bidi.fi', NULL, 1, 3000.00);
-- ERROR: null value in column "name" violates not-null constraint


-- ============================================
-- TRIGGER DEMONSTRATIONS
-- ============================================

-- 1. Budget Reduction Prevention Trigger
-- Try to reduce project budget - should FAIL
UPDATE Project 
SET Budget = 100000 
WHERE PrID = 1;
-- ERROR: Budget reduction not allowed. Old: 150000, New: 100000

-- Increasing budget should WORK
UPDATE Project 
SET Budget = 200000 
WHERE PrID = 1;
-- SUCCESS

-- 2. Salary Change Log Trigger
-- Check current salary
SELECT EmpID, Name, Salary FROM Employee WHERE EmpID = 1;

-- Update salary
UPDATE Employee SET Salary = 4800.00 WHERE EmpID = 1;

-- Check the log
SELECT * FROM SalaryLog WHERE EmpID = 1;

-- Update again to see another log entry
UPDATE Employee SET Salary = 5000.00 WHERE EmpID = 1;

-- Check all logs for this employee
SELECT * FROM SalaryLog WHERE EmpID = 1 ORDER BY ChangeDate;

-- 3. Project Auto-Completion Trigger
-- First, check a project with workers
SELECT p.PrID, p.Name, p.Status, COUNT(w.EmpID) as Workers
FROM Project p
LEFT JOIN Works w ON p.PrID = w.PrID
WHERE p.PrID = 1
GROUP BY p.PrID, p.Name, p.Status;

-- Remove all workers from a project
-- (First, make sure project 7 has workers, then delete them)
DELETE FROM Works WHERE PrID = 7;

-- Check if project status changed (if it was Active)
SELECT PrID, Name, Status FROM Project WHERE PrID = 7;

-- 4. Employee Deletion Prevention Trigger
-- Try to delete an employee who has active projects - should FAIL
DELETE FROM Employee WHERE EmpID = 1;
-- ERROR: Cannot delete employee 1 - has X active project(s)

-- First remove from Works, then delete
DELETE FROM Works WHERE EmpID = 2;
DELETE FROM Has WHERE EmpID = 2;
DELETE FROM PartOf WHERE EmpID = 2;

-- Now delete should WORK
DELETE FROM Employee WHERE EmpID = 2;


-- ============================================
-- DEFAULT VALUES DEMONSTRATION
-- ============================================

-- 1. Country defaults to 'Finland'
INSERT INTO Location (Address) VALUES ('Test Address, Oulu');
SELECT * FROM Location WHERE Address = 'Test Address, Oulu';
-- Shows Country = 'Finland'

-- 2. HireDate defaults to CURRENT_DATE
INSERT INTO Employee (Email, Name, DepID, Salary)
VALUES ('newhire@bidi.fi', 'New Hire', 1, 3500.00);
SELECT EmpID, Name, HireDate FROM Employee WHERE Email = 'newhire@bidi.fi';
-- Shows HireDate = today's date

-- 3. Project Status defaults to 'Planning'
INSERT INTO Project (Name, Budget) VALUES ('Future Project', 75000.00);
SELECT PrID, Name, Budget, Status FROM Project WHERE Name = 'Future Project';
-- Shows Status = 'Planning'

-- Clean up test data
DELETE FROM Location WHERE Address = 'Test Address, Oulu';
DELETE FROM Employee WHERE Email = 'newhire@bidi.fi';
DELETE FROM Project WHERE Name = 'Future Project';


-- ============================================
-- VIEW DEMONSTRATION
-- ============================================

-- Query the EmployeeProjectSummary view
SELECT 
    EmployeeName,
    Department,
    TotalProjects,
    TotalHoursWorked,
    NumRoles,
    AssignedRoles
FROM EmployeeProjectSummary
WHERE TotalProjects > 0
ORDER BY TotalHoursWorked DESC;


-- ============================================
-- AGGREGATION DEMONSTRATION
-- ============================================

-- Department summary with HAVING
SELECT 
    d.Name AS Department,
    COUNT(e.EmpID) AS EmployeeCount,
    ROUND(AVG(e.Salary), 2) AS AvgSalary,
    SUM(COALESCE(w.TotalHours, 0)) AS DeptTotalHours
FROM Department d
LEFT JOIN Employee e ON d.DepID = e.DepID
LEFT JOIN (
    SELECT EmpID, SUM(hoursWorked) as TotalHours 
    FROM Works 
    GROUP BY EmpID
) w ON e.EmpID = w.EmpID
GROUP BY d.DepID, d.Name
HAVING COUNT(e.EmpID) >= 2
ORDER BY AvgSalary DESC;
