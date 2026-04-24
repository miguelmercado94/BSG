package com.bsg.docviz.presentation.controller;

import com.bsg.docviz.service.MockTagsRepository;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.Map;

@RestController
public class TagsController {

    private final MockTagsRepository mockTagsRepository;

    public TagsController(MockTagsRepository mockTagsRepository) {
        this.mockTagsRepository = mockTagsRepository;
    }

    @GetMapping("/tags")
    public ResponseEntity<Map<String, Object>> getTags() {
        return ResponseEntity.ok(Map.of("tags", mockTagsRepository.findAllTags()));
    }
}
