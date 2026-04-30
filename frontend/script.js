// BiDi Database Frontend - Interactive Demo

function showDemo(type) {
    const output = document.getElementById('demo-output');
    
    const demos = {
        email: {
            title: '❌ Constraint Violation: Invalid Email',
            sql: `INSERT INTO Employee (Email, Name, DepID, Salary)
VALUES ('invalid.email.com', 'Test', 1, 3000.00);`,
            error: `ERROR: new row for relation "employee" 
violates check constraint "chk_employee_email"
DETAIL: Failing row contains (12, invalid.email.com, ...).`,
            explanation: 'The CHECK constraint enforces that Email must contain @ symbol.'
        },
        salary: {
            title: '❌ Constraint Violation: Negative Salary',
            sql: `INSERT INTO Employee (Email, Name, DepID, Salary)
VALUES ('test@bidi.fi', 'Test', 1, -1000.00);`,
            error: `ERROR: new row for relation "employee" 
violates check constraint "chk_salary_positive"
DETAIL: Failing row contains (14, test@bidi.fi, ..., -1000.00).`,
            explanation: 'Salary must be positive - prevents data entry errors.'
        },
        budget: {
            title: '❌ Trigger: Budget Reduction Blocked',
            sql: `UPDATE Project 
SET Budget = 100000 
WHERE PrID = 1;`,
            error: `ERROR: Budget reduction not allowed. 
Old: 150000.00, New: 100000.00
CONTEXT: PL/pgSQL function check_budget_increase()`,
            explanation: 'The trigger enforces BiDi business rule: budgets can only increase (scope additions), never decrease.'
        }
    };
    
    const demo = demos[type];
    
    output.innerHTML = `
        <div class="demo-result">
            <h4>${demo.title}</h4>
            <div class="sql-block">
                <strong>SQL:</strong>
                <pre><code>${demo.sql}</code></pre>
            </div>
            <div class="error-block" style="background: #fee; padding: 1rem; border-radius: 5px; margin: 1rem 0; border-left: 4px solid #e74c3c;">
                <strong>Result:</strong>
                <pre style="margin: 0.5rem 0 0 0; color: #c0392b;">${demo.error}</pre>
            </div>
            <p style="background: #e8f4f8; padding: 1rem; border-radius: 5px;">
                <strong>💡 Why this happens:</strong> ${demo.explanation}
            </p>
        </div>
    `;
    output.className = 'demo-output error';
}

// Smooth scrolling for navigation
document.querySelectorAll('nav a').forEach(anchor => {
    anchor.addEventListener('click', function (e) {
        e.preventDefault();
        const target = document.querySelector(this.getAttribute('href'));
        if (target) {
            target.scrollIntoView({
                behavior: 'smooth',
                block: 'start'
            });
        }
    });
});

// Add animation on scroll
const observerOptions = {
    threshold: 0.1,
    rootMargin: '0px 0px -50px 0px'
};

const observer = new IntersectionObserver((entries) => {
    entries.forEach(entry => {
        if (entry.isIntersecting) {
            entry.target.style.opacity = '1';
            entry.target.style.transform = 'translateY(0)';
        }
    });
}, observerOptions);

// Observe all cards
document.querySelectorAll('.card').forEach(card => {
    card.style.opacity = '0';
    card.style.transform = 'translateY(20px)';
    card.style.transition = 'opacity 0.6s ease, transform 0.6s ease';
    observer.observe(card);
});

console.log('🚀 BiDi Database Frontend loaded successfully!');
