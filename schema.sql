-- BiDi Database Schema
-- CT60A7660 - Database Systems Management
-- Phase 2: Implementation

-- Drop tables if they exist (for clean setup)
DROP TABLE IF EXISTS Works CASCADE;
-- NOTE: Commissions table removed - relationship now in Project table (CID FK)
DROP TABLE IF EXISTS Has CASCADE;
DROP TABLE IF EXISTS PartOf CASCADE;
DROP TABLE IF EXISTS Employee CASCADE;
DROP TABLE IF EXISTS Role CASCADE;
DROP TABLE IF EXISTS UserGroup CASCADE;
DROP TABLE IF EXISTS Project CASCADE;
DROP TABLE IF EXISTS Customer CASCADE;
DROP TABLE IF EXISTS Department CASCADE;
DROP TABLE IF EXISTS Location CASCADE;

-- ============================================
-- 1. LOCATION TABLE (Independent entity)
-- ============================================
CREATE TABLE Location (
    LID SERIAL PRIMARY KEY,
    Address VARCHAR(255) NOT NULL,
    Country VARCHAR(100) NOT NULL DEFAULT 'Finland'
);

-- ============================================
-- 2. DEPARTMENT TABLE
-- ============================================
CREATE TABLE Department (
    DepID SERIAL PRIMARY KEY,
    Name VARCHAR(100) NOT NULL,
    LID INT NOT NULL,
    
    FOREIGN KEY (LID) REFERENCES Location(LID)
        ON DELETE RESTRICT
        ON UPDATE CASCADE
);

-- ============================================
-- 3. CUSTOMER TABLE
-- ============================================
CREATE TABLE Customer (
    CID SERIAL PRIMARY KEY,
    Name VARCHAR(100) NOT NULL,
    Email VARCHAR(100) NOT NULL,
    LID INT NOT NULL,
    
    -- CHECK constraint 1: Email must contain @
    CONSTRAINT chk_customer_email CHECK (Email LIKE '%@%'),
    
    FOREIGN KEY (LID) REFERENCES Location(LID)
        ON DELETE RESTRICT
        ON UPDATE CASCADE
);

-- ============================================
-- 4. EMPLOYEE TABLE
-- ============================================
CREATE TABLE Employee (
    EmpID SERIAL PRIMARY KEY,
    Email VARCHAR(100) NOT NULL,
    Name VARCHAR(100) NOT NULL,
    DepID INT NOT NULL,
    HireDate DATE DEFAULT CURRENT_DATE,
    Salary DECIMAL(10, 2) NOT NULL,  -- Changed: Salary should not be NULL
    
    -- CHECK constraint 2: Email must contain @
    CONSTRAINT chk_employee_email CHECK (Email LIKE '%@%'),
    -- CHECK constraint 3: Salary must be positive
    CONSTRAINT chk_salary_positive CHECK (Salary > 0),
    
    FOREIGN KEY (DepID) REFERENCES Department(DepID)
        ON DELETE RESTRICT
        ON UPDATE CASCADE
);

-- ============================================
-- 5. ROLE TABLE
-- ============================================
CREATE TABLE Role (
    RoleID SERIAL PRIMARY KEY,
    Name VARCHAR(100) NOT NULL
);

-- ============================================
-- 6. USERGROUP TABLE
-- ============================================
CREATE TABLE UserGroup (
    GrID SERIAL PRIMARY KEY,
    Name VARCHAR(100) NOT NULL,
    Description TEXT DEFAULT 'Standard user group'
);

-- ============================================
-- 7. PROJECT TABLE
-- ============================================
-- ER Note: Commissions relationship - Project (1..N), Customer (1..1)
-- Each project has exactly ONE customer (N projects can belong to 1 customer)
-- This is N:1 relationship (many projects → one customer), NOT 1:1
-- Therefore: CID is stored directly in Project table as foreign key
CREATE TABLE Project (
    PrID SERIAL PRIMARY KEY,
    Name VARCHAR(100) NOT NULL,
    Budget DECIMAL(12, 2) NOT NULL,
    Status VARCHAR(20) DEFAULT 'Planning',
    CID INT NOT NULL,  -- FK to Customer (each project has exactly 1 customer)
    startDate DATE NOT NULL DEFAULT CURRENT_DATE,
    deadline DATE NOT NULL,
    
    -- CHECK constraint 4: Budget must be positive
    CONSTRAINT chk_budget_positive CHECK (Budget > 0),
    -- CHECK constraint 5: Status must be valid
    CONSTRAINT chk_status_valid CHECK (Status IN ('Planning', 'Active', 'Completed', 'Cancelled')),
    -- CHECK constraint 6: Deadline must be after start date
    CONSTRAINT chk_project_deadline CHECK (deadline > startDate),
    -- NOTE: No UNIQUE constraint needed on CID - a customer CAN have multiple projects
    
    FOREIGN KEY (CID) REFERENCES Customer(CID)
        ON DELETE RESTRICT
        ON UPDATE CASCADE
);

