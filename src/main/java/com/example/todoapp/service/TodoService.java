package com.example.todoapp.service;

import com.example.todoapp.entity.Todo;
import com.example.todoapp.repository.TodoRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.time.LocalDate;
import java.util.List;
import java.util.Optional;

@Service
public class TodoService {
    
    @Autowired
    private TodoRepository todoRepository;
    
    // Create a new todo
    public Todo createTodo(Todo todo) {
        return todoRepository.save(todo);
    }
    
    // Get all todos
    public List<Todo> getAllTodos() {
        return todoRepository.findAll();
    }
    
    // Get todos ordered by priority and date
    public List<Todo> getAllTodosOrdered() {
        return todoRepository.findAllOrderedByPriorityAndDate();
    }
    
    // Get todo by ID
    public Optional<Todo> getTodoById(Long id) {
        return todoRepository.findById(id);
    }
    
    // Update todo
    public Todo updateTodo(Long id, Todo todoDetails) {
        Optional<Todo> optionalTodo = todoRepository.findById(id);
        if (optionalTodo.isPresent()) {
            Todo todo = optionalTodo.get();
            
            if (todoDetails.getDescription() != null) {
                todo.setDescription(todoDetails.getDescription());
            }
            if (todoDetails.getStartDate() != null) {
                todo.setStartDate(todoDetails.getStartDate());
            }
            if (todoDetails.getEndDate() != null) {
                todo.setEndDate(todoDetails.getEndDate());
            }
            if (todoDetails.getPriority() != null) {
                todo.setPriority(todoDetails.getPriority());
            }
            if (todoDetails.getComments() != null) {
                todo.setComments(todoDetails.getComments());
            }
            if (todoDetails.getCollaborators() != null) {
                todo.setCollaborators(todoDetails.getCollaborators());
            }
            if (todoDetails.getCompleted() != null) {
                todo.setCompleted(todoDetails.getCompleted());
            }
            
            return todoRepository.save(todo);
        }
        return null;
    }
    
    // Delete todo
    public boolean deleteTodo(Long id) {
        if (todoRepository.existsById(id)) {
            todoRepository.deleteById(id);
            return true;
        }
        return false;
    }
    
    // Get todos by completion status
    public List<Todo> getTodosByStatus(Boolean completed) {
        return todoRepository.findByCompleted(completed);
    }
    
    // Get todos by priority
    public List<Todo> getTodosByPriority(Todo.Priority priority) {
        return todoRepository.findByPriority(priority);
    }
    
    // Search todos by description
    public List<Todo> searchTodosByDescription(String description) {
        return todoRepository.findByDescriptionContainingIgnoreCase(description);
    }
    
    // Get todos by collaborator
    public List<Todo> getTodosByCollaborator(String collaborator) {
        return todoRepository.findByCollaboratorsContainingIgnoreCase(collaborator);
    }
    
    // Get overdue todos
    public List<Todo> getOverdueTodos() {
        return todoRepository.findOverdueTodos();
    }
    
    // Get todos due today
    public List<Todo> getTodosDueToday() {
        return todoRepository.findTodosDueToday();
    }
    
    // Get todos by date range
    public List<Todo> getTodosByDateRange(LocalDate startDate, LocalDate endDate) {
        return todoRepository.findByDateRange(startDate, endDate);
    }
    
    // Toggle todo completion status
    public Todo toggleTodoCompletion(Long id) {
        Optional<Todo> optionalTodo = todoRepository.findById(id);
        if (optionalTodo.isPresent()) {
            Todo todo = optionalTodo.get();
            todo.setCompleted(!todo.getCompleted());
            return todoRepository.save(todo);
        }
        return null;
    }
}
