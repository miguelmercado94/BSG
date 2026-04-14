package com.bsg.docviz.vector;

import com.bsg.docviz.config.VectorProperties;
import com.pgvector.PGvector;
import jakarta.annotation.PostConstruct;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.dao.DataAccessException;
import org.springframework.jdbc.core.BatchPreparedStatementSetter;
import org.springframework.jdbc.core.JdbcTemplate;

import javax.sql.DataSource;
import java.sql.PreparedStatement;
import java.sql.SQLException;
import java.util.List;

/**
 * Almacén vectorial en PostgreSQL con extensión pgvector (similitud coseno vía {@code <=>}).
 */
public class PgVectorStore implements VectorStore {

    private static final Logger log = LoggerFactory.getLogger(PgVectorStore.class);

    private final JdbcTemplate jdbc;
    private final VectorProperties props;

    public PgVectorStore(DataSource dataSource, VectorProperties props) {
        this.jdbc = new JdbcTemplate(dataSource);
        this.props = props;
    }

    @PostConstruct
    public void initSchema() {
        jdbc.execute("CREATE EXTENSION IF NOT EXISTS vector");
        int dim = props.getEmbeddingDimensions();
        jdbc.execute(
                "CREATE TABLE IF NOT EXISTS docviz_vector_chunk ("
                        + "id VARCHAR(128) PRIMARY KEY,"
                        + "namespace VARCHAR(512) NOT NULL,"
                        + "user_label VARCHAR(256) NOT NULL,"
                        + "source TEXT NOT NULL,"
                        + "chunk_index INT NOT NULL,"
                        + "embedding vector(" + dim + ") NOT NULL"
                        + ")");
        jdbc.execute("CREATE INDEX IF NOT EXISTS idx_docviz_vec_ns ON docviz_vector_chunk(namespace)");
    }

    @Override
    public void upsertBatch(String namespace, List<VectorRecord> records) {
        if (records == null || records.isEmpty()) {
            return;
        }
        int dim = props.getEmbeddingDimensions();
        String sql =
                "INSERT INTO docviz_vector_chunk (id, namespace, user_label, source, chunk_index, embedding) "
                        + "VALUES (?, ?, ?, ?, ?, ?) "
                        + "ON CONFLICT (id) DO UPDATE SET "
                        + "namespace = EXCLUDED.namespace, user_label = EXCLUDED.user_label, "
                        + "source = EXCLUDED.source, chunk_index = EXCLUDED.chunk_index, embedding = EXCLUDED.embedding";
        try {
            jdbc.batchUpdate(
                    sql,
                    new BatchPreparedStatementSetter() {
                        @Override
                        public void setValues(PreparedStatement ps, int i) throws SQLException {
                            VectorRecord r = records.get(i);
                            if (r.vector().length != dim) {
                                throw new IllegalStateException(
                                        "Dimensión de embedding " + r.vector().length
                                                + " != docviz.vector.embedding-dimensions="
                                                + dim);
                            }
                            ps.setString(1, r.id());
                            ps.setString(2, namespace);
                            ps.setString(3, r.userLabel() != null ? r.userLabel() : "");
                            ps.setString(4, r.source());
                            ps.setInt(5, r.chunkIndex());
                            ps.setObject(6, new PGvector(r.vector()));
                        }

                        @Override
                        public int getBatchSize() {
                            return records.size();
                        }
                    });
        } catch (DataAccessException e) {
            log.error(
                    "pgvector upsertBatch falló: {} filas, namespace={}, primera id={}",
                    records.size(),
                    namespace,
                    records.isEmpty() ? "—" : records.get(0).id(),
                    e);
            throw e;
        }
    }

    @Override
    public List<VectorMatch> queryTopK(String namespace, float[] vector, int topK, String userLabel) {
        int dim = props.getEmbeddingDimensions();
        if (vector.length != dim) {
            throw new IllegalStateException(
                    "Dimensión de la consulta " + vector.length + " != docviz.vector.embedding-dimensions=" + dim);
        }
        PGvector qv = new PGvector(vector);
        String label = userLabel != null ? userLabel : "";
        String sql =
                "SELECT source, chunk_index, (embedding <=> ?) AS dist FROM docviz_vector_chunk "
                        + "WHERE namespace = ? AND user_label = ? ORDER BY embedding <=> ? LIMIT ?";
        return jdbc.query(
                con -> {
                    PreparedStatement ps = con.prepareStatement(sql);
                    ps.setObject(1, qv);
                    ps.setString(2, namespace);
                    ps.setString(3, label);
                    ps.setObject(4, qv);
                    ps.setInt(5, topK);
                    return ps;
                },
                (rs, rowNum) -> {
                    double dist = rs.getDouble("dist");
                    double score = Math.max(0.0, 1.0 - dist);
                    return new VectorMatch(rs.getString("source"), rs.getInt("chunk_index"), score);
                });
    }

    @Override
    public void deleteAllInNamespace(String namespace) {
        jdbc.update("DELETE FROM docviz_vector_chunk WHERE namespace = ?", namespace);
    }
}
