package com.bsg.docviz.presentation.controller;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.HttpRequestMethodNotSupportedException;
import org.springframework.web.bind.MethodArgumentNotValidException;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;
import org.springframework.web.context.request.async.AsyncRequestTimeoutException;
import org.springframework.web.multipart.MaxUploadSizeExceededException;
import org.springframework.web.server.ResponseStatusException;

import java.util.Map;

@RestControllerAdvice
public class ApiExceptionHandler {

    private static final Logger log = LoggerFactory.getLogger(ApiExceptionHandler.class);

    /** Evita HttpMessageNotWritableException cuando el endpoint original usa p. ej. application/x-ndjson. */
    private static ResponseEntity<Map<String, String>> json(HttpStatus status, String error) {
        return ResponseEntity.status(status)
                .contentType(MediaType.APPLICATION_JSON)
                .body(Map.of("error", error));
    }

    @ExceptionHandler(AsyncRequestTimeoutException.class)
    public ResponseEntity<Map<String, String>> asyncTimeout(AsyncRequestTimeoutException ex) {
        log.warn("HTTP 503 AsyncRequestTimeoutException (sube spring.mvc.async.request-timeout o acorta la ingesta): {}", ex.toString());
        return json(
                HttpStatus.SERVICE_UNAVAILABLE,
                "Tiempo de espera agotado en petición asíncrona (p. ej. ingesta larga). "
                        + "Aumenta spring.mvc.async.request-timeout o indexa en lotes más pequeños.");
    }

    @ExceptionHandler(IllegalArgumentException.class)
    public ResponseEntity<Map<String, String>> badRequest(IllegalArgumentException ex) {
        log.warn("HTTP 400 IllegalArgumentException: {}", ex.getMessage());
        return json(HttpStatus.BAD_REQUEST, ex.getMessage() != null ? ex.getMessage() : "Bad request");
    }

    @ExceptionHandler(IllegalStateException.class)
    public ResponseEntity<Map<String, String>> badState(IllegalStateException ex) {
        log.warn("HTTP 400 IllegalStateException: {}", ex.getMessage());
        return json(HttpStatus.BAD_REQUEST, ex.getMessage() != null ? ex.getMessage() : "Illegal state");
    }

    @ExceptionHandler(MethodArgumentNotValidException.class)
    public ResponseEntity<Map<String, String>> validation(MethodArgumentNotValidException ex) {
        String msg = ex.getBindingResult().getFieldErrors().stream()
                .findFirst()
                .map(fe -> fe.getField() + ": " + fe.getDefaultMessage())
                .orElse("Validation failed");
        log.warn("HTTP 400 validation: {}", msg);
        return json(HttpStatus.BAD_REQUEST, msg);
    }

    @ExceptionHandler(MaxUploadSizeExceededException.class)
    public ResponseEntity<Map<String, String>> maxUpload(MaxUploadSizeExceededException ex) {
        log.warn("HTTP 413 MaxUploadSizeExceededException: {}", ex.getMessage());
        return json(HttpStatus.PAYLOAD_TOO_LARGE, "El archivo supera el tamaño máximo permitido.");
    }

    @ExceptionHandler(HttpRequestMethodNotSupportedException.class)
    public ResponseEntity<Map<String, String>> methodNotSupported(HttpRequestMethodNotSupportedException ex) {
        String msg = ex.getMessage() != null ? ex.getMessage() : "Method not allowed";
        log.warn("HTTP 405 {}: {}", ex.getMethod(), msg);
        return json(HttpStatus.METHOD_NOT_ALLOWED, msg);
    }

    @ExceptionHandler(ResponseStatusException.class)
    public ResponseEntity<Map<String, String>> responseStatus(ResponseStatusException ex) {
        String reason = ex.getReason();
        if (reason == null || reason.isBlank()) {
            reason = ex.getStatusCode().toString();
        }
        if (ex.getStatusCode().is5xxServerError()) {
            log.error("HTTP {} ResponseStatusException: {}", ex.getStatusCode().value(), reason, ex);
        } else {
            log.warn("HTTP {} ResponseStatusException: {}", ex.getStatusCode().value(), reason);
        }
        return ResponseEntity.status(ex.getStatusCode())
                .contentType(MediaType.APPLICATION_JSON)
                .body(Map.of("error", reason));
    }

    @ExceptionHandler(Exception.class)
    public ResponseEntity<Map<String, String>> generic(Exception ex) {
        log.error("HTTP 500 no manejada: {} — {}", ex.getClass().getName(), ex.getMessage(), ex);
        String msg = ex.getMessage() == null ? "Unexpected error" : ex.getMessage();
        return json(HttpStatus.INTERNAL_SERVER_ERROR, msg);
    }
}
