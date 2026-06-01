package com.bsg.soporterag.configuracion;

import com.bsg.soporterag.infraestructura.adaptador.persistencia.postgresql.VectorEsquemaInicializador;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.jdbc.core.JdbcTemplate;

@Configuration
public class VectorAlmacenConfiguracion {

    @Bean
    VectorEsquemaInicializador vectorEsquemaInicializador(JdbcTemplate jdbcTemplate, VectorPropiedades propiedades) {
        return new VectorEsquemaInicializador(jdbcTemplate, propiedades);
    }
}
