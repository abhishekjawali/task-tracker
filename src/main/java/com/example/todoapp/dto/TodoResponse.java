package com.example.todoapp.dto;

import com.example.todoapp.entity.Todo;
import com.fasterxml.jackson.annotation.JsonFormat;

import java.time.LocalDate;
import java.time.LocalDateTime;

public class TodoResponse {
    
    private Long id;
    private String description;
    
    @JsonFormat(pattern = "yyyy-MM-dd")
    private LocalDate startDate;
    
    @JsonFormat(pattern = "yyyy-MM-dd") 
    private LocalDate endDate;
    
    private Todo.Priority priority;
    private String comments;
    private String collaborators;
    private Boolean completed;
    
    @JsonFormat(pattern = "yyyy-MM-dd'T'HH:mm:ss")
    private LocalDateTime createdAt;
    
    @JsonFormat(pattern = "yyyy-MM-dd'T'HH:mm:ss")
    private LocalDateTime updatedAt;
    
    // Computed fields
    private Boolean isOverdue;
    private Boolean isDueToday;
    private Boolean isDueSoon;
    
    // Default constructor
    public TodoResponse() {}
    
    // Constructor with all fields
    public TodoResponse(Long id, String description, LocalDate startDate, LocalDate endDate,
                       Todo.Priority priority, String comments, String collaborators,
                       Boolean completed, LocalDateTime createdAt, LocalDateTime updatedAt,
                       Boolean isOverdue, Boolean isDueToday, Boolean isDueSoon) {
        this.id = id;
        this.description = description;
        this.startDate = startDate;
        this.endDate = endDate;
        this.priority = priority;
        this.comments = comments;
        this.collaborators = collaborators;
        this.completed = completed;
        this.createdAt = createdAt;
        this.updatedAt = updatedAt;
        this.isOverdue = isOverdue;
        this.isDueToday = isDueToday;
        this.isDueSoon = isDueSoon;
    }
    
    // Static factory method
    public static TodoResponse from(Todo todo) {
        return new TodoResponse(
            todo.getId(),
            todo.getDescription(),
            todo.getStartDate(),
            todo.getEndDate(),
            todo.getPriority(),
            todo.getComments(),
            todo.getCollaborators(),
            todo.getCompleted(),
            todo.getCreatedAt(),
            todo.getUpdatedAt(),
            isOverdue(todo),
            isDueToday(todo),
            isDueSoon(todo, 3) // Due within 3 days
        );
    }
    
    // Helper methods for computed fields
    private static Boolean isOverdue(Todo todo) {
        return todo.getEndDate() != null && 
               todo.getEndDate().isBefore(LocalDate.now()) && 
               !todo.getCompleted();
    }
    
    private static Boolean isDueToday(Todo todo) {
        return todo.getEndDate() != null && 
               todo.getEndDate().equals(LocalDate.now());
    }
    
    private static Boolean isDueSoon(Todo todo, int days) {
        return todo.getEndDate() != null && 
               todo.getEndDate().isBefore(LocalDate.now().plusDays(days + 1)) && 
               !todo.getCompleted();
    }
    
    // Getters and Setters
    public Long getId() {
        return id;
    }
    
    public void setId(Long id) {
        this.id = id;
    }
    
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
    
    public LocalDateTime getCreatedAt() {
        return createdAt;
    }
    
    public void setCreatedAt(LocalDateTime createdAt) {
        this.createdAt = createdAt;
    }
    
    public LocalDateTime getUpdatedAt() {
        return updatedAt;
    }
    
    public void setUpdatedAt(LocalDateTime updatedAt) {
        this.updatedAt = updatedAt;
    }
    
    public Boolean getIsOverdue() {
        return isOverdue;
    }
    
    public void setIsOverdue(Boolean isOverdue) {
        this.isOverdue = isOverdue;
    }
    
    public Boolean getIsDueToday() {
        return isDueToday;
    }
    
    public void setIsDueToday(Boolean isDueToday) {
        this.isDueToday = isDueToday;
    }
    
    public Boolean getIsDueSoon() {
        return isDueSoon;
    }
    
    public void setIsDueSoon(Boolean isDueSoon) {
        this.isDueSoon = isDueSoon;
    }
}
