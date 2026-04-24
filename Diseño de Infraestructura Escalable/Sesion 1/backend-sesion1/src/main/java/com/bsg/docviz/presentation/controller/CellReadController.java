package com.bsg.docviz.presentation.controller;

import com.bsg.docviz.dto.CellRepoResponse;
import com.bsg.docviz.dto.CellResponse;
import com.bsg.docviz.service.DomainCellService;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

@RestController
@RequestMapping("/cells")
public class CellReadController {

    private final DomainCellService domainCellService;

    public CellReadController(DomainCellService domainCellService) {
        this.domainCellService = domainCellService;
    }

    @GetMapping
    public List<CellResponse> list() {
        return domainCellService.listCells();
    }

    @GetMapping("/{cellId}/repos")
    public List<CellRepoResponse> listRepos(@PathVariable long cellId) {
        return domainCellService.listRepos(cellId);
    }
}
