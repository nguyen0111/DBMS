#!/bin/bash

# BiDi Database Setup Script
# CT60A7660 - Database Systems Management

echo "======================================"
echo "BiDi Database Setup"
echo "======================================"

# Check if database name provided
DB_NAME=${1:-bidi}

echo "Database: $DB_NAME"
echo ""

# Create database
echo "Creating database..."
dropdb --if-exists $DB_NAME
createdb $DB_NAME

if [ $? -ne 0 ]; then
    echo "Error: Failed to create database. Make sure PostgreSQL is running."
    exit 1
fi

# Run SQL files in order
echo "Creating schema..."
psql -d $DB_NAME -f schema.sql

echo "Creating triggers..."
psql -d $DB_NAME -f triggers.sql

echo "Inserting seed data..."
psql -d $DB_NAME -f seed_data.sql

echo "Creating queries and views..."
psql -d $DB_NAME -f queries.sql

echo "Setting up access control..."
psql -d $DB_NAME -f access_control.sql

echo ""
echo "======================================"
echo "Setup Complete!"
echo "======================================"
echo ""
echo "Database: $DB_NAME"
echo ""
echo "Test users created:"
echo "  - manager1 / ManagerPass123!"
echo "  - employee1 / EmployeePass123!"
echo ""
echo "Useful commands:"
echo "  psql -d $DB_NAME                    # Connect as default user"
echo "  psql -U manager1 -d $DB_NAME        # Connect as manager"
echo "  psql -U employee1 -d $DB_NAME      # Connect as employee"
echo "  psql -d $DB_NAME -f demo_queries.sql  # Run demonstrations"
echo ""
