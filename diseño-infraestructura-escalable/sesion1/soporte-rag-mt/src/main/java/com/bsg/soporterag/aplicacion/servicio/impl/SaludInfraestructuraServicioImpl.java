package com.bsg.soporterag.aplicacion.servicio.impl;

import com.bsg.soporterag.aplicacion.dto.response.SaludInfraestructuraDto;
import com.bsg.soporterag.aplicacion.puerto.entrada.ConsultarSaludInfraestructuraCasoDeUso;
import com.bsg.soporterag.configuracion.AlmacenamientoS3Propiedades;
import com.bsg.soporterag.configuracion.CacheRedisPropiedades;
import com.bsg.soporterag.configuracion.VectorPropiedades;
import com.bsg.soporterag.dominio.modelo.RolBucketS3;
import com.bsg.soporterag.dominio.puerto.salida.AlmacenObjetoPort;
import com.bsg.soporterag.dominio.puerto.salida.CachePort;
import org.springframework.core.env.Environment;
import org.springframework.stereotype.Service;
import reactor.core.publisher.Mono;

import java.util.Arrays;
import java.util.Map;

@Service
public class SaludInfraestructuraServicioImpl implements ConsultarSaludInfraestructuraCasoDeUso {

    private final Environment environment;
    private final VectorPropiedades vectorPropiedades;
    private final AlmacenamientoS3Propiedades s3Propiedades;
    private final CacheRedisPropiedades cachePropiedades;
    private final AlmacenObjetoPort almacenObjetoPort;
    private final CachePort cachePort;

    public SaludInfraestructuraServicioImpl(
            Environment environment,
            VectorPropiedades vectorPropiedades,
            AlmacenamientoS3Propiedades s3Propiedades,
            CacheRedisPropiedades cachePropiedades,
            AlmacenObjetoPort almacenObjetoPort,
            CachePort cachePort) {
        this.environment = environment;
        this.vectorPropiedades = vectorPropiedades;
        this.s3Propiedades = s3Propiedades;
        this.cachePropiedades = cachePropiedades;
        this.almacenObjetoPort = almacenObjetoPort;
        this.cachePort = cachePort;
    }

    @Override
    public Mono<SaludInfraestructuraDto> ejecutar() {
        return Mono.fromSupplier(() -> new SaludInfraestructuraDto(
                "soporte-rag-mt",
                Arrays.asList(environment.getActiveProfiles()),
                vectorPropiedades.embeddingsProvider(),
                vectorPropiedades.embeddingDimensions(),
                Map.of(
                        "git", vectorPropiedades.tablaGit(),
                        "soporte", vectorPropiedades.tablaSoporte()),
                Map.of(
                        "soporte", almacenObjetoPort.nombreBucket(RolBucketS3.SOPORTE),
                        "borradores", almacenObjetoPort.nombreBucket(RolBucketS3.BORRADORES),
                        "workarea", almacenObjetoPort.nombreBucket(RolBucketS3.WORKAREA)),
                s3Propiedades.enabled() && almacenObjetoPort.configurado(),
                s3Propiedades.usaEndpointPersonalizado() ? "localstack" : "aws-iam",
                cachePropiedades.enabled() && cachePort.activa()));
    }
}
