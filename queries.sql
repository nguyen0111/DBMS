-- BiDi Database Queries
-- CT60A7660 - Database Systems Management
-- Phase 2: Implementation - Queries (10 Points)

-- ============================================
-- SIMPLE SELECT QUERIES (2 points)
-- ============================================

-- Simple Query 1: Get all employees with their basic info
SELECT EmpID, Name, Email, HireDate
FROM Employee
ORDER BY Name;

-- Simple Query 2: Get all active projects with budget
SELECT PrID, Name, Budget, Status
FROM Project
WHERE Status = 'Active'
ORDER BY Budget DESC;

-- ============================================
-- JOIN QUERIES (3 or more tables) (3 points)
-- ============================================

-- Join Query 1: Employees with their Department and Location (3 tables)
SELECT 
    e.EmpID,
    e.Name AS EmployeeName,
    e.Email,
    d.Name AS DepartmentName,
    l.Address AS OfficeLocation,
    l.Country
FROM Employee e
JOIN Department d ON e.DepID = d.DepID
JOIN Location l ON d.LID = l.LID
ORDER BY d.Name, e.Name;

-- Join Query 2: Projects with Customer info (3 tables)
-- NOTE: Commissions relationship now in Project table (CID FK)
-- This enforces ER cardinality: Project (1..N), Customer (1..1)
SELECT 
    p.PrID,
    p.Name AS ProjectName,
    p.Budget,
    p.Status,
    c.Name AS CustomerName,
    c.Email AS CustomerEmail,
    p.startDate,
    p.deadline
FROM Project p
JOIN Customer c ON p.CID = c.CID
ORDER BY p.startDate;

-- Join Query 3: Employee-Project assignments with all related info (4 tables)
SELECT 
    e.Name AS EmployeeName,
    e.Email,
    d.Name AS Department,
    p.Name AS ProjectName,
    p.Status AS ProjectStatus,
    w.started AS AssignmentDate,
    w.hoursWorked
FROM Works w
JOIN Employee e ON w.EmpID = e.EmpID
JOIN Department d ON e.DepID = d.DepID
JOIN Project p ON w.PrID = p.PrID
ORDER BY p.Name, e.Name;

-- Join Query 4: Employees with their Roles and UserGroups (4 tables)
SELECT 
    e.Name AS EmployeeName,
    r.Name AS RoleName,
    h.Description AS RoleAssignment,
    ug.Name AS UserGroup,
    h.assignedDate
FROM Employee e
JOIN Has h ON e.EmpID = h.EmpID
JOIN Role r ON h.RoleID = r.RoleID
LEFT JOIN PartOf po ON e.EmpID = po.EmpID
LEFT JOIN UserGroup ug ON po.GrID = ug.GrID
ORDER BY e.Name, r.Name;

-- Join Query 5: Complete project overview (5 tables)
-- NOTE: Uses Project.CID directly per updated schema (Commissions in Project table)
SELECT 
    p.Name AS ProjectName,
    p.Budget,
    c.Name AS CustomerName,
    l.Address AS CustomerLocation,
    COUNT(DISTINCT w.EmpID) AS NumEmployees,
    COALESCE(SUM(w.hoursWorked), 0) AS TotalHours  -- Fixed: COALESCE handles NULL
FROM Project p
JOIN Customer c ON p.CID = c.CID
JOIN Location l ON c.LID = l.LID
LEFT JOIN Works w ON p.PrID = w.PrID
GROUP BY p.PrID, p.Name, p.Budget, c.Name, l.Address
ORDER BY p.Budget DESC;

-- ============================================
-- AGGREGATION QUERIES (2 points)
-- ============================================

-- Aggregation Query 1: Department statistics
SELECT 
    d.Name AS DepartmentName,
    l.Address AS Location,
    COUNT(e.EmpID) AS NumEmployees,
    AVG(e.Salary) AS AvgSalary,
    MIN(e.Salary) AS MinSalary,
    MAX(e.Salary) AS MaxSalary
