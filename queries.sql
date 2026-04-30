-- Queries for BiDi Database

-- Simple SELECT queries
SELECT EmpID, Name, Email, HireDate
FROM Employee
ORDER BY Name;

SELECT PrID, Name, Budget, Status
FROM Project
WHERE Status = 'Active'
ORDER BY Budget DESC;

-- JOIN queries (3+ tables)
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

-- More JOIN queries
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

SELECT 
    p.Name AS ProjectName,
    p.Budget,
    c.Name AS CustomerName,
    l.Address AS CustomerLocation,
    COUNT(DISTINCT w.EmpID) AS NumEmployees,
    COALESCE(SUM(w.hoursWorked), 0) AS TotalHours
FROM Project p
JOIN Customer c ON p.CID = c.CID
JOIN Location l ON c.LID = l.LID
LEFT JOIN Works w ON p.PrID = w.PrID
GROUP BY p.PrID, p.Name, p.Budget, c.Name, l.Address
ORDER BY p.Budget DESC;

-- Aggregation queries with GROUP BY and HAVING
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

-- More aggregation
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

-- VIEW
CREATE OR REPLACE VIEW EmployeeProjectSummary AS
SELECT 
    e.EmpID,
    e.Name AS EmployeeName,
    e.Email,
    d.Name AS Department,
    COUNT(DISTINCT w.PrID) AS TotalProjects,
    COALESCE(SUM(w.hoursWorked), 0) AS TotalHoursWorked,
    COUNT(DISTINCT r.RoleID) AS NumRoles,
    STRING_AGG(DISTINCT r.Name, ', ') AS AssignedRoles
FROM Employee e
JOIN Department d ON e.DepID = d.DepID
LEFT JOIN Works w ON e.EmpID = w.EmpID
LEFT JOIN Has h ON e.EmpID = h.EmpID
LEFT JOIN Role r ON h.RoleID = r.RoleID
GROUP BY e.EmpID, e.Name, e.Email, d.Name;

SELECT * FROM EmployeeProjectSummary ORDER BY TotalHoursWorked DESC NULLS LAST;

-- INSERT, UPDATE, DELETE
INSERT INTO Employee (Email, Name, DepID, Salary)
VALUES ('new.employee@bidi.fi', 'New Employee', 2, 4000.00)
RETURNING EmpID;

INSERT INTO Project (Name, Budget, Status, CID, startDate, deadline) 
VALUES ('AI Health Assistant', 250000.00, 'Planning', 1, '2024-06-01', '2025-05-31')
RETURNING PrID;

INSERT INTO Works (PrID, EmpID, started, hoursWorked)
VALUES (1, 2, '2024-05-01', 40);

UPDATE Employee SET Salary = 5000.00 WHERE EmpID = 1;
UPDATE Project SET Status = 'Active' WHERE PrID = 3;
UPDATE Works SET hoursWorked = hoursWorked + 20 WHERE PrID = 1 AND EmpID = 1;

DELETE FROM Works WHERE PrID = 1 AND EmpID = 2;
DELETE FROM PartOf WHERE GrID = 2 AND EmpID = 9;
