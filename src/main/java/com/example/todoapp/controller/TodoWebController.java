package com.example.todoapp.controller;

import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.GetMapping;

@Controller
public class TodoWebController {
    
    @GetMapping("/")
    public String index() {
        return "index";
    }
    
    @GetMapping("/todos")
    public String todos() {
        return "index";
    }

    // create /health controller
    @GetMapping("/actuator/health")
    public String health() {
        return "index";
    }
}
