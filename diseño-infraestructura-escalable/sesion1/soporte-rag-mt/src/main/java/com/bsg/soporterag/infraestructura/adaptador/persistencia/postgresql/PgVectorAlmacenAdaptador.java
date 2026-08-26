package com.bsg.soporterag.infraestructura.adaptador.persistencia.postgresql;

import com.bsg.soporterag.configuracion.VectorPropiedades;
import com.bsg.soporterag.dominio.modelo.CoincidenciaVectorial;
import com.bsg.soporterag.dominio.modelo.FragmentoVectorial;
import com.bsg.soporterag.dominio.modelo.FuenteRag;
import com.bsg.soporterag.dominio.puerto.salida.AlmacenVectorialPort;
import com.pgvector.PGvector;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.jdbc.core.namedparam.MapSqlParameterSource;
import org.springframework.jdbc.core.namedparam.NamedParameterJdbcTemplate;
import org.springframework.lang.NonNull;
import org.springframework.stereotype.Component;
import reactor.core.publisher.Flux;
import reactor.core.publisher.Mono;
import reactor.core.scheduler.Schedulers;

import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.List;

/**
 * Adaptador pgvector con tablas separadas por {@link FuenteRag}. JDBC en {@code boundedElastic}.
 */
@Component
public class PgVectorAlmacenAdaptador implements AlmacenVectorialPort {

    private final JdbcTemplate jdbc;
    private final NamedParameterJdbcTemplate namedJdbc;
    private final VectorPropiedades propiedades;

    public PgVectorAlmacenAdaptador(@NonNull JdbcTemplate jdbcTemplate, @NonNull VectorPropiedades propiedades) {
        this.jdbc = jdbcTemplate;
        this.namedJdbc = new NamedParameterJdbcTemplate(jdbcTemplate);
        this.propiedades = propiedades;
    }

    @Override
    public Mono<Void> guardarLote(FuenteRag fuente, String namespace, Flux<FragmentoVectorial> fragmentos) {
        return fragmentos.collectList()
                .flatMap(lista -> Mono.fromRunnable(() -> upsertBatch(fuente, namespace, lista))
                        .subscribeOn(Schedulers.boundedElastic())
                        .then());
    }

    @Override
    public Flux<CoincidenciaVectorial> buscarSimilares(
            FuenteRag fuente, String namespace, float[] embedding, int topK) {
        return Mono.fromCallable(() -> querySimilares(fuente, namespace, embedding, topK))
                .subscribeOn(Schedulers.boundedElastic())
                .flatMapMany(Flux::fromIterable);
    }

    @Override
    public Mono<Void> eliminarNamespace(FuenteRag fuente, String namespace) {
        String tabla = propiedades.nombreTabla(fuente);
        return Mono.fromRunnable(() -> borrarPorNamespace(tabla, namespace))
                .subscribeOn(Schedulers.boundedElastic())
                .then();
    }

    @Override
    public Mono<Void> eliminarDocumentos(FuenteRag fuente, String namespace, List<String> documentos) {
        String tabla = propiedades.nombreTabla(fuente);
        return Mono.fromRunnable(() -> borrarDocumentos(tabla, namespace, documentos))
                .subscribeOn(Schedulers.boundedElastic())
                .then();
    }

    @Override
    public Flux<CoincidenciaVectorial> buscarPorDocumento(FuenteRag fuente, String namespace, String filePath) {
        return Mono.fromCallable(() -> queryPorDocumento(fuente, namespace, filePath))
                .subscribeOn(Schedulers.boundedElastic())
                .flatMapMany(Flux::fromIterable);
    }

    private void borrarPorNamespace(String tabla, String namespace) {
        String sql = "DELETE FROM " + tabla + " WHERE namespace = ?";
        jdbc.update(sql, namespace);
    }

    private void borrarDocumentos(String tabla, String namespace, List<String> documentos) {
        if (documentos == null || documentos.isEmpty()) {
            return;
        }
        String sql = "DELETE FROM " + tabla + " WHERE namespace = :namespace AND fuente IN (:documentos)";
        MapSqlParameterSource parameters = new MapSqlParameterSource();
        parameters.addValue("namespace", namespace);
        parameters.addValue("documentos", documentos);
        namedJdbc.update(sql, parameters);
    }

    private void upsertBatch(FuenteRag fuente, String namespace, List<FragmentoVectorial> registros) {
        if (registros.isEmpty()) {
            return;
        }
        String tabla = propiedades.nombreTabla(fuente);
        String sql = "INSERT INTO " + tabla + " (id, namespace, fuente, indice_fragmento, contenido, embedding) "
                + "VALUES (?, ?, ?, ?, ?, ?) "
                + "ON CONFLICT (id) DO UPDATE SET "
                + "namespace = EXCLUDED.namespace, "
                + "fuente = EXCLUDED.fuente, "
                + "indice_fragmento = EXCLUDED.indice_fragmento, "
                + "contenido = EXCLUDED.contenido, "
                + "embedding = EXCLUDED.embedding";

        jdbc.batchUpdate(sql, registros, registros.size(), (PreparedStatement ps, FragmentoVectorial r) -> {
            ps.setString(1, r.id());
            ps.setString(2, namespace);
            ps.setString(3, r.fuente());
            ps.setInt(4, r.indiceFragmento());
            ps.setString(5, r.contenido());
            ps.setObject(6, new PGvector(r.embedding()));
        });
    }

    private List<CoincidenciaVectorial> querySimilares(
            FuenteRag fuente, String namespace, float[] embedding, int topK) {
        int k = topK > 0 ? topK : propiedades.ragTopK();
        String tabla = propiedades.nombreTabla(fuente);
        PGvector vector = new PGvector(embedding);
        
        String sql = String.format(
                "SELECT fuente, indice_fragmento, contenido, (embedding <=> ?) AS dist FROM %s WHERE namespace = ? ORDER BY dist ASC LIMIT ?",
                tabla);

        return jdbc.query(
                con -> {
                    PreparedStatement ps = con.prepareStatement(sql);
                    ps.setObject(1, vector);
                    ps.setString(2, namespace);
                    ps.setInt(3, k);
                    return ps;
                },
                PgVectorAlmacenAdaptador::mapearCoincidencia);
    }

    private static CoincidenciaVectorial mapearCoincidencia(ResultSet rs, int rowNum) throws SQLException {
        return new CoincidenciaVectorial(
                rs.getString("fuente"),
                rs.getInt("indice_fragmento"),
                rs.getString("contenido"),
                rs.getDouble("dist"));
    }

    private List<CoincidenciaVectorial> queryPorDocumento(FuenteRag fuente, String namespace, String filePath) {
        String tabla = propiedades.nombreTabla(fuente);
        String sql = String.format(
                "SELECT fuente, indice_fragmento, contenido, 0.0 AS dist FROM %s WHERE namespace = ? AND fuente = ? ORDER BY indice_fragmento ASC",
                tabla);
        return jdbc.query(sql, (rs, rowNum) -> new CoincidenciaVectorial(
                rs.getString("fuente"),
                rs.getInt("indice_fragmento"),
                rs.getString("contenido"),
                rs.getDouble("dist")
        ), namespace, filePath);
    }
}
