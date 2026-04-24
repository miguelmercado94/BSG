package com.bsg.docviz.repository;

import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.jdbc.core.RowMapper;
import org.springframework.jdbc.support.GeneratedKeyHolder;
import org.springframework.stereotype.Repository;

import java.sql.PreparedStatement;
import java.util.List;
import java.util.Objects;
import java.util.Optional;

@Repository
public class CellJdbcRepository {

    private static final RowMapper<CellEntity> MAPPER = (rs, rowNum) -> new CellEntity(
            rs.getLong("id"),
            rs.getString("name"),
            rs.getString("description"),
            rs.getTimestamp("created_at").toInstant(),
            rs.getString("created_by"));

    private final JdbcTemplate jdbc;

    public CellJdbcRepository(JdbcTemplate jdbc) {
        this.jdbc = jdbc;
    }

    public List<CellEntity> findAll() {
        return jdbc.query("SELECT id, name, description, created_at, created_by FROM docviz_cell ORDER BY name", MAPPER);
    }

    public Optional<CellEntity> findById(long id) {
        List<CellEntity> list = jdbc.query(
                "SELECT id, name, description, created_at, created_by FROM docviz_cell WHERE id = ?",
                MAPPER,
                id);
        return list.isEmpty() ? Optional.empty() : Optional.of(list.getFirst());
    }

    /** Identificador normalizado: {@code lower(btrim(name))} (PostgreSQL). */
    public Optional<CellEntity> findByNormalizedName(String normalizedName) {
        List<CellEntity> list = jdbc.query(
                """
                SELECT id, name, description, created_at, created_by FROM docviz_cell
                WHERE lower(btrim(name)) = ?
                """,
                MAPPER,
                normalizedName);
        return list.isEmpty() ? Optional.empty() : Optional.of(list.getFirst());
    }

    public boolean existsOtherWithNormalizedName(String normalizedName, long excludeId) {
        Integer n = jdbc.queryForObject(
                """
                SELECT COUNT(*)::int FROM docviz_cell
                WHERE lower(btrim(name)) = ? AND id <> ?
                """,
                Integer.class,
                normalizedName,
                excludeId);
        return n != null && n > 0;
    }

    public long insert(String name, String description, String createdBy) {
        GeneratedKeyHolder kh = new GeneratedKeyHolder();
        jdbc.update(con -> {
            PreparedStatement ps = con.prepareStatement(
                    "INSERT INTO docviz_cell (name, description, created_by) VALUES (?,?,?)",
                    new String[] {"id"});
            ps.setString(1, name);
            ps.setString(2, description);
            ps.setString(3, createdBy);
            return ps;
        }, kh);
        return Objects.requireNonNull(kh.getKey()).longValue();
    }

    public boolean update(long id, String name, String description) {
        return jdbc.update("UPDATE docviz_cell SET name = ?, description = ? WHERE id = ?", name, description, id) > 0;
    }

    public boolean delete(long id) {
        return jdbc.update("DELETE FROM docviz_cell WHERE id = ?", id) > 0;
    }
}
