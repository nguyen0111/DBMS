-- Constraint Violations (will fail)

-- Invalid email format
INSERT INTO Employee (Email, Name, DepID, Salary)
VALUES ('invalid.email.com', 'Test User', 1, 3000.00);

-- Negative salary
INSERT INTO Employee (Email, Name, DepID, Salary)
VALUES ('test@bidi.fi', 'Test User', 1, -1000.00);

-- Negative budget
INSERT INTO Project (Name, Budget, Status)
VALUES ('Bad Project', -50000, 'Planning');

-- Invalid status
INSERT INTO Project (Name, Budget, Status)
VALUES ('Bad Project', 50000, 'InvalidStatus');

-- Deadline before start date
INSERT INTO Project (Name, Budget, Status, CID, startDate, deadline)
VALUES ('Test Project', 50000.00, 'Planning', 1, '2024-12-31', '2024-01-01');

-- Non-existent department FK
INSERT INTO Employee (Email, Name, DepID, Salary)
VALUES ('test@bidi.fi', 'Test User', 999, 3000.00);

-- NULL name (NOT NULL violation)
INSERT INTO Employee (Email, Name, DepID, Salary)
VALUES ('test@bidi.fi', NULL, 1, 3000.00);


-- Trigger Demonstrations

-- Budget reduction prevention (will fail)
UPDATE Project SET Budget = 100000 WHERE PrID = 1;

-- Budget increase (will succeed)
UPDATE Project SET Budget = 200000 WHERE PrID = 1;

-- Salary change logging
SELECT EmpID, Name, Salary FROM Employee WHERE EmpID = 1;
UPDATE Employee SET Salary = 4800.00 WHERE EmpID = 1;
SELECT * FROM SalaryLog WHERE EmpID = 1;

-- Auto-complete project when workers removed
DELETE FROM Works WHERE PrID = 7;
SELECT PrID, Name, Status FROM Project WHERE PrID = 7;

-- Prevent employee deletion with active projects (will fail)
DELETE FROM Employee WHERE EmpID = 1;

-- Delete employee after removing from all relationships
DELETE FROM Works WHERE EmpID = 2;
DELETE FROM Has WHERE EmpID = 2;
DELETE FROM PartOf WHERE EmpID = 2;
DELETE FROM Employee WHERE EmpID = 2;


-- Default Values Demonstration

INSERT INTO Location (Address) VALUES ('Test Address, Oulu');
SELECT * FROM Location WHERE Address = 'Test Address, Oulu';

INSERT INTO Employee (Email, Name, DepID, Salary)
VALUES ('newhire@bidi.fi', 'New Hire', 1, 3500.00);
SELECT EmpID, Name, HireDate FROM Employee WHERE Email = 'newhire@bidi.fi';

INSERT INTO Project (Name, Budget) VALUES ('Future Project', 75000.00);
SELECT PrID, Name, Budget, Status FROM Project WHERE Name = 'Future Project';

-- Clean up test data
DELETE FROM Location WHERE Address = 'Test Address, Oulu';
DELETE FROM Employee WHERE Email = 'newhire@bidi.fi';
DELETE FROM Project WHERE Name = 'Future Project';


-- View Demonstration

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


-- Aggregation with GROUP BY and HAVING

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
