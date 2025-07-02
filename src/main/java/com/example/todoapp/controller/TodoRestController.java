package com.example.todoapp.controller;

import com.example.todoapp.entity.Todo;
import com.example.todoapp.service.TodoService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDate;
import java.util.List;
import java.util.Optional;

@RestController
@RequestMapping("/api/todos")
@CrossOrigin(origins = "*")
public class TodoRestController {
    
    @Autowired
    private TodoService todoService;
    
    // Create a new todo
    @PostMapping
    public ResponseEntity<Todo> createTodo(@RequestBody Todo todo) {
        try {
            Todo createdTodo = todoService.createTodo(todo);
            return new ResponseEntity<>(createdTodo, HttpStatus.CREATED);
        } catch (Exception e) {
            return new ResponseEntity<>(null, HttpStatus.INTERNAL_SERVER_ERROR);
        }
    }
    
    // Get all todos
    @GetMapping
    public ResponseEntity<List<Todo>> getAllTodos(
            @RequestParam(required = false) String sort,
            @RequestParam(required = false) String filter,
            @RequestParam(required = false) String search) {
        try {
            List<Todo> todos;
            
            if (search != null && !search.isEmpty()) {
                todos = todoService.searchTodosByDescription(search);
            } else if (filter != null) {
                switch (filter.toLowerCase()) {
                    case "completed":
                        todos = todoService.getTodosByStatus(true);
                        break;
                    case "pending":
                        todos = todoService.getTodosByStatus(false);
                        break;
                    case "overdue":
                        todos = todoService.getOverdueTodos();
                        break;
                    case "due-today":
                        todos = todoService.getTodosDueToday();
                        break;
                    case "high-priority":
                        todos = todoService.getTodosByPriority(Todo.Priority.HIGH);
                        break;
                    case "urgent":
                        todos = todoService.getTodosByPriority(Todo.Priority.URGENT);
                        break;
                    default:
                        todos = todoService.getAllTodos();
                }
            } else if ("priority".equals(sort)) {
                todos = todoService.getAllTodosOrdered();
            } else {
                todos = todoService.getAllTodos();
            }
            
            return new ResponseEntity<>(todos, HttpStatus.OK);
        } catch (Exception e) {
            return new ResponseEntity<>(null, HttpStatus.INTERNAL_SERVER_ERROR);
        }
    }
    
    // Get todo by ID
    @GetMapping("/{id}")
    public ResponseEntity<Todo> getTodoById(@PathVariable Long id) {
        Optional<Todo> todo = todoService.getTodoById(id);
        if (todo.isPresent()) {
            return new ResponseEntity<>(todo.get(), HttpStatus.OK);
        } else {
            return new ResponseEntity<>(HttpStatus.NOT_FOUND);
        }
    }
    
    // Update todo
    @PutMapping("/{id}")
    public ResponseEntity<Todo> updateTodo(@PathVariable Long id, @RequestBody Todo todoDetails) {
        try {
            Todo updatedTodo = todoService.updateTodo(id, todoDetails);
            if (updatedTodo != null) {
                return new ResponseEntity<>(updatedTodo, HttpStatus.OK);
            } else {
                return new ResponseEntity<>(HttpStatus.NOT_FOUND);
            }
        } catch (Exception e) {
            return new ResponseEntity<>(null, HttpStatus.INTERNAL_SERVER_ERROR);
        }
    }
    
    // Delete todo
    @DeleteMapping("/{id}")
    public ResponseEntity<HttpStatus> deleteTodo(@PathVariable Long id) {
        try {
            boolean deleted = todoService.deleteTodo(id);
            if (deleted) {
                return new ResponseEntity<>(HttpStatus.NO_CONTENT);
            } else {
                return new ResponseEntity<>(HttpStatus.NOT_FOUND);
            }
        } catch (Exception e) {
            return new ResponseEntity<>(HttpStatus.INTERNAL_SERVER_ERROR);
        }
    }
    
    // Toggle todo completion
    @PatchMapping("/{id}/toggle")
    public ResponseEntity<Todo> toggleTodoCompletion(@PathVariable Long id) {
        try {
            Todo updatedTodo = todoService.toggleTodoCompletion(id);
            if (updatedTodo != null) {
                return new ResponseEntity<>(updatedTodo, HttpStatus.OK);
            } else {
                return new ResponseEntity<>(HttpStatus.NOT_FOUND);
            }
        } catch (Exception e) {
            return new ResponseEntity<>(null, HttpStatus.INTERNAL_SERVER_ERROR);
        }
    }
    
    // Get todos by priority
    @GetMapping("/priority/{priority}")
    public ResponseEntity<List<Todo>> getTodosByPriority(@PathVariable String priority) {
        try {
            Todo.Priority priorityEnum = Todo.Priority.valueOf(priority.toUpperCase());
            List<Todo> todos = todoService.getTodosByPriority(priorityEnum);
            return new ResponseEntity<>(todos, HttpStatus.OK);
        } catch (IllegalArgumentException e) {
            return new ResponseEntity<>(HttpStatus.BAD_REQUEST);
        } catch (Exception e) {
            return new ResponseEntity<>(null, HttpStatus.INTERNAL_SERVER_ERROR);
        }
    }
    
    // Get todos by collaborator
    @GetMapping("/collaborator/{collaborator}")
    public ResponseEntity<List<Todo>> getTodosByCollaborator(@PathVariable String collaborator) {
        try {
            List<Todo> todos = todoService.getTodosByCollaborator(collaborator);
            return new ResponseEntity<>(todos, HttpStatus.OK);
        } catch (Exception e) {
            return new ResponseEntity<>(null, HttpStatus.INTERNAL_SERVER_ERROR);
        }
    }
    
    // Get todos by date range
    @GetMapping("/date-range")
    public ResponseEntity<List<Todo>> getTodosByDateRange(
            @RequestParam String startDate,
            @RequestParam String endDate) {
        try {
            LocalDate start = LocalDate.parse(startDate);
            LocalDate end = LocalDate.parse(endDate);
            List<Todo> todos = todoService.getTodosByDateRange(start, end);
            return new ResponseEntity<>(todos, HttpStatus.OK);
        } catch (Exception e) {
            return new ResponseEntity<>(null, HttpStatus.INTERNAL_SERVER_ERROR);
        }
    }

    // // create /health controller
    // @GetMapping("/actuator/health")
    // public ResponseEntity<String> health() {
    //     return new ResponseEntity<>("OK", HttpStatus.OK);
    // }
}
