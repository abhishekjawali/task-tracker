package com.example.todoapp.dto;

import com.example.todoapp.entity.Todo;
import com.fasterxml.jackson.annotation.JsonFormat;

import javax.validation.constraints.NotNull;
import javax.validation.constraints.Size;
import java.time.LocalDate;

public class TodoUpdateRequest {
    
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
    
    private Boolean completed;
    
    @NotNull(message = "Version is required for optimistic locking")
    private Long version;
    
    // Default constructor
    public TodoUpdateRequest() {}
    
    // Constructor with all fields
    public TodoUpdateRequest(String description, LocalDate startDate, LocalDate endDate,
                           Todo.Priority priority, String comments, String collaborators,
                           Boolean completed, Long version) {
        this.description = description;
        this.startDate = startDate;
        this.endDate = endDate;
        this.priority = priority;
        this.comments = comments;
        this.collaborators = collaborators;
        this.completed = completed;
        this.version = version;
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
    
    public Boolean getCompleted() {
        return completed;
    }
    
    public void setCompleted(Boolean completed) {
        this.completed = completed;
    }
    
    public Long getVersion() {
        return version;
    }
    
    public void setVersion(Long version) {
        this.version = version;
    }
}
