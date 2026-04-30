-- BiDi Database Seed Data
-- Sample data for demonstration

-- ============================================
-- LOCATIONS (3 office locations in Finland)
-- ============================================
INSERT INTO Location (Address, Country) VALUES
('Yliopistonkatu 34, Lahti', 'Finland'),
('Lönnrotinkatu 5, Helsinki', 'Finland'),
('Hatanpään valtatie 30, Tampere', 'Finland');

-- ============================================
-- DEPARTMENTS (5 departments)
-- ============================================
INSERT INTO Department (Name, LID) VALUES
('HR', 1),
('Software', 1),
('Data', 2),
('ICT', 3),
('Customer Support', 1);

-- ============================================
-- CUSTOMERS (External customers)
-- ============================================
INSERT INTO Customer (Name, Email, LID) VALUES
('Helsinki Medical Center', 'contact@hmc.fi', 2),
('Tampere Health Services', 'info@ths.fi', 3),
('Lahti Regional Hospital', 'admin@lrh.fi', 1),
('FinCare Systems', 'business@fincare.fi', 2),
('MediSoft Oy', 'sales@medisoft.fi', 3);

-- ============================================
-- EMPLOYEES (Sample employees across departments)
-- ============================================
INSERT INTO Employee (Email, Name, DepID, HireDate, Salary) VALUES
('john.smith@bidi.fi', 'John Smith', 2, '2020-01-15', 4500.00),
('anna.korhonen@bidi.fi', 'Anna Korhonen', 1, '2019-03-20', 3800.00),
('matti.virtanen@bidi.fi', 'Matti Virtanen', 3, '2021-06-10', 5200.00),
('lisa.johnson@bidi.fi', 'Lisa Johnson', 4, '2018-11-05', 4800.00),
('pekka.nieminen@bidi.fi', 'Pekka Nieminen', 2, '2020-09-12', 4100.00),
('sarah.williams@bidi.fi', 'Sarah Williams', 5, '2022-01-08', 3500.00),
('juha.makinen@bidi.fi', 'Juha Mäkinen', 3, '2019-07-22', 5500.00),
('emma.taylor@bidi.fi', 'Emma Taylor', 2, '2021-04-15', 4300.00),
('antti.laine@bidi.fi', 'Antti Laine', 4, '2020-12-01', 4600.00),
('maria.garcia@bidi.fi', 'Maria Garcia', 1, '2021-08-18', 3700.00);

-- ============================================
-- ROLES
-- ============================================
INSERT INTO Role (Name) VALUES
('Software Developer'),
('Project Manager'),
('Data Analyst'),
('System Administrator'),
('HR Specialist'),
('Customer Support Agent'),
('Senior Developer'),
('Database Administrator'),
('Team Lead'),
('Quality Assurance');

-- ============================================
-- USER GROUPS
-- ============================================
INSERT INTO UserGroup (Name, Description) VALUES
('Admin Group', 'System administrators with full access'),
('Developers Group', 'Software development team members'),
('Management Group', 'Project and department managers'),
('Support Group', 'Customer support staff'),
('Analytics Group', 'Data analysis team');

-- ============================================
-- PROJECTS
-- ============================================
-- NOTE: CID, startDate, deadline now in Project table per ER (1:1 relationship)
-- Each project has exactly ONE customer (CID), not many-to-many
INSERT INTO Project (Name, Budget, Status, CID, startDate, deadline) VALUES
('MediTrack System', 150000.00, 'Active', 1, '2024-01-15', '2024-12-31'),
('Patient Portal v2', 85000.00, 'Active', 2, '2024-02-01', '2024-08-31'),
('Health Analytics Dashboard', 120000.00, 'Planning', 3, '2024-03-01', '2025-02-28'),
('EMR Integration', 200000.00, 'Active', 1, '2024-01-10', '2024-10-15'),
('Mobile Health App', 95000.00, 'Completed', 4, '2023-06-01', '2024-01-31'),
('Telemedicine Platform', 180000.00, 'Active', 2, '2024-04-01', '2025-03-31'),
('Data Migration 2024', 60000.00, 'Planning', 5, '2024-05-01', '2024-11-30'),
('Security Audit', 45000.00, 'Cancelled', 3, '2024-01-01', '2024-03-31');

-- ============================================
-- COMMISSIONS (Relationship now in Project table)
-- ============================================
-- NOTE: Commissions relationship (Project-Customer) is now implemented 
-- directly in the Project table with CID column.
-- The separate Commissions table has been removed to correctly enforce 
-- the ER cardinality: Project (1..N), Customer (1..1)
-- This ensures each project has exactly ONE customer, not many.

-- ============================================
-- WORKS (Employees assigned to Projects)
-- ============================================
INSERT INTO Works (PrID, EmpID, started, hoursWorked) VALUES
(1, 1, '2024-01-15', 320),
(1, 5, '2024-01-20', 280),
(1, 8, '2024-02-01', 250),
(2, 1, '2024-02-05', 180),
(2, 8, '2024-02-10', 200),
(3, 3, '2024-03-15', 120),
(3, 7, '2024-03-20', 150),
(4, 1, '2024-01-12', 400),
(4, 4, '2024-01-15', 350),
(4, 9, '2024-02-01', 300),
(6, 5, '2024-04-01', 160),
(6, 8, '2024-04-05', 140),
(7, 3, '2024-05-10', 80);

-- ============================================
-- HAS (Employee-Role assignments)
-- ============================================
INSERT INTO Has (EmpID, RoleID, Description, assignedDate) VALUES
(1, 1, 'Full-stack developer', '2020-01-15'),
(1, 7, 'Promoted to senior', '2022-06-01'),
(2, 5, 'HR coordinator', '2019-03-20'),
(3, 3, 'Lead data analyst', '2021-06-10'),
(4, 4, 'System admin', '2018-11-05'),
(5, 1, 'Backend developer', '2020-09-12'),
(6, 6, 'Support specialist', '2022-01-08'),
(7, 3, 'Senior analyst', '2019-07-22'),
(7, 8, 'DBA responsibilities', '2021-01-15'),
(8, 1, 'Frontend developer', '2021-04-15'),
(9, 4, 'Network admin', '2020-12-01'),
(10, 5, 'Recruiter', '2021-08-18');

-- ============================================
-- PARTOF (UserGroup memberships)
-- ============================================
INSERT INTO PartOf (GrID, EmpID, joinedDate) VALUES
(2, 1, '2020-01-15'),
(2, 5, '2020-09-12'),
(2, 8, '2021-04-15'),
(3, 1, '2022-06-01'),
(3, 3, '2022-01-10'),
(3, 7, '2023-03-15'),
(1, 4, '2018-11-05'),
(1, 9, '2020-12-01'),
(4, 6, '2022-01-08'),
(5, 3, '2021-06-10'),
(5, 7, '2019-07-22'),
(2, 9, '2023-06-01');
