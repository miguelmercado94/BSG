package com.bsg.docviz.presentation.controller;

import com.bsg.docviz.dto.TagToolRefDto;
import com.bsg.docviz.service.TagToolRegistry;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;
import java.util.Map;

@RestController
public class TagsController {

    private final TagToolRegistry tagToolRegistry;

    public TagsController(TagToolRegistry tagToolRegistry) {
        this.tagToolRegistry = tagToolRegistry;
    }

    /**
     * Lista de tags reconocidos + URLs de referencia por tag (para UI y alineación con el bloque @tools en RAG).
     */
    @GetMapping("/tags")
    public ResponseEntity<Map<String, Object>> getTags() {
        List<String> tags = tagToolRegistry.allTagNames();
        Map<String, List<TagToolRefDto>> toolsByTag = tagToolRegistry.toolsByTagMap();
        return ResponseEntity.ok(Map.of("tags", tags, "toolsByTag", toolsByTag));
    }
}
