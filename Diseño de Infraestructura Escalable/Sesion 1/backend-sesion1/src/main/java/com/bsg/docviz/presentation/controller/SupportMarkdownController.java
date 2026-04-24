package com.bsg.docviz.presentation.controller;

import com.bsg.docviz.dto.S3FileUrlItem;
import com.bsg.docviz.dto.SupportMarkdownUploadResponse;
import com.bsg.docviz.support.SupportMarkdownService;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.http.MediaType;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.multipart.MultipartFile;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/support")
@ConditionalOnProperty(name = "docviz.support.enabled", havingValue = "true")
public class SupportMarkdownController {

    private final SupportMarkdownService supportMarkdownService;

    public SupportMarkdownController(SupportMarkdownService supportMarkdownService) {
        this.supportMarkdownService = supportMarkdownService;
    }

    /**
     * Lista objetos .md con URL presignada GET (el front descarga directo desde S3).
     */
    @GetMapping("/markdown/objects")
    public List<S3FileUrlItem> listObjects(@RequestParam("cellRepoId") long cellRepoId) {
        return supportMarkdownService.listObjectsForCellRepo(cellRepoId);
    }

    /**
     * Sube un .md a S3 y genera embeddings en pgvector en el namespace del repositorio conectado.
     */
    @PostMapping(value = "/markdown", consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    public SupportMarkdownUploadResponse upload(@RequestParam("file") MultipartFile file) {
        return supportMarkdownService.uploadAndIndex(file);
    }

    @DeleteMapping("/markdown")
    public Map<String, Object> delete(@RequestParam("fileName") String fileName) {
        supportMarkdownService.deleteIndexed(fileName);
        return Map.of("deleted", Boolean.TRUE, "fileName", fileName);
    }
}
