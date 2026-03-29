package com.bsg.docviz.web;

import com.bsg.docviz.dto.FileContentResponse;
import com.bsg.docviz.service.FileExplorerService;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

@RestController
public class FilesController {

    private final FileExplorerService fileExplorerService;

    public FilesController(FileExplorerService fileExplorerService) {
        this.fileExplorerService = fileExplorerService;
    }

    @GetMapping("/files/content")
    public ResponseEntity<FileContentResponse> content(@RequestParam("query") String query) {
        return ResponseEntity.ok(fileExplorerService.readFile(query));
    }
}
