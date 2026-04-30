# BiDi Database Project
**CT60A7660 – Database Systems Management**

## Project Overview
Complete PostgreSQL database implementation for BiDi IT company with:
- 7 entities (Project, Customer, Location, Department, Employee, Role, UserGroup)
- 6 relationships with proper cardinalities
- Full constraints, triggers, and access control

## Files Structure

| File | Description |
|------|-------------|
| `schema.sql` | Database schema with all tables, PKs, FKs, CHECK constraints |
| `triggers.sql` | 4 triggers (budget protection, salary logging, auto-completion, delete prevention) |
| `seed_data.sql` | Sample data for demonstration (10 employees, 8 projects, 5 customers) |
| `queries.sql` | All required queries (SELECT, JOINs, aggregations, VIEW) |
| `access_control.sql` | Roles (manager, employee), users, and privilege management |
| `demo_queries.sql` | Constraint violations and trigger demonstrations |
| `setup.sh` | One-command setup script |
| `frontend/` | Interactive web demo (HTML/CSS/JS) |

## Frontend Demo

An interactive web frontend is included in the `/frontend` directory:
- **Schema visualization** - All 12 tables with relationships
- **Constraints display** - All CHECK constraints and triggers explained
- **Query examples** - Sample SQL with syntax highlighting
- **Interactive demo** - Click buttons to see constraint violations
- **ER Model** - Complete entity-relationship diagram

### View Frontend
```bash
# Open directly in browser
cd frontend
open index.html

# Or serve with Python
python -m http.server 8000
# Then visit http://localhost:8000
```

## Quick Start

### Prerequisites
- PostgreSQL installed (12+ recommended)
- psql command line tool

### Setup
```bash
# 1. Create database
createdb bidi

# 2. Run all SQL files
psql -d bidi -f schema.sql
psql -d bidi -f triggers.sql
psql -d bidi -f seed_data.sql
psql -d bidi -f queries.sql
psql -d bidi -f access_control.sql
```

Or use the setup script:
```bash
chmod +x setup.sh
./setup.sh
```

## Scoring Checklist

### Constraints (5 Points) ✅
- [x] Primary Keys on all tables
- [x] Foreign Keys with proper ON DELETE/UPDATE
- [x] 7 CHECK constraints (email format, positive values, valid status, deadline)
- [x] 5 DEFAULT values (country, hiredate, status, description, hours)
- [x] NULL/NOT NULL handling throughout

### Triggers (5 Points) ✅
- [x] **Trigger 1**: Prevent budget reduction (financial control)
- [x] **Trigger 2**: Log salary changes (audit trail)
- [x] **Trigger 3**: Auto-complete projects (workflow automation)
- [x] **Trigger 4**: Prevent employee deletion with active projects (data integrity)

### Queries (10 Points) ✅
- [x] 2+ simple SELECT queries
- [x] 5 JOIN queries (3-5 tables)
- [x] 3 aggregation queries (GROUP BY, HAVING)
- [x] 1 VIEW (EmployeeProjectSummary)
- [x] INSERT, UPDATE, DELETE examples

### Access Control (5 Points) ✅
- [x] 2 roles: `bidi_manager`, `bidi_employee`
- [x] 4 users: `manager1`, `manager2`, `employee1`, `employee2`
- [x] Different privileges per role
- [x] Row-level security enabled

## Demonstration Commands

### Test Constraint Violations
```sql
-- Bad email (no @)
INSERT INTO Employee VALUES ('bad.email', 'Test', 1, 3000);

-- Negative salary
INSERT INTO Employee VALUES ('test@bidi.fi', 'Test', 1, -1000);

-- Budget reduction
UPDATE Project SET Budget = 50000 WHERE PrID = 1;
```

### Test Access Control
```bash
# As manager (works)
psql -U manager1 -d bidi -c "SELECT * FROM Employee;"

# As employee (fails - no salary access)
psql -U employee1 -d bidi -c "SELECT Salary FROM Employee;"
```

## ER Model Mapping

