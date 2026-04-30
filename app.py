"""
BiDi Database Management System
Frontend Application for CT60A7660 Database Systems Management
Bonus: +10 points for demonstrating database connectivity, RBAC, constraints and triggers

Requirements:
- Python 3.8+
- pip install streamlit psycopg2-binary pandas
- Run: streamlit run app.py
"""

import streamlit as st
import psycopg2
import psycopg2.errors
import pandas as pd
from contextlib import contextmanager

# ============================================
# DATABASE CONFIGURATION
# ============================================
DB_CONFIG = {
    "dbname": "bidi",
    "host": "localhost",
    "port": "5432"
}

# ============================================
# DATABASE CONNECTION HELPER
# ============================================
@contextmanager
def get_db_connection():
    """Context manager for database connections using current user credentials."""
    conn = None
    try:
        conn = psycopg2.connect(
            dbname=DB_CONFIG["dbname"],
            user=st.session_state.get("db_user", "postgres"),
            password=st.session_state.get("db_password", ""),
            host=DB_CONFIG["host"],
            port=DB_CONFIG["port"]
        )
        yield conn
    except psycopg2.errors.InsufficientPrivilege as e:
        st.error(f"🔒 Access Denied: {e}")
        raise
    except psycopg2.Error as e:
        st.error(f"❌ Database Error: {e}")
        raise
    finally:
        if conn:
            conn.close()

def run_query(query, params=None, fetch=True):
    """Execute a query and return results."""
    with get_db_connection() as conn:
        with conn.cursor() as cur:
            cur.execute(query, params)
            if fetch and cur.description:
                columns = [desc[0] for desc in cur.description]
                data = cur.fetchall()
                return pd.DataFrame(data, columns=columns) if data else pd.DataFrame()
            conn.commit()
            return None

# ============================================
# AUTHENTICATION
# ============================================
def login_screen():
    """Display login screen and authenticate users."""
    st.title("🔐 BiDi Database System Login")
    st.markdown("---")
    
    col1, col2, col3 = st.columns([1, 2, 1])
    
    with col2:
        st.subheader("Please Log In")
        
        # Pre-filled credentials for demo
        username = st.text_input("Username", value="manager1")
        password = st.text_input("Password", value="ManagerPass123!", type="password")
        
        st.markdown("""
        **Demo Credentials:**
        - **Manager**: `manager1` / `ManagerPass123!`
        - **Employee**: `employee1` / `EmployeePass123!`
        """)
        
        if st.button("🔓 Login", use_container_width=True):
            try:
                # Test connection with provided credentials
                conn = psycopg2.connect(
                    dbname=DB_CONFIG["dbname"],
                    user=username,
                    password=password,
                    host=DB_CONFIG["host"],
                    port=DB_CONFIG["port"]
                )
                conn.close()
                
                # Store credentials in session state
                st.session_state["authenticated"] = True
                st.session_state["db_user"] = username
                st.session_state["db_password"] = password
                st.session_state["role"] = "Manager" if "manager" in username.lower() else "Employee"
                st.session_state["page"] = "Dashboard"
                
                st.success(f"✅ Welcome, {username}! Role: {st.session_state['role']}")
                st.rerun()
                
            except psycopg2.Error as e:
                st.error(f"❌ Login failed: {e}")

def logout():
    """Clear session and logout."""
    for key in list(st.session_state.keys()):
        del st.session_state[key]
    st.rerun()

