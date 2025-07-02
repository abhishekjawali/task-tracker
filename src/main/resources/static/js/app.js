// ToDo App JavaScript

class TodoApp {
    constructor() {
        this.todos = [];
        this.currentEditId = null;
        this.init();
    }

    init() {
        this.setupEventListeners();
        this.updateCurrentDate();
        this.loadTodos();
        
        // Update date every minute
        setInterval(() => this.updateCurrentDate(), 60000);
    }

    setupEventListeners() {
        // Form submission
        document.getElementById('todoForm').addEventListener('submit', (e) => {
            e.preventDefault();
            this.createTodo();
        });

        // Search functionality
        document.getElementById('searchInput').addEventListener('input', (e) => {
            this.searchTodos(e.target.value);
        });

        // Filter functionality
        document.getElementById('filterSelect').addEventListener('change', (e) => {
            this.filterTodos(e.target.value);
        });

        // Sort functionality
        document.getElementById('sortSelect').addEventListener('change', (e) => {
            this.sortTodos(e.target.value);
        });

        // Edit form submission
        document.getElementById('saveEdit').addEventListener('click', () => {
            this.saveEdit();
        });

        // Modal events
        document.getElementById('editModal').addEventListener('hidden.bs.modal', () => {
            this.currentEditId = null;
        });
    }

    updateCurrentDate() {
        const now = new Date();
        const options = { 
            weekday: 'long', 
            year: 'numeric', 
            month: 'long', 
            day: 'numeric' 
        };
        document.getElementById('currentDate').textContent = now.toLocaleDateString('en-US', options);
    }

    async loadTodos() {
        try {
            this.showLoading();
            const response = await fetch('/api/todos');
            if (response.ok) {
                this.todos = await response.json();
                this.renderTodos();
                this.updateStatistics();
            } else {
                this.showError('Failed to load todos');
            }
        } catch (error) {
            console.error('Error loading todos:', error);
            this.showError('Failed to load todos');
        } finally {
            this.hideLoading();
        }
    }