FROM Department d
JOIN Location l ON d.LID = l.LID
LEFT JOIN Employee e ON d.DepID = e.DepID
GROUP BY d.DepID, d.Name, l.Address
ORDER BY NumEmployees DESC;

-- Aggregation Query 2: Project hours by employee with HAVING
SELECT 
    e.Name AS EmployeeName,
    d.Name AS Department,
    COUNT(w.PrID) AS NumProjects,
    SUM(w.hoursWorked) AS TotalHours,
    AVG(w.hoursWorked) AS AvgHoursPerProject
FROM Employee e
JOIN Department d ON e.DepID = d.DepID
JOIN Works w ON e.EmpID = w.EmpID
GROUP BY e.EmpID, e.Name, d.Name
HAVING SUM(w.hoursWorked) > 200
ORDER BY TotalHours DESC;

-- Aggregation Query 3: Project budget analysis by status
SELECT 
    Status,
    COUNT(*) AS NumProjects,
    SUM(Budget) AS TotalBudget,
    AVG(Budget) AS AvgBudget,
    MIN(Budget) AS MinBudget,
    MAX(Budget) AS MaxBudget
FROM Project
GROUP BY Status
HAVING COUNT(*) > 0
ORDER BY TotalBudget DESC;

-- ============================================
-- VIEW (1 point)
-- ============================================

-- Create a view for Employee Project Summary
CREATE OR REPLACE VIEW EmployeeProjectSummary AS
SELECT 
    e.EmpID,
    e.Name AS EmployeeName,
    e.Email,
    d.Name AS Department,
    COUNT(DISTINCT w.PrID) AS TotalProjects,
    COALESCE(SUM(w.hoursWorked), 0) AS TotalHoursWorked,  -- Fixed: COALESCE handles NULL
    COUNT(DISTINCT r.RoleID) AS NumRoles,
    STRING_AGG(DISTINCT r.Name, ', ') AS AssignedRoles
FROM Employee e
JOIN Department d ON e.DepID = d.DepID
LEFT JOIN Works w ON e.EmpID = w.EmpID
LEFT JOIN Has h ON e.EmpID = h.EmpID
LEFT JOIN Role r ON h.RoleID = r.RoleID
GROUP BY e.EmpID, e.Name, e.Email, d.Name;

-- Query the view
SELECT * FROM EmployeeProjectSummary ORDER BY TotalHoursWorked DESC NULLS LAST;

-- ============================================
-- INSERT, UPDATE, DELETE EXAMPLES
-- ============================================

-- INSERT Example 1: Add new employee (Salary is NOT NULL per schema)
INSERT INTO Employee (Email, Name, DepID, Salary)
VALUES ('new.employee@bidi.fi', 'New Employee', 2, 4000.00)
RETURNING EmpID;

-- INSERT Example 2: Add new project with customer (Commissions now in Project)
-- NOTE: Per ER cardinality fix, CID is directly in Project table
-- First insert project with RETURNING to get safe ID
INSERT INTO Project (Name, Budget, Status, CID, startDate, deadline) 
VALUES ('AI Health Assistant', 250000.00, 'Planning', 1, '2024-06-01', '2025-05-31')
RETURNING PrID;

-- INSERT Example 3: Assign employee to project
INSERT INTO Works (PrID, EmpID, started, hoursWorked)
VALUES (1, 2, '2024-05-01', 40);

-- UPDATE Example 1: Update employee salary
UPDATE Employee 
SET Salary = 5000.00 
WHERE EmpID = 1;

-- UPDATE Example 2: Update project status
UPDATE Project 
SET Status = 'Active' 
WHERE PrID = 3;

-- UPDATE Example 3: Update hours worked
UPDATE Works 
SET hoursWorked = hoursWorked + 20 
WHERE PrID = 1 AND EmpID = 1;

-- DELETE Example 1: Remove employee from project
DELETE FROM Works 
WHERE PrID = 1 AND EmpID = 2;

-- DELETE Example 2: Remove user group membership
DELETE FROM PartOf 
WHERE GrID = 2 AND EmpID = 9;
