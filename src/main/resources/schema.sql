-- H2 Database Schema for ToDo App
-- This script creates the database schema and will be executed at startup

-- Drop table if exists (for clean restart)
DROP TABLE IF EXISTS todos;

-- Create the todos table
CREATE TABLE todos (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    description TEXT,
    start_date DATE,
    end_date DATE,
    priority VARCHAR(20) CHECK (priority IN ('LOW', 'MEDIUM', 'HIGH', 'URGENT')),
    comments TEXT,
    collaborators VARCHAR(500),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    completed BOOLEAN DEFAULT FALSE
);

-- Create indexes for better performance
CREATE INDEX idx_todos_priority ON todos(priority);
CREATE INDEX idx_todos_completed ON todos(completed);
CREATE INDEX idx_todos_end_date ON todos(end_date);
CREATE INDEX idx_todos_created_at ON todos(created_at);

-- Note: H2 doesn't support PostgreSQL-style triggers, so we'll handle updated_at in the application code
