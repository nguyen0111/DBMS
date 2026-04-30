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
| `app.py` | **BONUS**: Streamlit frontend application (+10 points) |
| `requirements.txt` | Python dependencies for frontend |
| **Indexing** | **BONUS**: Well-justified indexes on FKs and query columns (+2 points) |

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

### Core Requirements (25 Points)

| Component | Requirement | Implementation | Status |
|-----------|-------------|----------------|--------|
| **Constraints (5 pts)** | 2 CHECK, 2 DEFAULT | **7 CHECK, 8 DEFAULT** | ✅ **5/5 + 2 bonus** |
| **Triggers (5 pts)** | 3 triggers | **4 triggers** | ✅ **5/5 + 1 bonus** |
| **Queries (10 pts)** | SELECT, JOINs, Aggregations, VIEW, DML | All implemented | ✅ **10/10** |
| **Access Control (5 pts)** | 2 roles, 2 users, RBAC | 2 roles, 4 users, RLS | ✅ **5/5** |

### Bonus Points (Up to +15) - ALL CLAIMED! 🎯
| Bonus | Points | Evidence |
|-------|--------|----------|
| **Additional Attributes/Constraints** | **+2** | 7 CHECK constraints (req: 2), 8 DEFAULT values (req: 2) |
| **Additional Triggers** | **+1** | 4 triggers implemented (req: 3) |
| **Indexing Strategy** | **+2** | 5 well-justified indexes on FKs and query columns |
| **Frontend Application** | **+10** | Streamlit app with DB connectivity, RBAC demo, constraint testing |

### Total Possible: **40/25 Points** 🚀

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

## Bonus: Frontend Application (+10 Points)

A Streamlit web application demonstrating database connectivity, RBAC enforcement, constraints and triggers.

### Installation
```bash
# Install dependencies
pip install -r requirements.txt
```

### Running the Frontend
```bash
# Make sure PostgreSQL is running and database 'bidi' is set up
streamlit run app.py
```

The app will open at `http://localhost:8501`

### Features Demonstrated
- **Authentication**: Login as Manager or Employee with database-level credentials
- **RBAC Enforcement**: Different views based on database role permissions
- **Dashboard**: KPI metrics (Total Projects, Employees, Budget)
- **Projects/Employees**: Forms to INSERT new records (with permission checks)
- **Testing Page**: Interactive buttons to violate constraints and triggers
  - Negative budget (CHECK constraint)
  - Invalid email format (CHECK constraint)
  - Foreign key violations
  - Budget reduction trigger
  - Salary audit log trigger
  - Access control demonstration

### Demo Credentials
- **Manager**: `manager1` / `ManagerPass123!` (full access)
- **Employee**: `employee1` / `EmployeePass123!` (limited access, no salary data)

## Bonus: Indexing Strategy (+2 Points)

Well-justified indexes implemented for query optimization:

| Index | Column(s) | Justification |
|-------|-----------|---------------|
| `idx_employee_dept` | Employee(DepID) | FK to Department - organizational hierarchy queries |
| `idx_project_customer` | Project(CID) | FK to Customer - core business relationship queries |
| `idx_works_employee` | Works(EmpID) | M:N relationship - employee project assignments |
| `idx_works_project` | Works(PrID) | M:N relationship - project team lookups |
| `idx_employee_email` | Employee(Email) | Unique identifier - login/authentication lookups |

All indexes target foreign keys (for JOIN performance) and frequently queried columns.

## Notes for Viva
- Run `demo_queries.sql` to show constraint violations and trigger behavior
- Use different user accounts to demonstrate access control
- View `EmployeeProjectSummary` shows combined employee data
- All foreign keys use RESTRICT or CASCADE appropriately
- **Frontend Bonus**: Launch `app.py` to demonstrate full integration
