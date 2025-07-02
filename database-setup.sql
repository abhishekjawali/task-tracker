-- PostgreSQL Database Setup for ToDo App

-- Create database (run this as postgres superuser)
-- CREATE DATABASE todoapp;

-- Create user (run this as postgres superuser)
-- CREATE USER todouser WITH PASSWORD 'todopass';

-- Grant privileges (run this as postgres superuser)
-- GRANT ALL PRIVILEGES ON DATABASE todoapp TO todouser;

-- Connect to todoapp database and run the following:

-- Create the todos table (this will be auto-created by Hibernate, but here's the manual version)
CREATE TABLE IF NOT EXISTS todos (
    id BIGSERIAL PRIMARY KEY,
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
CREATE INDEX IF NOT EXISTS idx_todos_priority ON todos(priority);
CREATE INDEX IF NOT EXISTS idx_todos_completed ON todos(completed);
CREATE INDEX IF NOT EXISTS idx_todos_end_date ON todos(end_date);
CREATE INDEX IF NOT EXISTS idx_todos_created_at ON todos(created_at);

-- Create a function to update the updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Create trigger to automatically update updated_at
DROP TRIGGER IF EXISTS update_todos_updated_at ON todos;
CREATE TRIGGER update_todos_updated_at
    BEFORE UPDATE ON todos
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Insert some sample data (optional)
INSERT INTO todos (description, start_date, end_date, priority, comments, collaborators, completed) VALUES
('Complete project documentation', '2024-01-15', '2024-01-20', 'HIGH', 'Include API documentation and user guide', 'John Doe, Jane Smith', false),
('Review code changes', '2024-01-16', '2024-01-17', 'MEDIUM', 'Focus on security and performance', 'Alice Johnson', false),
('Prepare presentation for client meeting', '2024-01-18', '2024-01-19', 'URGENT', 'Include demo and Q&A section', 'Bob Wilson, Carol Brown', false),
('Update database schema', '2024-01-10', '2024-01-15', 'LOW', 'Add new indexes for performance', 'David Lee', true),
('Test new features', '2024-01-20', '2024-01-25', 'MEDIUM', 'Comprehensive testing required', 'Eva Martinez, Frank Taylor', false);

-- Grant permissions to todouser
GRANT ALL PRIVILEGES ON TABLE todos TO todouser;
GRANT USAGE, SELECT ON SEQUENCE todos_id_seq TO todouser;
