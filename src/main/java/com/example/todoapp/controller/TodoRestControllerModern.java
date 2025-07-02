package com.example.todoapp.controller;

import com.example.todoapp.dto.TodoCreateRequest;
import com.example.todoapp.dto.TodoResponse;
import com.example.todoapp.dto.TodoUpdateRequest;
import com.example.todoapp.entity.Todo;
import com.example.todoapp.service.TodoServiceModern;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.web.PageableDefault;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.*;

import javax.validation.Valid;
import javax.validation.constraints.Min;
import java.time.LocalDate;
import java.util.List;
import java.util.stream.Collectors;

@RestController
@RequestMapping("/api/v1/todos")
@CrossOrigin(origins = "*")
@Validated
public class TodoRestControllerModern {
    
    private final TodoServiceModern todoService;
    
    public TodoRestControllerModern(TodoServiceModern todoService) {
        this.todoService = todoService;
    }
    
    @PostMapping
    public ResponseEntity<TodoResponse> createTodo(@Valid @RequestBody TodoCreateRequest request) {
        Todo todo = todoService.createTodo(request);
        return ResponseEntity.status(HttpStatus.CREATED).body(TodoResponse.from(todo));
    }
    
    @GetMapping
    public ResponseEntity<Page<TodoResponse>> getAllTodos(
            @RequestParam(required = false) String search,
            @RequestParam(required = false) String filter,
            @RequestParam(required = false) String sort,
            @PageableDefault(size = 20) Pageable pageable) {
        
        Page<Todo> todos = todoService.getAllTodos(search, filter, sort, pageable);
        Page<TodoResponse> response = todos.map(TodoResponse::from);
        return ResponseEntity.ok(response);
    }
    
    @GetMapping("/{id}")
    public ResponseEntity<TodoResponse> getTodoById(@PathVariable @Min(1) Long id) {
        Todo todo = todoService.getTodoById(id);
        return ResponseEntity.ok(TodoResponse.from(todo));
    }
    
    @PutMapping("/{id}")
    public ResponseEntity<TodoResponse> updateTodo(
            @PathVariable @Min(1) Long id,
            @Valid @RequestBody TodoUpdateRequest request) {
        Todo todo = todoService.updateTodo(id, request);
        return ResponseEntity.ok(TodoResponse.from(todo));
    }
    
    @DeleteMapping("/{id}")
    public ResponseEntity<Void> deleteTodo(@PathVariable @Min(1) Long id) {
        todoService.deleteTodo(id);
        return ResponseEntity.noContent().build();
    }
    
    @PatchMapping("/{id}/toggle")
    public ResponseEntity<TodoResponse> toggleTodoCompletion(@PathVariable @Min(1) Long id) {
        Todo todo = todoService.toggleTodoCompletion(id);
        return ResponseEntity.ok(TodoResponse.from(todo));
    }
    
    @GetMapping("/priority/{priority}")
    public ResponseEntity<List<TodoResponse>> getTodosByPriority(@PathVariable Todo.Priority priority) {
        List<Todo> todos = todoService.getTodosByPriority(priority);
        List<TodoResponse> response = todos.stream()
            .map(TodoResponse::from)
            .collect(Collectors.toList());
        return ResponseEntity.ok(response);
    }
    
    @GetMapping("/date-range")
    public ResponseEntity<List<TodoResponse>> getTodosByDateRange(
            @RequestParam LocalDate startDate,
            @RequestParam LocalDate endDate) {
        List<Todo> todos = todoService.getTodosByDateRange(startDate, endDate);
        List<TodoResponse> response = todos.stream()
            .map(TodoResponse::from)
            .collect(Collectors.toList());
        return ResponseEntity.ok(response);
    }
    
    @GetMapping("/overdue")
    public ResponseEntity<List<TodoResponse>> getOverdueTodos() {
        List<Todo> todos = todoService.getOverdueTodos();
        List<TodoResponse> response = todos.stream()
            .map(TodoResponse::from)
            .collect(Collectors.toList());
        return ResponseEntity.ok(response);
    }
    
    @GetMapping("/due-today")
    public ResponseEntity<List<TodoResponse>> getTodosDueToday() {
        List<Todo> todos = todoService.getTodosDueToday();
        List<TodoResponse> response = todos.stream()
            .map(TodoResponse::from)
            .collect(Collectors.toList());
        return ResponseEntity.ok(response);
    }
}
