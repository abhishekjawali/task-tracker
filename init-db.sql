-- PostgreSQL initialization script for ToDo Manager
-- This script creates the necessary table structure

-- Create the todos table
CREATE TABLE IF NOT EXISTS todos (
    id BIGSERIAL PRIMARY KEY,
    description TEXT NOT NULL,
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

-- Insert sample data (optional - remove if you don't want sample data)
INSERT INTO todos (description, start_date, end_date, priority, comments, collaborators, completed) VALUES
('Complete project documentation', '2024-01-15', '2024-01-20', 'HIGH', 'Include API documentation and deployment guide', 'John Doe, Jane Smith', false),
('Review code changes', '2024-01-16', '2024-01-17', 'MEDIUM', 'Focus on security and performance improvements', 'Alice Johnson', false),
('Deploy to staging environment', '2024-01-18', '2024-01-19', 'HIGH', 'Test all features before production deployment', 'Bob Wilson', false),
('Update user interface', '2024-01-10', '2024-01-25', 'LOW', 'Improve mobile responsiveness', 'Sarah Davis', false),
('Database optimization', '2024-01-12', '2024-01-22', 'URGENT', 'Optimize slow queries and add indexes', 'Mike Brown', false),
('Security audit', '2024-01-20', '2024-01-30', 'HIGH', 'Comprehensive security review', 'Security Team', false),
('Write unit tests', '2024-01-14', '2024-01-21', 'MEDIUM', 'Achieve 80% code coverage', 'Development Team', false),
('Setup monitoring', '2024-01-16', '2024-01-23', 'MEDIUM', 'Configure CloudWatch and alerts', 'DevOps Team', false),
('User training materials', '2024-01-25', '2024-02-05', 'LOW', 'Create user guides and video tutorials', 'Training Team', false),
('Performance testing', '2024-01-22', '2024-01-28', 'HIGH', 'Load testing and optimization', 'QA Team', false),
('Backup strategy implementation', '2024-01-08', '2024-01-15', 'URGENT', 'Automated backups and recovery procedures', 'Infrastructure Team', true),
('API documentation', '2024-01-05', '2024-01-12', 'MEDIUM', 'Complete REST API documentation', 'Technical Writers', true),
('Initial project setup', '2024-01-01', '2024-01-07', 'HIGH', 'Project initialization and basic structure', 'Project Manager', true);

-- Display table information
SELECT 'Sample data inserted successfully. Total todos: ' || COUNT(*) as message FROM todos;