# ============================================
# DASHBOARD PAGE
# ============================================
def dashboard_page():
    """Display dashboard with KPI metrics."""
    st.title("📊 BiDi Dashboard")
    st.markdown(f"Welcome, **{st.session_state['db_user']}** ({st.session_state['role']})")
    st.markdown("---")
    
    # KPI Cards
    col1, col2, col3, col4 = st.columns(4)
    
    try:
        # Total Projects
        df_projects = run_query("SELECT COUNT(*) as count FROM Project")
        total_projects = df_projects['count'].iloc[0] if not df_projects.empty else 0
        
        # Total Employees
        df_employees = run_query("SELECT COUNT(*) as count FROM EmployeePublic")
        total_employees = df_employees['count'].iloc[0] if not df_employees.empty else 0
        
        # Total Budget
        df_budget = run_query("SELECT SUM(Budget) as total FROM Project")
        total_budget = df_budget['total'].iloc[0] if not df_budget.empty else 0
        
        # Active Projects
        df_active = run_query("SELECT COUNT(*) as count FROM Project WHERE Status = 'Active'")
        active_projects = df_active['count'].iloc[0] if not df_active.empty else 0
        
        with col1:
            st.metric("📁 Total Projects", total_projects)
        with col2:
            st.metric("👥 Total Employees", total_employees)
        with col3:
            st.metric("💰 Total Budget", f"€{total_budget:,.0f}")
        with col4:
            st.metric("⚡ Active Projects", active_projects)
            
    except Exception as e:
        st.error(f"Error loading metrics: {e}")
    
    st.markdown("---")
    
    # Recent Projects Table
    st.subheader("📋 Recent Projects")
    try:
        df = run_query("""
            SELECT p.Name, p.Budget, p.Status, c.Name as Customer, p.deadline
            FROM Project p
            JOIN Customer c ON p.CID = c.CID
            ORDER BY p.PrID DESC
            LIMIT 5
        """)
        st.dataframe(df, use_container_width=True)
    except Exception as e:
        st.error(f"Error: {e}")

# ============================================
# PROJECTS PAGE
# ============================================
def projects_page():
    """Display and manage projects."""
    st.title("📁 Projects Management")
    st.markdown("---")
    
    # Add New Project Form (Managers only can INSERT)
    with st.expander("➕ Add New Project", expanded=False):
        with st.form("add_project_form"):
            col1, col2 = st.columns(2)
            
            with col1:
                name = st.text_input("Project Name", placeholder="e.g., New Health App")
                budget = st.number_input("Budget (€)", min_value=1, value=50000)
                status = st.selectbox("Status", ["Planning", "Active", "Completed", "Cancelled"])
            
            with col2:
                # Get customers for dropdown
                try:
                    df_customers = run_query("SELECT CID, Name FROM Customer")
                    customer_options = {f"{row['name']} (ID: {row['cid']})": row['cid'] 
                                       for _, row in df_customers.iterrows()}
                    customer_selected = st.selectbox("Customer", list(customer_options.keys()))
                    cid = customer_options[customer_selected]
                except:
                    cid = st.number_input("Customer ID", min_value=1, value=1)
                
                start_date = st.date_input("Start Date")
                deadline = st.date_input("Deadline")
            
            submitted = st.form_submit_button("💾 Create Project", use_container_width=True)
            
            if submitted:
                try:
                    query = """
                        INSERT INTO Project (Name, Budget, Status, CID, startDate, deadline)
                        VALUES (%s, %s, %s, %s, %s, %s)
                    """
                    run_query(query, (name, budget, status, cid, start_date, deadline), fetch=False)
                    st.success(f"✅ Project '{name}' created successfully!")
                    st.rerun()
                except psycopg2.errors.InsufficientPrivilege:
                    st.warning("🔒 Access Denied: You do not have permission to create projects.")
                except psycopg2.Error as e:
                    st.error(f"❌ Database Error: {e}")
    
    st.markdown("---")
    
    # Projects List
    st.subheader("📋 All Projects")
    try:
        df = run_query("""
            SELECT p.PrID, p.Name, p.Budget, p.Status, 
                   c.Name as Customer, p.startDate, p.deadline
            FROM Project p
            JOIN Customer c ON p.CID = c.CID
            ORDER BY p.PrID
        """)
        st.dataframe(df, use_container_width=True)
    except psycopg2.errors.InsufficientPrivilege:
        st.warning("🔒 Access Denied: You do not have permission to view projects.")
    except Exception as e:
        st.error(f"❌ Error: {e}")

