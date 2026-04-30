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
| `app.py` | Streamlit web application for database demonstration |
| `requirements.txt` | Python dependencies |
| `.gitignore` | Git ignore patterns |

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

## Project Implementation Summary

### Phase 2 Requirements (25 Points)

| Component | Requirements | Implementation |
|-----------|--------------|----------------|
| **Constraints (5 pts)** | 2 CHECK, 2 DEFAULT, PKs, FKs, NULL handling | 7 CHECK constraints, 8 DEFAULT values, all PKs/FKs, proper NULL handling |
| **Triggers (5 pts)** | 3 meaningful triggers | 4 triggers: budget protection, salary audit logging, auto-completion, delete prevention |
| **Queries (10 pts)** | SELECT, JOINs (3+ tables), Aggregations, VIEW, DML | 2+ SELECT, 3+ JOIN queries, 2+ aggregations, 1 VIEW, INSERT/UPDATE/DELETE examples |
| **Access Control (5 pts)** | 2 roles, 2 users, different privileges | 2 roles (manager, employee), 4 users, RBAC at DB level, RLS policies |

### Extended Implementation

| Feature | Description |
|---------|-------------|
| **Indexing Strategy** | 5 optimized indexes on foreign keys and query columns (Employee.DepID, Project.CID, Works.EmpID/PrID, Employee.Email) |
| **Web Application** | Streamlit frontend with database connectivity, role-based access, constraint and trigger demonstration |
| **Additional Constraints** | Exceeds minimum with 7 CHECK and 8 DEFAULT values |
| **Additional Triggers** | 4 triggers implemented (exceeds requirement of 3) |

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

## Design Decisions

### ER Model Implementation
- **Commissions Relationship**: Implemented as N:1 (many projects → one customer) by storing CID directly in Project table. Each project has exactly one customer, while customers can have multiple projects.

### Additional Attributes (Beyond ER Model)
The following attributes were added to support business operations:
- **Employee.Salary**: Required for payroll and audit logging
- **Project.Status**: Tracks project lifecycle (Planning, Active, Completed, Cancelled)
- **Works.hoursWorked**: Tracks employee contribution to projects
- **Location.Country**: Default 'Finland' as BiDi operates nationally

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

## Indexing Strategy

Optimized indexes implemented for query performance:

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
- Launch `app.py` to demonstrate web application with full database integration
