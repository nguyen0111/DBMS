-- Access Control for BiDi Database

-- Roles
DROP ROLE IF EXISTS bidi_manager;
CREATE ROLE bidi_manager;
DROP ROLE IF EXISTS bidi_employee;
CREATE ROLE bidi_employee;

-- Manager permissions
GRANT SELECT ON ALL TABLES IN SCHEMA public TO bidi_manager;
GRANT INSERT, UPDATE ON Project TO bidi_manager;
GRANT INSERT ON Works TO bidi_manager;
GRANT SELECT, INSERT ON SalaryLog TO bidi_manager;
GRANT SELECT ON EmployeePublic TO bidi_manager;
GRANT ALL ON Employee TO bidi_manager;
GRANT USAGE ON ALL SEQUENCES IN SCHEMA public TO bidi_manager;

-- Employee permissions (limited)
GRANT SELECT ON Location TO bidi_employee;
GRANT SELECT ON Department TO bidi_employee;
GRANT SELECT ON Project TO bidi_employee;
GRANT SELECT ON Customer TO bidi_employee;
GRANT SELECT ON Works TO bidi_employee;
GRANT SELECT ON Role TO bidi_employee;
GRANT SELECT ON Has TO bidi_employee;
GRANT SELECT ON UserGroup TO bidi_employee;
GRANT SELECT ON PartOf TO bidi_employee;

-- Security hardening
REVOKE ALL ON Employee FROM PUBLIC;
REVOKE ALL ON Employee FROM bidi_employee;

-- Public employee view (no salary)
CREATE OR REPLACE VIEW EmployeePublic AS
SELECT EmpID, Email, Name, DepID, HireDate
FROM Employee;
GRANT SELECT ON EmployeePublic TO bidi_employee;

-- Users
DROP USER IF EXISTS manager1;
CREATE USER manager1 WITH PASSWORD 'ManagerPass123!';
GRANT bidi_manager TO manager1;

DROP USER IF EXISTS employee1;
CREATE USER employee1 WITH PASSWORD 'EmployeePass123!';
GRANT bidi_employee TO employee1;

DROP USER IF EXISTS manager2;
CREATE USER manager2 WITH PASSWORD 'ManagerPass456!';
GRANT bidi_manager TO manager2;

DROP USER IF EXISTS employee2;
CREATE USER employee2 WITH PASSWORD 'EmployeePass456!';
GRANT bidi_employee TO employee2;

-- Row-level security
ALTER TABLE Employee ENABLE ROW LEVEL SECURITY;

CREATE POLICY employee_rls_policy ON Employee
    FOR SELECT
    TO bidi_employee
    USING (true);

CREATE POLICY manager_rls_policy ON Employee
    FOR ALL
    TO bidi_manager
    USING (true)
    WITH CHECK (true);
