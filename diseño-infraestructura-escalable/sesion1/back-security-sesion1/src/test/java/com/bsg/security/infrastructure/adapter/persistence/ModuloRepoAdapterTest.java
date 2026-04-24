package com.bsg.security.infrastructure.adapter.persistence;

import com.bsg.security.domain.model.Modulo;
import com.bsg.security.infrastructure.entity.ModuleEntity;
import com.bsg.security.infrastructure.repository.ModuleRepository;
import com.bsg.security.mapper.ModuloMapper;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import reactor.core.publisher.Mono;
import reactor.test.StepVerifier;

import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class ModuloRepoAdapterTest {

    @Mock
    private ModuleRepository moduleRepository;

    @Mock
    private ModuloMapper moduloMapper;

    private ModuloRepoAdapter adapter;

    @BeforeEach
    void setUp() {
        adapter = new ModuloRepoAdapter(moduleRepository, moduloMapper);
    }

    @Test
    void findById_maps() {
        ModuleEntity e = new ModuleEntity();
        e.setId(1L);
        Modulo d = new Modulo();
        d.setId(1L);
        when(moduleRepository.findById(1L)).thenReturn(Mono.just(e));
        when(moduloMapper.toDomain(e)).thenReturn(d);

        StepVerifier.create(adapter.findById(1L))
                .expectNext(d)
                .verifyComplete();
    }
}
