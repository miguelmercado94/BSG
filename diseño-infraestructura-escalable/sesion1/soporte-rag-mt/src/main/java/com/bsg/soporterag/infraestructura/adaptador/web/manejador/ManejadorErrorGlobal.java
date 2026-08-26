package com.bsg.soporterag.infraestructura.adaptador.web.manejador;

import com.bsg.soporterag.dominio.excepcion.CelulaNoEncontradaException;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.http.HttpStatus;
import org.springframework.http.ProblemDetail;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;
import org.springframework.web.bind.support.WebExchangeBindException;
import reactor.core.publisher.Mono;

@RestControllerAdvice
public class ManejadorErrorGlobal {

    private static final Logger log = LoggerFactory.getLogger(ManejadorErrorGlobal.class);

    @ExceptionHandler(WebExchangeBindException.class)
    public Mono<ProblemDetail> handleValidationExceptions(WebExchangeBindException ex) {
        ProblemDetail detail = ProblemDetail.forStatus(HttpStatus.BAD_REQUEST);
        detail.setTitle("Validación fallida");
        detail.setDetail(ex.getAllErrors().isEmpty() ? ex.getMessage() : ex.getAllErrors().getFirst().getDefaultMessage());
        return Mono.just(detail);
    }

    @ExceptionHandler(CelulaNoEncontradaException.class)
    public Mono<ProblemDetail> handleCelulaNoEncontrada(CelulaNoEncontradaException ex) {
        ProblemDetail detail = ProblemDetail.forStatus(HttpStatus.NOT_FOUND);
        detail.setTitle("Recurso no encontrado");
        detail.setDetail(ex.getMessage());
        return Mono.just(detail);
    }

    @ExceptionHandler(IllegalArgumentException.class)
    public Mono<ProblemDetail> handleIllegalArgument(IllegalArgumentException ex) {
        ProblemDetail detail = ProblemDetail.forStatus(HttpStatus.BAD_REQUEST);
        detail.setTitle("Argumento inválido");
        detail.setDetail(ex.getMessage());
        return Mono.just(detail);
    }

    @ExceptionHandler(IllegalStateException.class)
    public Mono<ProblemDetail> handleIllegalState(IllegalStateException ex) {
        ProblemDetail detail = ProblemDetail.forStatus(HttpStatus.CONFLICT); // 409 Conflict es a menudo más apropiado
        detail.setTitle("Estado inválido");
        detail.setDetail(ex.getMessage());
        return Mono.just(detail);
    }

    @ExceptionHandler(Exception.class)
    public Mono<ProblemDetail> handleGenericException(Exception ex) {
        log.error("Error no manejado: {}", ex.getMessage(), ex);
        ProblemDetail detail = ProblemDetail.forStatus(HttpStatus.INTERNAL_SERVER_ERROR);
        detail.setTitle("Error interno del servidor");
        detail.setDetail(ex.getMessage() != null ? ex.getMessage() : "Error inesperado");
        return Mono.just(detail);
    }
}
