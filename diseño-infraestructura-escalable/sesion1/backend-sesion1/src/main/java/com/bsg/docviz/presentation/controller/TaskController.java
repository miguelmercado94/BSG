package com.bsg.docviz.presentation.controller;

import com.bsg.docviz.dto.TaskContinueRequest;
import com.bsg.docviz.dto.TaskContinueResponse;
import com.bsg.docviz.dto.TaskCreateRequest;
import com.bsg.docviz.dto.TaskResponse;
import com.bsg.docviz.service.DomainTaskService;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

@RestController
@RequestMapping("/tasks")
public class TaskController {

    private final DomainTaskService domainTaskService;

    public TaskController(DomainTaskService domainTaskService) {
        this.domainTaskService = domainTaskService;
    }

    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    public TaskResponse create(@Valid @RequestBody TaskCreateRequest body) {
        return domainTaskService.create(body);
    }

    @GetMapping
    public List<TaskResponse> list(@RequestParam(required = false) Long cellId) {
        if (cellId != null) {
            return domainTaskService.listForCell(cellId);
        }
        return domainTaskService.listMineOrAll();
    }

    @GetMapping("/{id}")
    public TaskResponse get(@PathVariable long id) {
        return domainTaskService.get(id);
    }

    @PostMapping("/continue")
    public TaskContinueResponse continueTask(@Valid @RequestBody TaskContinueRequest body) {
        return domainTaskService.continueTask(body.taskId());
    }
}
