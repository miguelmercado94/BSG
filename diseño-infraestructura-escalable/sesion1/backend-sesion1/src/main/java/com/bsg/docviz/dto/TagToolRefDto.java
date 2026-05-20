package com.bsg.docviz.dto;

/** URL de referencia asociada a un tag de repositorio (simula @tools / orientación al LLM). */
public record TagToolRefDto(String id, String title, String url, String hint) {}
