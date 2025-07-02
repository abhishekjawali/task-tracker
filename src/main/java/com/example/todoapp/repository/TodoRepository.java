package com.example.todoapp.repository;

import com.example.todoapp.entity.Todo;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.JpaSpecificationExecutor;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.time.LocalDate;
import java.util.List;

@Repository
public interface TodoRepository extends JpaRepository<Todo, Long>, JpaSpecificationExecutor<Todo> {
    
    // Find todos by completion status
    List<Todo> findByCompleted(Boolean completed);
    
    // Find todos by priority
    List<Todo> findByPriority(Todo.Priority priority);
    
    // Find todos by date range
    @Query("SELECT t FROM Todo t WHERE t.startDate >= :startDate AND t.endDate <= :endDate")
    List<Todo> findByDateRange(@Param("startDate") LocalDate startDate, @Param("endDate") LocalDate endDate);
    
    // Find todos containing specific text in description
    List<Todo> findByDescriptionContainingIgnoreCase(String description);
    
    // Find todos by collaborator
    List<Todo> findByCollaboratorsContainingIgnoreCase(String collaborator);
    
    // Find overdue todos
    @Query("SELECT t FROM Todo t WHERE t.endDate < CURRENT_DATE AND t.completed = false")
    List<Todo> findOverdueTodos();
    
    // Find todos due today
    @Query("SELECT t FROM Todo t WHERE t.endDate = CURRENT_DATE")
    List<Todo> findTodosDueToday();
    
    // Find todos ordered by priority and end date
    @Query("SELECT t FROM Todo t ORDER BY " +
           "CASE t.priority " +
           "WHEN 'URGENT' THEN 1 " +
           "WHEN 'HIGH' THEN 2 " +
           "WHEN 'MEDIUM' THEN 3 " +
           "WHEN 'LOW' THEN 4 " +
           "ELSE 5 END, " +
           "t.endDate ASC NULLS LAST")
    List<Todo> findAllOrderedByPriorityAndDate();
}