    async createTodo() {
        const formData = this.getFormData();
        
        if (!formData.description.trim()) {
            this.showError('Description is required');
            return;
        }

        try {
            const response = await fetch('/api/todos', {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                },
                body: JSON.stringify(formData)
            });

            if (response.ok) {
                const newTodo = await response.json();
                this.todos.unshift(newTodo);
                this.renderTodos();
                this.updateStatistics();
                this.clearForm();
                this.showSuccess('Todo created successfully!');
            } else {
                this.showError('Failed to create todo');
            }
        } catch (error) {
            console.error('Error creating todo:', error);
            this.showError('Failed to create todo');
        }
    }

    async updateTodo(id, todoData) {
        try {
            const response = await fetch(`/api/todos/${id}`, {
                method: 'PUT',
                headers: {
                    'Content-Type': 'application/json',
                },
                body: JSON.stringify(todoData)
            });

            if (response.ok) {
                const updatedTodo = await response.json();
                const index = this.todos.findIndex(todo => todo.id === id);
                if (index !== -1) {
                    this.todos[index] = updatedTodo;
                    this.renderTodos();
                    this.updateStatistics();
                }
                return updatedTodo;
            } else {
                this.showError('Failed to update todo');
                return null;
            }
        } catch (error) {
            console.error('Error updating todo:', error);
            this.showError('Failed to update todo');
            return null;
        }
    }

    async deleteTodo(id) {
        if (!confirm('Are you sure you want to delete this todo?')) {
            return;
        }

        try {
            const response = await fetch(`/api/todos/${id}`, {
                method: 'DELETE'
            });

            if (response.ok) {
                this.todos = this.todos.filter(todo => todo.id !== id);
                this.renderTodos();
                this.updateStatistics();
                this.showSuccess('Todo deleted successfully!');
            } else {
                this.showError('Failed to delete todo');
            }
        } catch (error) {
            console.error('Error deleting todo:', error);
            this.showError('Failed to delete todo');
        }
    }

    async toggleComplete(id) {
        try {
            const response = await fetch(`/api/todos/${id}/toggle`, {
                method: 'PATCH'
            });

            if (response.ok) {
                const updatedTodo = await response.json();
                const index = this.todos.findIndex(todo => todo.id === id);
                if (index !== -1) {
                    this.todos[index] = updatedTodo;
                    this.renderTodos();
                    this.updateStatistics();
                    this.showSuccess(updatedTodo.completed ? 'Todo completed!' : 'Todo marked as pending');
                }
            } else {
                this.showError('Failed to update todo status');
            }
        } catch (error) {
            console.error('Error toggling todo:', error);
            this.showError('Failed to update todo status');
        }
    }

    async searchTodos(query) {
        if (!query.trim()) {
            this.renderTodos();
            return;
        }

        try {
            const response = await fetch(`/api/todos?search=${encodeURIComponent(query)}`);
            if (response.ok) {
                const filteredTodos = await response.json();
                this.renderTodos(filteredTodos);
            }
        } catch (error) {
            console.error('Error searching todos:', error);
        }
    }

    async filterTodos(filter) {
        if (!filter) {
            this.renderTodos();
            return;
        }

        try {
            const response = await fetch(`/api/todos?filter=${filter}`);
            if (response.ok) {
                const filteredTodos = await response.json();
                this.renderTodos(filteredTodos);
            }
        } catch (error) {
            console.error('Error filtering todos:', error);
        }
    }

    async sortTodos(sort) {
        if (!sort) {
            this.renderTodos();
            return;
        }

        try {
            const response = await fetch(`/api/todos?sort=${sort}`);
            if (response.ok) {
                const sortedTodos = await response.json();
                this.renderTodos(sortedTodos);
            }
        } catch (error) {
            console.error('Error sorting todos:', error);
        }
    }

    renderTodos(todosToRender = this.todos) {
        const todoList = document.getElementById('todoList');
        const emptyState = document.getElementById('emptyState');

        if (todosToRender.length === 0) {
            todoList.innerHTML = '';
            emptyState.style.display = 'block';
            return;
        }

        emptyState.style.display = 'none';
        
        todoList.innerHTML = todosToRender.map(todo => this.createTodoHTML(todo)).join('');
        
        // Add event listeners to action buttons
        this.attachTodoEventListeners();
    }

    createTodoHTML(todo) {
        const priorityClass = todo.priority ? `priority-${todo.priority.toLowerCase()}` : '';
        const completedClass = todo.completed ? 'completed' : '';
        const priorityBadge = todo.priority ? 
            `<span class="badge priority-badge priority-${todo.priority.toLowerCase()}">${todo.priority}</span>` : '';
        
        const startDate = todo.startDate ? new Date(todo.startDate).toLocaleDateString() : '';
        const endDate = todo.endDate ? new Date(todo.endDate).toLocaleDateString() : '';
        const isOverdue = todo.endDate && new Date(todo.endDate) < new Date() && !todo.completed;
        
        const collaborators = todo.collaborators ? 
            `<div class="collaborators mt-2">
                <i class="fas fa-users me-1"></i>
                <small>${todo.collaborators}</small>
            </div>` : '';
            
        const comments = todo.comments ? 
            `<div class="comments">
                <i class="fas fa-comment me-1"></i>
                ${todo.comments}
            </div>` : '';

        return `
            <div class="card todo-item ${priorityClass} ${completedClass} fade-in-up" data-id="${todo.id}">
                <div class="card-body">
                    <div class="d-flex justify-content-between align-items-start mb-2">
                        <div class="flex-grow-1">
                            <h6 class="todo-description mb-1">${this.escapeHtml(todo.description)}</h6>
                            <div class="d-flex align-items-center gap-2 flex-wrap">
                                ${priorityBadge}
                                ${isOverdue ? '<span class="badge bg-danger">Overdue</span>' : ''}
                                ${todo.completed ? '<span class="badge bg-success">Completed</span>' : ''}
                            </div>
                        </div>
                        <div class="d-flex gap-1">
                            <button class="btn btn-action btn-complete" onclick="todoApp.toggleComplete(${todo.id})" 
                                    title="${todo.completed ? 'Mark as pending' : 'Mark as complete'}">
                                <i class="fas ${todo.completed ? 'fa-undo' : 'fa-check'}"></i>
                            </button>
                            <button class="btn btn-action btn-edit" onclick="todoApp.editTodo(${todo.id})" title="Edit">
                                <i class="fas fa-edit"></i>
                            </button>
                            <button class="btn btn-action btn-delete" onclick="todoApp.deleteTodo(${todo.id})" title="Delete">
                                <i class="fas fa-trash"></i>
                            </button>
                        </div>
                    </div>
                    
                    ${startDate || endDate ? `
                        <div class="date-display mb-2">
                            ${startDate ? `<i class="fas fa-calendar-plus me-1"></i>Start: ${startDate}` : ''}
                            ${startDate && endDate ? ' | ' : ''}
                            ${endDate ? `<i class="fas fa-calendar-check me-1"></i>End: ${endDate}` : ''}
                        </div>
                    ` : ''}
                    
                    ${collaborators}
                    ${comments}
                </div>
            </div>
        `;
    }

    attachTodoEventListeners() {
        // Event listeners are handled via onclick attributes in the HTML
        // This method can be used for additional event handling if needed
    }

    editTodo(id) {
        const todo = this.todos.find(t => t.id === id);
        if (!todo) return;

        this.currentEditId = id;
        
        // Populate edit form
        document.getElementById('editId').value = todo.id;
        document.getElementById('editDescription').value = todo.description || '';
        document.getElementById('editStartDate').value = todo.startDate || '';
        document.getElementById('editEndDate').value = todo.endDate || '';
        document.getElementById('editPriority').value = todo.priority || '';
        document.getElementById('editCollaborators').value = todo.collaborators || '';
        document.getElementById('editComments').value = todo.comments || '';

        // Show modal
        const modal = new bootstrap.Modal(document.getElementById('editModal'));
        modal.show();
    }

    async saveEdit() {
        if (!this.currentEditId) return;

        const editData = {
            description: document.getElementById('editDescription').value,
            startDate: document.getElementById('editStartDate').value || null,
            endDate: document.getElementById('editEndDate').value || null,
            priority: document.getElementById('editPriority').value || null,
            collaborators: document.getElementById('editCollaborators').value || null,
            comments: document.getElementById('editComments').value || null
        };

        const updatedTodo = await this.updateTodo(this.currentEditId, editData);
        if (updatedTodo) {
            this.showSuccess('Todo updated successfully!');
            const modal = bootstrap.Modal.getInstance(document.getElementById('editModal'));
            modal.hide();
        }
    }

    updateStatistics() {
        const total = this.todos.length;
        const completed = this.todos.filter(todo => todo.completed).length;
        const pending = total - completed;
        const overdue = this.todos.filter(todo => 
            todo.endDate && new Date(todo.endDate) < new Date() && !todo.completed
        ).length;

        document.getElementById('totalTodos').textContent = total;
        document.getElementById('completedTodos').textContent = completed;
        document.getElementById('pendingTodos').textContent = pending;
        document.getElementById('overdueTodos').textContent = overdue;
    }

    getFormData() {
        return {
            description: document.getElementById('description').value,
            startDate: document.getElementById('startDate').value || null,
            endDate: document.getElementById('endDate').value || null,
            priority: document.getElementById('priority').value || null,
            collaborators: document.getElementById('collaborators').value || null,
            comments: document.getElementById('comments').value || null
        };
    }

    clearForm() {
        document.getElementById('todoForm').reset();
    }

    showSuccess(message) {
        document.getElementById('successMessage').textContent = message;
        const toast = new bootstrap.Toast(document.getElementById('successToast'));
        toast.show();
    }

    showError(message) {
        document.getElementById('errorMessage').textContent = message;
        const toast = new bootstrap.Toast(document.getElementById('errorToast'));
        toast.show();
    }

    showLoading() {
        // You can implement a loading spinner here
        console.log('Loading...');
    }

    hideLoading() {
        // Hide loading spinner
        console.log('Loading complete');
    }

    escapeHtml(text) {
        const div = document.createElement('div');
        div.textContent = text;
        return div.innerHTML;
    }
}

// Initialize the app when DOM is loaded
document.addEventListener('DOMContentLoaded', () => {
    window.todoApp = new TodoApp();
});
