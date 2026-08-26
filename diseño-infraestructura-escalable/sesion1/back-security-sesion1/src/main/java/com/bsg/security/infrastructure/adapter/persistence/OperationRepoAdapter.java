package com.bsg.security.infrastructure.adapter.persistence;

import com.bsg.security.application.port.output.persistence.OperationRepositoryPort;
import com.bsg.security.domain.model.Operation;
import com.bsg.security.domain.support.ApiPathTemplateMatcher;
import com.bsg.security.infrastructure.entity.OperationEntity;
import com.bsg.security.infrastructure.repository.OperationRepository;
import com.bsg.security.mapper.OperationMapper;
import org.springframework.stereotype.Component;
import reactor.core.publisher.Flux;
import reactor.core.publisher.Mono;

import java.time.LocalDateTime;
import java.util.Comparator;
import java.util.List;

/**
 * Adapter de persistencia para Operation. Conecta el modelo de dominio con la BD:
 * implementa OperationRepositoryPort, usa OperationMapper (domain ↔ entity) y delega en OperationRepository.
 * Siempre rellena auditoría en creación (createdAt, updatedAt, createdBy, updatedBy) y en actualización (updatedAt, updatedBy).
 */
@Component
public class OperationRepoAdapter implements OperationRepositoryPort {

    private static final String AUDIT_USER = "system";

    /**
     * Desempate si varias plantillas coinciden: más segmentos literales, luego más segmentos totales, luego path lexicográfico.
     */
    private static final Comparator<OperationEntity> TEMPLATE_MATCH_ORDER =
            Comparator.comparingInt((OperationEntity e) -> ApiPathTemplateMatcher.literalSegmentCount(e.getPath()))
                    .reversed()
                    .thenComparingInt(e -> ApiPathTemplateMatcher.segmentCount(e.getPath()))
                    .reversed()
                    .thenComparing(OperationEntity::getPath);

    private final OperationRepository operationRepository;
    private final OperationMapper operationMapper;
    public OperationRepoAdapter(OperationRepository operationRepository,
                                OperationMapper operationMapper) {
        this.operationRepository = operationRepository;
        this.operationMapper = operationMapper;
    }

    @Override
    public Mono<Operation> findById(Long id) {
        return operationRepository.findById(id)
                .map(operationMapper::toDomain);
    }

    @Override
    public Mono<Operation> findByPathAndHttpMethod(String path, String httpMethod) {
        return operationRepository.findByPathAndHttpMethod(path, httpMethod)
                .map(operationMapper::toDomain);
    }

    @Override
    public Mono<Operation> findByModulePathBaseAndPathAndHttpMethod(String modulePathBase, String path, String httpMethod) {
        return operationRepository
                .findByModulePathBaseAndPathAndHttpMethod(modulePathBase, path, httpMethod)
                .switchIfEmpty(resolveByTemplate(modulePathBase, path, httpMethod))
                .map(operationMapper::toDomain);
    }

    private Mono<OperationEntity> resolveByTemplate(String modulePathBase, String actualPath, String httpMethod) {
        return operationRepository
                .findTemplateOperationsByModulePathBaseAndHttpMethod(modulePathBase, httpMethod)
                .filter(entity -> ApiPathTemplateMatcher.matches(entity.getPath(), actualPath))
                .collectList()
                .flatMap(OperationRepoAdapter::pickSingleTemplateMatch);
    }

    private static Mono<OperationEntity> pickSingleTemplateMatch(List<OperationEntity> matches) {
        if (matches.isEmpty()) {
            return Mono.empty();
        }
        matches.sort(TEMPLATE_MATCH_ORDER);
        return Mono.just(matches.getFirst());
    }

    @Override
    public Flux<Operation> findByModuleId(Long moduleId) {
        return operationRepository.findByModuleId(moduleId)
                .map(operationMapper::toDomain);
    }

    @Override
    public Flux<Operation> findByActiveTrue() {
        return operationRepository.findByActiveTrue()
                .map(operationMapper::toDomain);
    }

    @Override
    public Mono<Operation> save(Operation operation) {
        OperationEntity entity = operationMapper.toEntity(operation);
        LocalDateTime now = LocalDateTime.now();
        if (entity.getId() == null) {
            entity.setCreatedAt(now);
            entity.setUpdatedAt(now);
            entity.setCreatedBy(entity.getCreatedBy() != null ? entity.getCreatedBy() : AUDIT_USER);
            entity.setUpdatedBy(entity.getUpdatedBy() != null ? entity.getUpdatedBy() : AUDIT_USER);
        } else {
            entity.setUpdatedAt(now);
            entity.setUpdatedBy(entity.getUpdatedBy() != null ? entity.getUpdatedBy() : AUDIT_USER);
        }
        return operationRepository.save(entity)
                .map(operationMapper::toDomain);
    }
}
