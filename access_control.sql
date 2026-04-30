-- BiDi Database Access Control
-- CT60A7660 - Database Systems Management
-- Phase 2: Implementation - Access Control (5 Points)

-- ============================================
-- CREATE ROLES (2 roles minimum)
-- ============================================

-- Role 1: bidi_manager - Full read access, limited write
-- Can view all data, insert/update projects, view salary logs
DROP ROLE IF EXISTS bidi_manager;
CREATE ROLE bidi_manager;

-- Grant SELECT on all tables
GRANT SELECT ON ALL TABLES IN SCHEMA public TO bidi_manager;

-- Grant INSERT/UPDATE on Project (managers can create/modify projects)
GRANT INSERT, UPDATE ON Project TO bidi_manager;
-- NOTE: Sequences granted below with ALL SEQUENCES

-- NOTE: Commissions table removed - CID is now in Project table
-- Managers can create projects with CID via INSERT on Project

-- Grant INSERT on Works (managers can assign employees to projects)
GRANT INSERT ON Works TO bidi_manager;

-- Grant SELECT, INSERT on SalaryLog (managers can view salary history and trigger can log)
GRANT SELECT, INSERT ON SalaryLog TO bidi_manager;

-- Grant SELECT on EmployeePublic view (managers can view public employee data)
GRANT SELECT ON EmployeePublic TO bidi_manager;

-- Grant ALL on Employee table (managers need full access for testing and management)
GRANT ALL ON Employee TO bidi_manager;

-- Role 2: bidi_employee - Limited read access, no salary info
-- Can view their own data, projects, but NOT salaries
DROP ROLE IF EXISTS bidi_employee;
CREATE ROLE bidi_employee;

-- Grant SELECT on basic tables (no Employee salary info)
GRANT SELECT ON Location TO bidi_employee;
GRANT SELECT ON Department TO bidi_employee;
GRANT SELECT ON Project TO bidi_employee;
GRANT SELECT ON Customer TO bidi_employee;
-- NOTE: Commissions table removed - relationship now in Project table
GRANT SELECT ON Works TO bidi_employee;
GRANT SELECT ON Role TO bidi_employee;
GRANT SELECT ON Has TO bidi_employee;
GRANT SELECT ON UserGroup TO bidi_employee;
GRANT SELECT ON PartOf TO bidi_employee;

-- REVOKE any default PUBLIC access to Employee table (security hardening)
REVOKE ALL ON Employee FROM PUBLIC;

-- Grant SELECT on Employee but without salary (we'll use a view for this)
-- Actually, let's create a view for public employee info

-- Create view for employee public info (no salary)
CREATE OR REPLACE VIEW EmployeePublic AS
SELECT EmpID, Email, Name, DepID, HireDate
FROM Employee;

GRANT SELECT ON EmployeePublic TO bidi_employee;

-- EXPLICITLY REVOKE access to full Employee table for employee role
-- This ensures they cannot see salary data even if PUBLIC has access
REVOKE ALL ON Employee FROM bidi_employee;

-- Grant usage on sequences for ID operations
GRANT USAGE ON ALL SEQUENCES IN SCHEMA public TO bidi_manager;

-- ============================================
-- CREATE USERS (2 users minimum)
-- ============================================

-- User 1: manager1 - assigned to bidi_manager role
DROP USER IF EXISTS manager1;
CREATE USER manager1 WITH PASSWORD 'ManagerPass123!';
GRANT bidi_manager TO manager1;

-- User 2: employee1 - assigned to bidi_employee role
DROP USER IF EXISTS employee1;
CREATE USER employee1 WITH PASSWORD 'EmployeePass123!';
GRANT bidi_employee TO employee1;

-- Additional users for demonstration
DROP USER IF EXISTS manager2;
CREATE USER manager2 WITH PASSWORD 'ManagerPass456!';
GRANT bidi_manager TO manager2;

DROP USER IF EXISTS employee2;
CREATE USER employee2 WITH PASSWORD 'EmployeePass456!';
GRANT bidi_employee TO employee2;

-- ============================================
-- DEMONSTRATION QUERIES FOR ACCESS CONTROL
-- ============================================

-- These are example commands to test access control
-- Run these as different users to demonstrate the differences

-- === AS manager1 (should work) ===
-- Connect: psql -U manager1 -d bidi

-- This should WORK - manager can SELECT all
-- SELECT * FROM Employee;

-- This should WORK - manager can see salaries
-- SELECT Name, Salary FROM Employee;

-- This should WORK - manager can insert projects
-- INSERT INTO Project (Name, Budget, Status) VALUES ('Test Project', 50000, 'Planning');

-- This should WORK - manager can update projects
-- UPDATE Project SET Budget = 60000 WHERE Name = 'Test Project';

-- This should WORK - manager can view salary log
-- SELECT * FROM SalaryLog;


-- === AS employee1 (some should fail) ===
-- Connect: psql -U employee1 -d bidi

-- This should FAIL - employee cannot access Employee table directly
-- SELECT * FROM Employee;
-- ERROR: permission denied for table Employee

-- This should WORK - employee can use EmployeePublic view
-- SELECT * FROM EmployeePublic;

-- This should FAIL - employee cannot see salaries
-- SELECT Name, Salary FROM Employee;
-- ERROR: permission denied for table Employee

-- This should FAIL - employee cannot insert projects
-- INSERT INTO Project (Name, Budget, Status) VALUES ('Hacked Project', 1000000, 'Active');
-- ERROR: permission denied for table Project

-- This should WORK - employee can view projects
-- SELECT * FROM Project;

-- This should WORK - employee can view their assignments
-- SELECT * FROM Works WHERE EmpID = [their ID];

-- ============================================
-- ROW-LEVEL SECURITY (Bonus - PostgreSQL specific)
-- ============================================
-- IMPORTANT LIMITATION ACKNOWLEDGMENT:
-- This RLS implementation is SIMPLIFIED for academic demonstration.
-- In production, you would use session variables to map current_user 
-- to actual EmpID for real row-level restrictions.
--
-- Current implementation uses USING (true) which provides NO actual
-- row filtering - it's a placeholder showing where RLS would be applied.
-- This is intentional for demo purposes since we don't have authentication
-- mapping database users to employee IDs in this academic project.
-- ============================================

-- Enable row-level security on Employee table
ALTER TABLE Employee ENABLE ROW LEVEL SECURITY;

-- POLICY 1: Employee role - simplified for demo (no actual restriction)
-- PRODUCTION would use: USING (EmpID = current_setting('app.current_user_id')::INT)
-- For academic demo, we use true but rely on REVOKE for security
CREATE POLICY employee_rls_policy ON Employee
    FOR SELECT
    TO bidi_employee
    USING (true);  -- PLACEHOLDER: Real system needs user-to-emp mapping

-- POLICY 2: Manager role - full access (as designed)
CREATE POLICY manager_rls_policy ON Employee
    FOR ALL
    TO bidi_manager
    USING (true)
    WITH CHECK (true);

-- ALTERNATIVE (More secure) - If we want employees to see NOTHING:
-- DROP POLICY employee_rls_policy ON Employee;
-- CREATE POLICY employee_no_access ON Employee FOR SELECT TO bidi_employee USING (false);
-- But we keep the view-based approach (EmployeePublic) which is cleaner design.
