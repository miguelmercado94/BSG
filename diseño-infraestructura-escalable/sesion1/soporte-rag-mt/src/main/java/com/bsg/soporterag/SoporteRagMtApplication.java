package com.bsg.soporterag;

import com.bsg.soporterag.configuracion.AlmacenamientoS3Propiedades;
import com.bsg.soporterag.configuracion.CacheRedisPropiedades;
import com.bsg.soporterag.configuracion.ChatPropiedades;
import com.bsg.soporterag.configuracion.PromptsPropiedades;
import com.bsg.soporterag.configuracion.VectorPropiedades;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.boot.context.properties.EnableConfigurationProperties;

@SpringBootApplication
@EnableConfigurationProperties({
        VectorPropiedades.class,
        AlmacenamientoS3Propiedades.class,
        CacheRedisPropiedades.class,
        PromptsPropiedades.class,
        ChatPropiedades.class
})
public class SoporteRagMtApplication {

    public static void main(String[] args) {
        SpringApplication.run(SoporteRagMtApplication.class, args);
    }
}
