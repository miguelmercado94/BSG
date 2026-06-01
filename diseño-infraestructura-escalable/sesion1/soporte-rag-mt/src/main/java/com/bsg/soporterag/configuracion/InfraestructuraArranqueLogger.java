package com.bsg.soporterag.configuracion;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.boot.ApplicationArguments;
import org.springframework.boot.ApplicationRunner;
import org.springframework.core.env.Environment;
import org.springframework.stereotype.Component;

@Component
public class InfraestructuraArranqueLogger implements ApplicationRunner {

    private static final Logger log = LoggerFactory.getLogger(InfraestructuraArranqueLogger.class);

    private final Environment environment;
    private final AlmacenamientoS3Propiedades s3Propiedades;
    private final CacheRedisPropiedades cachePropiedades;
    private final VectorPropiedades vectorPropiedades;

    public InfraestructuraArranqueLogger(
            Environment environment,
            AlmacenamientoS3Propiedades s3Propiedades,
            CacheRedisPropiedades cachePropiedades,
            VectorPropiedades vectorPropiedades) {
        this.environment = environment;
        this.s3Propiedades = s3Propiedades;
        this.cachePropiedades = cachePropiedades;
        this.vectorPropiedades = vectorPropiedades;
    }

    @Override
    public void run(ApplicationArguments args) {
        log.info(
                """
                soporte-rag-mt arrancado
                  perfiles={}
                  embeddings={} dims={}
                  pgvector git={} | soporte={}
                  s3 enabled={} modo={} buckets=[soporte={}, borradores={}, workarea={}]
                  redis={}
                """,
                String.join(",", environment.getActiveProfiles()),
                vectorPropiedades.embeddingsProvider(),
                vectorPropiedades.embeddingDimensions(),
                vectorPropiedades.tablaGit(),
                vectorPropiedades.tablaSoporte(),
                s3Propiedades.enabled(),
                s3Propiedades.usaEndpointPersonalizado() ? "localstack" : "aws-iam",
                s3Propiedades.bucketSoporte(),
                s3Propiedades.bucketBorradores(),
                s3Propiedades.bucketWorkarea(),
                cachePropiedades.enabled());
    }
}
