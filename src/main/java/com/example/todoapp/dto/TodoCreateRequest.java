package com.example.todoapp.dto;

import com.example.todoapp.entity.Todo;
import com.fasterxml.jackson.annotation.JsonFormat;

import javax.validation.constraints.NotBlank;
import javax.validation.constraints.Size;
import java.time.LocalDate;

public class TodoCreateRequest {
    
    @NotBlank(message = "Description is required")
    @Size(max = 1000, message = "Description must not exceed 1000 characters")
    private String description;
    
    @JsonFormat(pattern = "yyyy-MM-dd")
    private LocalDate startDate;
    
    @JsonFormat(pattern = "yyyy-MM-dd")
    private LocalDate endDate;
    
    private Todo.Priority priority;
    
    @Size(max = 2000, message = "Comments must not exceed 2000 characters")
    private String comments;
    
    @Size(max = 500, message = "Collaborators must not exceed 500 characters")
    private String collaborators;
    
    // Default constructor
    public TodoCreateRequest() {}
    
    // Constructor with all fields
    public TodoCreateRequest(String description, LocalDate startDate, LocalDate endDate, 
                           Todo.Priority priority, String comments, String collaborators) {
        this.description = description;
        this.startDate = startDate;
        this.endDate = endDate;
        this.priority = priority;
        this.comments = comments;
        this.collaborators = collaborators;
    }
    
    // Getters and Setters
    public String getDescription() {
        return description;
    }
    
    public void setDescription(String description) {
        this.description = description;
    }
    
    public LocalDate getStartDate() {
        return startDate;
    }
    
    public void setStartDate(LocalDate startDate) {
        this.startDate = startDate;
    }
    
    public LocalDate getEndDate() {
        return endDate;
    }
    
    public void setEndDate(LocalDate endDate) {
        this.endDate = endDate;
    }
    
    public Todo.Priority getPriority() {
        return priority;
    }
    
    public void setPriority(Todo.Priority priority) {
        this.priority = priority;
    }
    
    public String getComments() {
        return comments;
    }
    
    public void setComments(String comments) {
        this.comments = comments;
    }
    
    public String getCollaborators() {
        return collaborators;
    }
    
    public void setCollaborators(String collaborators) {
        this.collaborators = collaborators;
    }
    
    // Convert to entity
    public Todo toEntity() {
        Todo todo = new Todo();
        todo.setDescription(description);
        todo.setStartDate(startDate);
        todo.setEndDate(endDate);
        todo.setPriority(priority);
        todo.setComments(comments);
        todo.setCollaborators(collaborators);
        todo.setCompleted(false);
        return todo;
    }
}
