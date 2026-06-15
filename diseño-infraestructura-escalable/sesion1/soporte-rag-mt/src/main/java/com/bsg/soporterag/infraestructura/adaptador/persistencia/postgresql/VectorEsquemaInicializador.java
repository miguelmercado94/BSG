package com.bsg.soporterag.infraestructura.adaptador.persistencia.postgresql;

import com.bsg.soporterag.configuracion.VectorPropiedades;
import jakarta.annotation.PostConstruct;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.jdbc.core.JdbcTemplate;

/**
 * DDL idempotente: extensión pgvector + una tabla por {@link com.bsg.soporterag.dominio.modelo.FuenteRag}.
 */
public class VectorEsquemaInicializador {

    private static final Logger log = LoggerFactory.getLogger(VectorEsquemaInicializador.class);

    private final JdbcTemplate jdbc;
    private final VectorPropiedades propiedades;

    public VectorEsquemaInicializador(JdbcTemplate jdbc, VectorPropiedades propiedades) {
        this.jdbc = jdbc;
        this.propiedades = propiedades;
    }

    @PostConstruct
    public void inicializar() {
        jdbc.execute("CREATE EXTENSION IF NOT EXISTS vector");
        int dim = propiedades.embeddingDimensions();
        crearTablaSiNoExiste(propiedades.tablaGit(), dim);
        crearTablaSiNoExiste(propiedades.tablaSoporte(), dim);
        log.info(
                "pgvector listo | tablas RAG git={} soporte={} | dims={}",
                propiedades.tablaGit(),
                propiedades.tablaSoporte(),
                dim);
    }

    private void crearTablaSiNoExiste(String nombreTabla, int dim) {
        validarIdentificadorTabla(nombreTabla);
        jdbc.execute("""
                CREATE TABLE IF NOT EXISTS %s (
                    id VARCHAR(128) PRIMARY KEY,
                    namespace VARCHAR(512) NOT NULL,
                    fuente TEXT NOT NULL,
                    indice_fragmento INT NOT NULL,
                    contenido TEXT NOT NULL,
                    embedding vector(%d) NOT NULL
                )
                """.formatted(nombreTabla, dim));
        jdbc.execute("""
                CREATE INDEX IF NOT EXISTS idx_%s_ns ON %s(namespace)
                """.formatted(nombreTabla, nombreTabla));
    }

    /** Solo nombres de tabla controlados por configuración (evita SQL injection en DDL). */
    private static void validarIdentificadorTabla(String nombreTabla) {
        if (nombreTabla == null || !nombreTabla.matches("[a-z][a-z0-9_]*")) {
            throw new IllegalStateException("Nombre de tabla pgvector inválido: " + nombreTabla);
        }
    }
}
