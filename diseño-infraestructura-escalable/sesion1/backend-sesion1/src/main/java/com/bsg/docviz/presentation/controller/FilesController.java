package com.bsg.docviz.presentation.controller;

import com.bsg.docviz.dto.FileContentResponse;
import com.bsg.docviz.application.port.output.FileExplorerPort;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

@RestController
public class FilesController {

    private final FileExplorerPort fileExplorerService;

    public FilesController(FileExplorerPort fileExplorerService) {
        this.fileExplorerService = fileExplorerService;
    }

    @GetMapping("/files/content")
    public ResponseEntity<FileContentResponse> content(@RequestParam("query") String query) {
        return ResponseEntity.ok(fileExplorerService.readFile(query));
    }
}