-- ============================================
-- 8. COMMISSIONS (Project - Customer relationship)
-- ============================================
-- NOTE: This relationship is now implemented directly in the Project table
-- with CID column and deadline/startDate columns.
-- Kept as comment for documentation purposes per ER specification.
-- 
-- ER Cardinality: Project (1..N), Customer (1..1)
-- Implementation: Project table has CID FK (each project has exactly 1 customer)
-- The old M:N implementation (below) was INCORRECT for this cardinality.
-- 
-- OLD (WRONG) - Allowed many customers per project:
--   PRIMARY KEY (PrID, CID) -- This allows multiple customers per project ❌
--
-- CORRECT - One customer per project:
--   CID in Project table with FK to Customer ✅

-- ============================================
-- 9. WORKS (Project - Employee relationship)
-- ============================================
CREATE TABLE Works (
    PrID INT NOT NULL,
    EmpID INT NOT NULL,
    started DATE NOT NULL DEFAULT CURRENT_DATE,
    hoursWorked INT DEFAULT 0,
    
    PRIMARY KEY (PrID, EmpID),
    
    -- CHECK constraint 7: Hours worked cannot be negative
    CONSTRAINT chk_hours_non_negative CHECK (hoursWorked >= 0),
    
    FOREIGN KEY (PrID) REFERENCES Project(PrID)
        ON DELETE CASCADE
        ON UPDATE CASCADE,
    FOREIGN KEY (EmpID) REFERENCES Employee(EmpID)
        ON DELETE CASCADE
        ON UPDATE CASCADE
);

-- ============================================
-- 10. HAS (Employee - Role relationship)
-- ============================================
CREATE TABLE Has (
    EmpID INT NOT NULL,
    RoleID INT NOT NULL,
    Description TEXT DEFAULT 'Primary role assignment',
    assignedDate DATE DEFAULT CURRENT_DATE,
    
    PRIMARY KEY (EmpID, RoleID),
    
    FOREIGN KEY (EmpID) REFERENCES Employee(EmpID)
        ON DELETE CASCADE
        ON UPDATE CASCADE,
    FOREIGN KEY (RoleID) REFERENCES Role(RoleID)
        ON DELETE CASCADE
        ON UPDATE CASCADE
);

-- ============================================
-- 11. PARTOF (UserGroup - Employee relationship)
-- ============================================
-- ER Cardinality: UserGroup (1..N), Employee (0..N)
-- Note: EmpID is NOT NULL - PK columns cannot be NULL logically
CREATE TABLE PartOf (
    GrID INT NOT NULL,
    EmpID INT NOT NULL,  -- Changed: was INT (nullable), now NOT NULL
    joinedDate DATE DEFAULT CURRENT_DATE,
    
    PRIMARY KEY (GrID, EmpID),
    
    FOREIGN KEY (GrID) REFERENCES UserGroup(GrID)
        ON DELETE CASCADE
        ON UPDATE CASCADE,
    FOREIGN KEY (EmpID) REFERENCES Employee(EmpID)
        ON DELETE CASCADE
        ON UPDATE CASCADE
);

-- ============================================
-- 12. SALARY LOG (Audit table for trigger)
-- ============================================
-- Note: This table is created in schema because it stores data
-- The trigger logic is in triggers.sql, but the table belongs here
CREATE TABLE SalaryLog (
    LogID SERIAL PRIMARY KEY,
    EmpID INT NOT NULL,
    OldSalary DECIMAL(10, 2),
    NewSalary DECIMAL(10, 2),
    ChangeDate TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    ChangedBy VARCHAR(100) DEFAULT CURRENT_USER,
    
    FOREIGN KEY (EmpID) REFERENCES Employee(EmpID)
        ON DELETE CASCADE
        ON UPDATE CASCADE
);

-- ============================================
-- INDEXING STRATEGY (+2 Bonus Points)
-- Well-justified indexes for query optimization
-- ============================================

-- Index 1: Employee.DepID - Foreign key, frequently joined with Department
-- Justification: Department-Employee queries are common (organizational hierarchy)
CREATE INDEX idx_employee_dept ON Employee(DepID);

-- Index 2: Project.CID - Foreign key, joined with Customer in most project queries
-- Justification: Project-Customer relationship queries are core business need
CREATE INDEX idx_project_customer ON Project(CID);

-- Index 3: Works.EmpID and Works.PrID - Composite FK relationship
-- Justification: M:N relationship queries need fast lookup for both directions
CREATE INDEX idx_works_employee ON Works(EmpID);
CREATE INDEX idx_works_project ON Works(PrID);

-- Index 4: Employee.Email - Unique identifier, used for lookups
-- Justification: Email is unique and frequently used for login/identification
CREATE INDEX idx_employee_email ON Employee(Email);