# ============================================
# EMPLOYEES PAGE
# ============================================
def employees_page():
    """Display and manage employees."""
    st.title("👥 Employees Management")
    st.markdown("---")
    
    # Add New Employee Form (Managers only)
    with st.expander("➕ Add New Employee", expanded=False):
        with st.form("add_employee_form"):
            col1, col2 = st.columns(2)
            
            with col1:
                name = st.text_input("Full Name", placeholder="e.g., John Smith")
                email = st.text_input("Email", placeholder="name@bidi.fi")
                salary = st.number_input("Salary (€)", min_value=1, value=4000)
            
            with col2:
                try:
                    df_depts = run_query("SELECT DepID, Name FROM Department")
                    dept_options = {f"{row['name']} (ID: {row['depid']})": row['depid'] 
                                   for _, row in df_depts.iterrows()}
                    dept_selected = st.selectbox("Department", list(dept_options.keys()))
                    depid = dept_options[dept_selected]
                except:
                    depid = st.number_input("Department ID", min_value=1, value=1)
            
            submitted = st.form_submit_button("💾 Add Employee", use_container_width=True)
            
            if submitted:
                try:
                    query = """
                        INSERT INTO Employee (Name, Email, Salary, DepID)
                        VALUES (%s, %s, %s, %s)
                    """
                    run_query(query, (name, email, salary, depid), fetch=False)
                    st.success(f"✅ Employee '{name}' added successfully!")
                    st.rerun()
                except psycopg2.errors.InsufficientPrivilege:
                    st.warning("🔒 Access Denied: You do not have permission to add employees.")
                except psycopg2.Error as e:
                    st.error(f"❌ Database Error: {e}")
    
    st.markdown("---")
    
    # Employees List - DEMONSTRATE RBAC
    st.subheader("📋 All Employees")
    
    # Try to access full Employee table (will fail for employee role)
    try:
        if st.session_state["role"] == "Manager":
            # Managers can see full Employee table with salary
            df = run_query("""
                SELECT e.EmpID, e.Name, e.Email, e.Salary, e.HireDate, d.Name as Department
                FROM Employee e
                JOIN Department d ON e.DepID = d.DepID
                ORDER BY e.EmpID
            """)
            st.success("✅ Full access granted (Manager role)")
            st.dataframe(df, use_container_width=True)
        else:
            # Employees can only see EmployeePublic view (no salary)
            df = run_query("""
                SELECT EmpID, Name, Email, HireDate
                FROM EmployeePublic
                ORDER BY EmpID
            """)
            st.info("ℹ️ Limited access (Employee role) - Salary data hidden")
            st.dataframe(df, use_container_width=True)
            
            # Demonstrate that direct Employee table access is blocked
            if st.button("⚠️ Attempt to Access Full Employee Table (Will Fail)"):
                try:
                    df_blocked = run_query("SELECT * FROM Employee")
                    st.dataframe(df_blocked)
                except psycopg2.errors.InsufficientPrivilege:
                    st.warning("🔒 Access Denied: You do not have permission to view this data.")
                    st.error("Database blocked action: permission denied for table Employee")
                    
    except psycopg2.errors.InsufficientPrivilege:
        st.warning("🔒 Access Denied: You do not have permission to view this data.")
    except Exception as e:
        st.error(f"❌ Error: {e}")

