package com.bsg.docviz.repository;

import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.jdbc.core.RowMapper;
import org.springframework.jdbc.support.GeneratedKeyHolder;
import org.springframework.stereotype.Repository;

import java.sql.PreparedStatement;
import java.sql.Timestamp;
import java.time.Instant;
import java.util.List;
import java.util.Objects;
import java.util.Optional;

@Repository
public class TaskJdbcRepository {

    private static final RowMapper<TaskEntity> MAPPER = (rs, rowNum) -> new TaskEntity(
            rs.getLong("id"),
            rs.getString("user_id"),
            rs.getString("hu_code"),
            rs.getLong("cell_repo_id"),
            rs.getString("enunciado"),
            rs.getString("status"),
            rs.getTimestamp("created_at").toInstant(),
            rs.getTimestamp("continued_at") != null ? rs.getTimestamp("continued_at").toInstant() : null,
            rs.getString("chat_conversation_id"));

    private final JdbcTemplate jdbc;

    public TaskJdbcRepository(JdbcTemplate jdbc) {
        this.jdbc = jdbc;
    }

    public List<TaskEntity> findByUserId(String userId) {
        return jdbc.query(
                """
                SELECT id, user_id, hu_code, cell_repo_id, enunciado, status, created_at, continued_at, chat_conversation_id
                FROM docviz_task WHERE user_id = ? ORDER BY created_at DESC
                """,
                MAPPER,
                userId);
    }

    public List<TaskEntity> findAll() {
        return jdbc.query(
                """
                SELECT id, user_id, hu_code, cell_repo_id, enunciado, status, created_at, continued_at, chat_conversation_id
                FROM docviz_task ORDER BY created_at DESC
                """,
                MAPPER);
    }

    /** Tareas cuyo repositorio pertenece a la célula indicada (p. ej. filtro admin). */
    public List<TaskEntity> findByCellId(long cellId) {
        return jdbc.query(
                """
                SELECT t.id, t.user_id, t.hu_code, t.cell_repo_id, t.enunciado, t.status, t.created_at, t.continued_at, t.chat_conversation_id
                FROM docviz_task t
                INNER JOIN docviz_cell_repo r ON r.id = t.cell_repo_id
                WHERE r.cell_id = ?
                ORDER BY t.created_at DESC
                """,
                MAPPER,
                cellId);
    }

    /** Tareas del usuario en repos de esa célula (soporte). */
    public List<TaskEntity> findByUserIdAndCellId(String userId, long cellId) {
        return jdbc.query(
                """
                SELECT t.id, t.user_id, t.hu_code, t.cell_repo_id, t.enunciado, t.status, t.created_at, t.continued_at, t.chat_conversation_id
                FROM docviz_task t
                INNER JOIN docviz_cell_repo r ON r.id = t.cell_repo_id
                WHERE t.user_id = ? AND r.cell_id = ?
                ORDER BY t.created_at DESC
                """,
                MAPPER,
                userId,
                cellId);
    }

    public Optional<TaskEntity> findById(long id) {
        List<TaskEntity> list = jdbc.query(
                """
                SELECT id, user_id, hu_code, cell_repo_id, enunciado, status, created_at, continued_at, chat_conversation_id
                FROM docviz_task WHERE id = ?
                """,
                MAPPER,
                id);
        return list.isEmpty() ? Optional.empty() : Optional.of(list.getFirst());
    }

    public long insert(String userId, String huCode, long cellRepoId, String enunciado, String status, String chatConversationId) {
        GeneratedKeyHolder kh = new GeneratedKeyHolder();
        jdbc.update(con -> {
            PreparedStatement ps = con.prepareStatement(
                    """
                    INSERT INTO docviz_task (user_id, hu_code, cell_repo_id, enunciado, status, chat_conversation_id)
                    VALUES (?,?,?,?,?,?)
                    """,
                    new String[] {"id"});
            ps.setString(1, userId);
            ps.setString(2, huCode);
            ps.setLong(3, cellRepoId);
            ps.setString(4, enunciado);
            ps.setString(5, status);
            ps.setString(6, chatConversationId);
            return ps;
        }, kh);
        return Objects.requireNonNull(kh.getKey()).longValue();
    }

    /** Rellena el id de hilo para tareas antiguas o filas sin valor. */
    public boolean updateChatConversationId(long taskId, String chatConversationId) {
        return jdbc.update(
                "UPDATE docviz_task SET chat_conversation_id = ? WHERE id = ?",
                chatConversationId,
                taskId)
                > 0;
    }

    public boolean markContinued(long id) {
        return jdbc.update(
                "UPDATE docviz_task SET status = 'ACTIVE', continued_at = ? WHERE id = ?",
                Timestamp.from(Instant.now()),
                id) > 0;
    }

    /** Filas eliminadas (p. ej. antes de borrar {@code docviz_cell_repo}). */
    public int deleteByCellRepoId(long cellRepoId) {
        return jdbc.update("DELETE FROM docviz_task WHERE cell_repo_id = ?", cellRepoId);
    }

    /** Todas las tareas cuyo repo pertenece a la célula (p. ej. antes de {@code DELETE docviz_cell}). */
    public int deleteByCellId(long cellId) {
        return jdbc.update(
                """
                DELETE FROM docviz_task WHERE cell_repo_id IN (
                    SELECT id FROM docviz_cell_repo WHERE cell_id = ?
                )
                """,
                cellId);
    }

    public int countByCellRepoId(long cellRepoId) {
        Integer n =
                jdbc.queryForObject(
                        "SELECT COUNT(*)::int FROM docviz_task WHERE cell_repo_id = ?",
                        Integer.class,
                        cellRepoId);
        return n != null ? n : 0;
    }

    public int countByCellId(long cellId) {
        Integer n =
                jdbc.queryForObject(
                        """
                        SELECT COUNT(*)::int FROM docviz_task t
                        INNER JOIN docviz_cell_repo r ON r.id = t.cell_repo_id
                        WHERE r.cell_id = ?
                        """,
                        Integer.class,
                        cellId);
        return n != null ? n : 0;
    }
}