**Entities:**
- ✅ Project (PrID, Name, Budget, Status, CID, startDate, deadline)
- ✅ Customer (CID, Name, Email, LID)
- ✅ Location (LID, Address, Country)
- ✅ Department (DepID, Name, LID)
- ✅ Employee (EmpID, Email, Name, DepID, HireDate, Salary)
- ✅ Role (RoleID, Name)
- ✅ UserGroup (GrID, Name, Description)

**Relationships:**
- ✅ **Commissions** (Project-Customer, N:1 cardinality - many projects per customer, startDate, deadline) - **Implemented in Project table** (CID FK) per ER specification
- ✅ Works (Project-Employee, M:N, started, hoursWorked)
- ✅ Has (Employee-Role, M:N, Description)
- ✅ In (Employee-Department, N:1)
- ✅ In (Department-Location, N:1)
- ✅ In (Customer-Location, N:1)
- ✅ PartOf (UserGroup-Employee, M:N)

## Corrections Made (Post-Feedback)

### 1. ER Cardinality Fix - Commissions Relationship ❌→✅
**Issue**: Original implementation used M:N table (PrID, CID as PK) allowing multiple customers per project.

**ER Specification**: Project (1..N), Customer (1..1) - Each project has exactly ONE customer.

**Fix**: Moved CID, startDate, deadline into Project table as foreign key columns:
```sql
CREATE TABLE Project (
    ...
    CID INT NOT NULL,  -- FK to Customer (each project has exactly 1 customer, N:1 overall)
    startDate DATE NOT NULL,
    deadline DATE NOT NULL,
    FOREIGN KEY (CID) REFERENCES Customer(CID)
);
```
This enforces that each project has exactly one customer (while allowing multiple projects per customer).

### 2. PartOf Table - NULL Fix ❌→✅
**Issue**: `EmpID INT` was nullable but part of PRIMARY KEY.

**Fix**: Changed to `EmpID INT NOT NULL` - PK columns cannot be NULL logically.

### 3. Salary Column - NOT NULL ❌→✅
**Issue**: Salary was nullable, allowing employees with no salary.

**Fix**: Changed to `Salary DECIMAL(10, 2) NOT NULL`.

### 4. SalaryLog Table Location ❌→✅
**Issue**: SalaryLog table created in triggers.sql (bad design practice).

**Fix**: Moved table definition to schema.sql where all tables are defined.

### 5. Trigger Justifications Improved
**Budget Trigger**: Added business justification - "BiDi contracts prohibit budget reductions for medical system projects once approved."

**Auto-complete Trigger**: Documented limitations:
- Only triggers on DELETE from Works
- Simplified logic for academic demo
- Production would need 'isActive' flag in Works table

### 6. Access Control Hardening
**Added explicit REVOKE**:
```sql
REVOKE ALL ON Employee FROM PUBLIC;
REVOKE ALL ON Employee FROM bidi_employee;
```

**RLS Documentation**: Acknowledged that `USING (true)` is a placeholder for demo - production would use session variables to map users to employee IDs.

### 7. NULL Aggregation Fix
Added `COALESCE(SUM(...), 0)` in queries where NULL could occur from LEFT JOINs.

## Assumptions Made
1. **Salary tracking**: Added Salary column to Employee for trigger demonstrations
2. **Status tracking**: Added Status column to Project (Planning, Active, Completed, Cancelled)
3. **Hours tracking**: Added hoursWorked to Works relationship
4. **Country default**: Finland as default country (BiDi operates in Finland)
5. **HireDate**: Track when employees joined
6. **AssignedDate**: Track when roles were assigned
7. **Total Participation**: ER requires Project (1..N) and Employee (1..N) for Works relationship - this means every project must have ≥1 employee and every employee must have ≥1 project. This is NOT enforced in SQL (would require complex triggers) and is noted as a limitation.

## Notes for Viva
- Run `demo_queries.sql` to show constraint violations and trigger behavior
- Use different user accounts to demonstrate access control
- View `EmployeeProjectSummary` shows combined employee data
- All foreign keys use RESTRICT or CASCADE appropriately