# ============================================
# TESTING PAGE - CONSTRAINTS & TRIGGERS
# ============================================
def testing_page():
    """Demonstrate constraints and triggers."""
    st.title("🧪 Testing: Constraints & Triggers")
    st.markdown("This page demonstrates the database constraints and triggers.")
    st.markdown("---")
    
    # CONSTRAINTS SECTION
    st.header("🔒 Constraints Testing")
    st.markdown("Click buttons to deliberately violate database rules:")
    
    col1, col2 = st.columns(2)
    
    with col1:
        st.subheader("📋 CHECK Constraints")
        
        # Negative Budget
        if st.button("❌ Test: Negative Budget", use_container_width=True):
            try:
                run_query(
                    """INSERT INTO Project (Name, Budget, Status, CID, startDate, deadline) 
                     VALUES ('Bad Project', -500, 'Planning', 1, '2024-01-01', '2024-12-31')""",
                    fetch=False
                )
                st.error("❌ Constraint failed to block!")
            except psycopg2.errors.CheckViolation as e:
                st.success("✅ Constraint worked!")
                st.error(f"Database blocked action: {e}")
            except psycopg2.Error as e:
                st.error(f"Database blocked action: {e}")
        
        # Invalid Email
        if st.button("❌ Test: Invalid Email Format", use_container_width=True):
            try:
                run_query(
                    """INSERT INTO Employee (Name, Email, Salary, DepID) 
                     VALUES ('Test User', 'bad_email_no_at', 3000, 1)""",
                    fetch=False
                )
                st.error("❌ Constraint failed to block!")
            except psycopg2.errors.CheckViolation as e:
                st.success("✅ Constraint worked!")
                st.error(f"Database blocked action: {e}")
            except psycopg2.Error as e:
                st.error(f"Database blocked action: {e}")
        
        # Negative Salary
        if st.button("❌ Test: Negative Salary", use_container_width=True):
            try:
                run_query(
                    """INSERT INTO Employee (Name, Email, Salary, DepID) 
                     VALUES ('Test User', 'test@bidi.fi', -1000, 1)""",
                    fetch=False
                )
                st.error("❌ Constraint failed to block!")
            except psycopg2.errors.CheckViolation as e:
                st.success("✅ Constraint worked!")
                st.error(f"Database blocked action: {e}")
            except psycopg2.Error as e:
                st.error(f"Database blocked action: {e}")
    
    with col2:
        st.subheader("🔗 Foreign Key Constraints")
        
        # Invalid Department ID
        if st.button("❌ Test: Invalid Department FK", use_container_width=True):
            try:
                run_query(
                    """INSERT INTO Employee (Name, Email, Salary, DepID) 
                     VALUES ('Test User', 'test@bidi.fi', 3000, 999)""",
                    fetch=False
                )
                st.error("❌ FK constraint failed to block!")
            except psycopg2.errors.ForeignKeyViolation as e:
                st.success("✅ FK Constraint worked!")
                st.error(f"Database blocked action: {e}")
            except psycopg2.Error as e:
                st.error(f"Database blocked action: {e}")
        
        # Invalid Customer ID
        if st.button("❌ Test: Invalid Customer FK", use_container_width=True):
            try:
                run_query(
                    """INSERT INTO Project (Name, Budget, Status, CID, startDate, deadline) 
                     VALUES ('Bad Project', 50000, 'Planning', 999, '2024-01-01', '2024-12-31')""",
                    fetch=False
                )
                st.error("❌ FK constraint failed to block!")
            except psycopg2.errors.ForeignKeyViolation as e:
                st.success("✅ FK Constraint worked!")
                st.error(f"Database blocked action: {e}")
            except psycopg2.Error as e:
                st.error(f"Database blocked action: {e}")
    
    st.markdown("---")
    
    # TRIGGERS SECTION
    st.header("⚡ Triggers Testing")
    
    col1, col2 = st.columns(2)
    
    with col1:
        st.subheader("💰 Budget Protection Trigger")
        
        if st.button("❌ Test: Reduce Project Budget", use_container_width=True):
            try:
                # Get current budget
                df = run_query("SELECT Budget FROM Project WHERE PrID = 1")
                current_budget = df['budget'].iloc[0] if not df.empty else 0
                new_budget = current_budget - 1000 if current_budget > 1000 else 1000
                
                run_query(
                    "UPDATE Project SET Budget = %s WHERE PrID = 1",
                    (new_budget,),
                    fetch=False
                )
                st.error("❌ Trigger failed to block budget reduction!")
            except psycopg2.errors.RaiseException as e:
                st.success("✅ Budget Protection Trigger worked!")
                st.error(f"Database blocked action: {e}")
            except psycopg2.Error as e:
                st.error(f"Database blocked action: {e}")
    
    with col2:
        st.subheader("📝 Salary Audit Log Trigger")
        
        if st.button("✅ Test: Update Employee Salary (Allowed)", use_container_width=True):
            try:
                # Get current salary
                df = run_query("SELECT Salary FROM Employee WHERE EmpID = 1")
                current_salary = df['salary'].iloc[0] if not df.empty else 0
                new_salary = current_salary + 100
                
                run_query(
                    "UPDATE Employee SET Salary = %s WHERE EmpID = 1",
                    (new_salary,),
                    fetch=False
                )
                
                # Check if logged
                df_log = run_query(
                    "SELECT * FROM SalaryLog WHERE EmpID = 1 ORDER BY ChangeDate DESC LIMIT 1"
                )
                if not df_log.empty:
                    st.success(f"✅ Salary updated and logged! New salary: €{new_salary}")
                    st.info("Check SalaryLog table for audit trail")
                else:
                    st.warning("Salary updated but not logged (check trigger)")
                    
            except psycopg2.errors.InsufficientPrivilege:
                st.warning("🔒 Access Denied: You don't have permission to update salaries.")
            except psycopg2.Error as e:
                st.error(f"Database error: {e}")
    
    st.markdown("---")
    
    # ACCESS CONTROL SECTION
    st.header("🔐 Role-Based Access Control Testing")
    
    if st.session_state["role"] == "Employee":
        st.info("You are logged in as **Employee**. Try these access tests:")
        
        if st.button("❌ Test: Employee Access to Full Employee Table", use_container_width=True):
            try:
                df = run_query("SELECT * FROM Employee")
                st.dataframe(df)
            except psycopg2.errors.InsufficientPrivilege:
                st.success("✅ RBAC Working!")
                st.warning("🔒 Access Denied: You do not have permission to view this data.")
                st.error("Database blocked action: permission denied for table Employee")
    else:
        st.info("You are logged in as **Manager**. You have full access.")
        st.success("✅ Manager can view all data including Employee salaries")

