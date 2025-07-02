-- Sample data for ToDo App
-- This script loads initial data and will be executed at startup after schema.sql

-- Insert sample todos with various priorities and states
INSERT INTO todos (description, start_date, end_date, priority, comments, collaborators, completed, created_at, updated_at) VALUES
('Complete project documentation', '2024-07-01', '2024-07-05', 'HIGH', 'Include API documentation and user guide', 'John Doe, Jane Smith', false, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
('Review code changes', '2024-07-02', '2024-07-03', 'MEDIUM', 'Focus on security and performance', 'Alice Johnson', false, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
('Prepare presentation for client meeting', '2024-07-01', '2024-07-02', 'URGENT', 'Include demo and Q&A section', 'Bob Wilson, Carol Brown', false, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
('Update database schema', '2024-06-25', '2024-06-30', 'LOW', 'Add new indexes for performance', 'David Lee', true, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
('Test new features', '2024-07-03', '2024-07-08', 'MEDIUM', 'Comprehensive testing required', 'Eva Martinez, Frank Taylor', false, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
('Setup CI/CD pipeline', '2024-07-01', '2024-07-10', 'HIGH', 'Configure automated testing and deployment', 'Mike Johnson', false, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
('Refactor authentication module', '2024-07-05', '2024-07-12', 'MEDIUM', 'Improve security and code maintainability', 'Sarah Wilson', false, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
('Write unit tests', '2024-06-28', '2024-07-01', 'HIGH', 'Achieve 80% code coverage', 'Tom Brown', true, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
('Deploy to staging environment', '2024-07-02', '2024-07-03', 'URGENT', 'Test before production deployment', 'Lisa Davis', false, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
('Optimize database queries', '2024-07-04', '2024-07-06', 'LOW', 'Improve application performance', 'Chris Taylor', false, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP);

-- Insert some overdue todos for testing
INSERT INTO todos (description, start_date, end_date, priority, comments, collaborators, completed, created_at, updated_at) VALUES
('Fix critical bug in payment system', '2024-06-20', '2024-06-25', 'URGENT', 'Customer reported payment failures', 'Emergency Team', false, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
('Update security certificates', '2024-06-15', '2024-06-20', 'HIGH', 'Certificates expiring soon', 'Security Team', false, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP);

-- Insert some completed todos
INSERT INTO todos (description, start_date, end_date, priority, comments, collaborators, completed, created_at, updated_at) VALUES
('Setup development environment', '2024-06-01', '2024-06-05', 'MEDIUM', 'Configure local development setup', 'Dev Team', true, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
('Create project repository', '2024-06-01', '2024-06-02', 'HIGH', 'Initialize Git repository with proper structure', 'Lead Developer', true, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
('Design database schema', '2024-06-03', '2024-06-08', 'HIGH', 'Create ERD and table definitions', 'Database Team', true, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP);
