package com.example.todoapp.service;

import com.example.todoapp.dto.TodoCreateRequest;
import com.example.todoapp.dto.TodoUpdateRequest;
import com.example.todoapp.entity.Todo;
import com.example.todoapp.repository.TodoRepository;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.domain.Specification;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import javax.persistence.EntityNotFoundException;
import javax.persistence.OptimisticLockException;
import java.time.LocalDate;
import java.util.List;

@Service
@Transactional(readOnly = true)
public class TodoServiceModern {
    
    private static final Logger logger = LoggerFactory.getLogger(TodoServiceModern.class);
    
    private final TodoRepository todoRepository;
    
    public TodoServiceModern(TodoRepository todoRepository) {
        this.todoRepository = todoRepository;
    }
    
    @Transactional
    public Todo createTodo(TodoCreateRequest request) {
        logger.debug("Creating new todo with description: {}", request.getDescription());
        
        Todo todo = request.toEntity();
        Todo savedTodo = todoRepository.save(todo);
        
        logger.info("Created todo with ID: {}", savedTodo.getId());
        return savedTodo;
    }
    
    public Page<Todo> getAllTodos(String search, String filter, String sort, Pageable pageable) {
        logger.debug("Fetching todos with search: {}, filter: {}, sort: {}", search, filter, sort);
        
        Specification<Todo> spec = buildSpecification(search, filter);
        return todoRepository.findAll(spec, pageable);
    }
    
    public Todo getTodoById(Long id) {
        logger.debug("Fetching todo with ID: {}", id);
        
        return todoRepository.findById(id)
            .orElseThrow(() -> new EntityNotFoundException("Todo not found with ID: " + id));
    }
    
    @Transactional
    public Todo updateTodo(Long id, TodoUpdateRequest request) {
        logger.debug("Updating todo with ID: {}", id);
        
        Todo existingTodo = getTodoById(id);
        
        // Update fields if provided
        if (request.getDescription() != null) {
            existingTodo.setDescription(request.getDescription());
        }
        if (request.getStartDate() != null) {
            existingTodo.setStartDate(request.getStartDate());
        }
        if (request.getEndDate() != null) {
            existingTodo.setEndDate(request.getEndDate());
        }
        if (request.getPriority() != null) {
            existingTodo.setPriority(request.getPriority());
        }
        if (request.getComments() != null) {
            existingTodo.setComments(request.getComments());
        }
        if (request.getCollaborators() != null) {
            existingTodo.setCollaborators(request.getCollaborators());
        }
        if (request.getCompleted() != null) {
            existingTodo.setCompleted(request.getCompleted());
        }
        
        Todo updatedTodo = todoRepository.save(existingTodo);
        logger.info("Updated todo with ID: {}", updatedTodo.getId());
        
        return updatedTodo;
    }
    
    @Transactional
    public void deleteTodo(Long id) {
        logger.debug("Deleting todo with ID: {}", id);
        
        if (!todoRepository.existsById(id)) {
            throw new EntityNotFoundException("Todo not found with ID: " + id);
        }
        
        todoRepository.deleteById(id);
        logger.info("Deleted todo with ID: {}", id);
    }
    
    @Transactional
    public Todo toggleTodoCompletion(Long id) {
        logger.debug("Toggling completion for todo with ID: {}", id);
        
        Todo todo = getTodoById(id);
        todo.setCompleted(!todo.getCompleted());
        
        Todo updatedTodo = todoRepository.save(todo);
        logger.info("Toggled completion for todo with ID: {} to {}", id, updatedTodo.getCompleted());
        
        return updatedTodo;
    }
    
    public List<Todo> getTodosByPriority(Todo.Priority priority) {
        logger.debug("Fetching todos with priority: {}", priority);
        return todoRepository.findByPriority(priority);
    }
    
    public List<Todo> getTodosByDateRange(LocalDate startDate, LocalDate endDate) {
        logger.debug("Fetching todos between {} and {}", startDate, endDate);
        return todoRepository.findByDateRange(startDate, endDate);
    }
    
    public List<Todo> getOverdueTodos() {
        logger.debug("Fetching overdue todos");
        return todoRepository.findOverdueTodos();
    }
    
    public List<Todo> getTodosDueToday() {
        logger.debug("Fetching todos due today");
        return todoRepository.findTodosDueToday();
    }
    
    public List<Todo> getTodosByCollaborator(String collaborator) {
        logger.debug("Fetching todos for collaborator: {}", collaborator);
        return todoRepository.findByCollaboratorsContainingIgnoreCase(collaborator);
    }
    
    private Specification<Todo> buildSpecification(String search, String filter) {
        Specification<Todo> spec = Specification.where(null);
        
        if (search != null && !search.trim().isEmpty()) {
            spec = spec.and((root, query, cb) -> 
                cb.like(cb.lower(root.get("description")), "%" + search.toLowerCase() + "%"));
        }
        
        if (filter != null) {
            String filterLower = filter.toLowerCase();
            if ("completed".equals(filterLower)) {
                spec = spec.and((root, query, cb) -> cb.isTrue(root.get("completed")));
            } else if ("pending".equals(filterLower)) {
                spec = spec.and((root, query, cb) -> cb.isFalse(root.get("completed")));
            } else if ("overdue".equals(filterLower)) {
                spec = spec.and((root, query, cb) -> cb.and(
                    cb.lessThan(root.get("endDate"), LocalDate.now()),
                    cb.isFalse(root.get("completed"))
                ));
            } else if ("due-today".equals(filterLower)) {
                spec = spec.and((root, query, cb) -> 
                    cb.equal(root.get("endDate"), LocalDate.now()));
            } else if ("high-priority".equals(filterLower)) {
                spec = spec.and((root, query, cb) -> 
                    cb.equal(root.get("priority"), Todo.Priority.HIGH));
            } else if ("urgent".equals(filterLower)) {
                spec = spec.and((root, query, cb) -> 
                    cb.equal(root.get("priority"), Todo.Priority.URGENT));
            }
        }
        
        return spec;
    }
}