# ============================================
# MAIN APP
# ============================================
def main():
    """Main application entry point."""
    st.set_page_config(
        page_title="BiDi Database System",
        page_icon="🏥",
        layout="wide",
        initial_sidebar_state="expanded"
    )
    
    # Initialize session state
    if "authenticated" not in st.session_state:
        st.session_state["authenticated"] = False
    
    # Show login screen if not authenticated
    if not st.session_state["authenticated"]:
        login_screen()
        return
    
    # Sidebar Navigation
    with st.sidebar:
        st.title("🏥 BiDi System")
        st.markdown(f"**User:** {st.session_state['db_user']}")
        st.markdown(f"**Role:** {st.session_state['role']}")
        st.markdown("---")
        
        # Navigation
        page = st.radio(
            "Navigation",
            ["Dashboard", "Projects", "Employees", "Testing"],
            index=["Dashboard", "Projects", "Employees", "Testing"].index(
                st.session_state.get("page", "Dashboard")
            )
        )
        st.session_state["page"] = page
        
        st.markdown("---")
        
        # Logout button
        if st.button("🚪 Logout", use_container_width=True):
            logout()
    
    # Display selected page
    if st.session_state["page"] == "Dashboard":
        dashboard_page()
    elif st.session_state["page"] == "Projects":
        projects_page()
    elif st.session_state["page"] == "Employees":
        employees_page()
    elif st.session_state["page"] == "Testing":
        testing_page()

if __name__ == "__main__":
    main()
