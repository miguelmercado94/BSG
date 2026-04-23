package com.bsg.docviz.service;

import com.bsg.docviz.context.ChatConversationIds;
import com.bsg.docviz.dto.ChatHistoryEntryDto;
import com.bsg.docviz.security.UserIdSanitizer;
import com.google.api.core.ApiFuture;
import com.google.cloud.Timestamp;
import com.google.cloud.firestore.DocumentReference;
import com.google.cloud.firestore.FieldValue;
import com.google.cloud.firestore.Firestore;
import com.google.cloud.firestore.Query;
import com.google.cloud.firestore.QueryDocumentSnapshot;
import com.google.cloud.firestore.QuerySnapshot;
import com.google.cloud.firestore.WriteResult;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.time.Instant;
import java.util.ArrayList;
import java.util.Collections;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.TreeMap;
import java.util.concurrent.ExecutionException;
import java.util.concurrent.TimeUnit;
import java.util.concurrent.TimeoutException;

/**
 * Turnos del chat RAG: {@code users/{userId}/conversations/{conversationId}/messages/{autoId}}.
 * Compatibilidad: si el hilo es {@code default} y la subcolección está vacía, se lee el formato antiguo
 * {@code users/{userId}/messages}.
 */
@Service
public class ChatConversationPersistenceService {

    /** Historial + id de conversación Firestore elegido (menor N entre hilos existentes). */
    public record ResolvedChatHistory(List<ChatHistoryEntryDto> entries, String resolvedConversationId) {}

    private static final Logger log = LoggerFactory.getLogger(ChatConversationPersistenceService.class);

    static final String USERS_COLLECTION = "users";
    static final String CONVERSATIONS_SUBCOLLECTION = "conversations";
    static final String MESSAGES_SUBCOLLECTION = "messages";

    private final Firestore firestore;

    public ChatConversationPersistenceService(@Autowired(required = false) Firestore firestore) {
        this.firestore = firestore;
    }

    public List<ChatHistoryEntryDto> loadRecentTurns(String rawUserId, int limit) {
        return loadRecentTurns(rawUserId, limit, ChatConversationIds.DEFAULT);
    }

    public List<ChatHistoryEntryDto> loadRecentTurns(String rawUserId, int limit, String conversationId) {
        if (firestore == null) {
            return List.of();
        }
        if (rawUserId == null || rawUserId.isBlank()) {
            return List.of();
        }
        int lim = Math.min(Math.max(1, limit), 100);
        String uid = UserIdSanitizer.forFilesystem(rawUserId);
        String convId = sanitizeConversationId(conversationId);

        List<ChatHistoryEntryDto> rows = loadFromConversation(uid, convId, lim);
        if (rows.isEmpty() && ChatConversationIds.DEFAULT.equals(convId)) {
            rows = loadLegacyFlat(uid, lim);
        }
        return rows;
    }

    /**
     * Historial del hilo **principal**: menor {@code N} entre conversaciones existentes.
     * Sin {@code cellName} se usa el formato legado {@code usuario_hu_taskId_N}; con célula,
     * {@code usuario_celula_hu_taskId_N}.
     */
    public ResolvedChatHistory loadRecentTurnsForTaskResolved(String rawUserId, int limit, long taskId, String huCode) {
        return loadRecentTurnsForTaskResolved(rawUserId, limit, taskId, huCode, null);
    }

    /**
     * Igual que {@link #loadRecentTurnsForTaskResolved(String, int, long, String)} con nombre de célula para el id en Firestore.
     */
    public ResolvedChatHistory loadRecentTurnsForTaskResolved(
            String rawUserId, int limit, long taskId, String huCode, String cellName) {
        String id = findPrimaryConversationId(rawUserId, taskId, huCode, cellName);
        return new ResolvedChatHistory(loadRecentTurns(rawUserId, limit, id), id);
    }

    /**
     * Id de conversación a mostrar por defecto: mínimo {@code N} presente en Firestore; si no hay ninguno,
     * {@code usuario_[celula_]hu_taskId_0}.
     */
    public String findPrimaryConversationId(String rawUserId, long taskId, String huCode) {
        return findPrimaryConversationId(rawUserId, taskId, huCode, null);
    }

    public String findPrimaryConversationId(String rawUserId, long taskId, String huCode, String cellName) {
        if (firestore == null) {
            return ChatConversationIds.forUserCellHuTaskIdAndThread(rawUserId, cellName, huCode, taskId, 0);
        }
        if (rawUserId == null || rawUserId.isBlank()) {
            return ChatConversationIds.forUserCellHuTaskIdAndThread("_", cellName, huCode, taskId, 0);
        }
        String u = UserIdSanitizer.forFilesystem(rawUserId.trim());
        String t =
                (huCode == null || huCode.isBlank())
                        ? "default"
                        : UserIdSanitizer.forFilesystem(huCode.trim());
        String c =
                (cellName == null || cellName.isBlank())
                        ? null
                        : UserIdSanitizer.forFilesystem(cellName.trim());
        String legacyBase =
                (c == null || c.isBlank()) ? u + "_" + t + "_" + taskId : u + "_" + c + "_" + t + "_" + taskId;
        String threadPrefix = legacyBase + "_";

        TreeMap<Integer, String> byN = new TreeMap<>();
        try {
            ApiFuture<QuerySnapshot> future = firestore
                    .collection(USERS_COLLECTION)
                    .document(u)
                    .collection(CONVERSATIONS_SUBCOLLECTION)
                    .get();
            QuerySnapshot snap = future.get(20, TimeUnit.SECONDS);
            for (QueryDocumentSnapshot doc : snap.getDocuments()) {
                String id = doc.getId();
                if (legacyBase.equals(id)) {
                    byN.putIfAbsent(0, id);
                } else if (id.startsWith(threadPrefix)) {
                    String suffix = id.substring(threadPrefix.length());
                    if (suffix.matches("\\d+")) {
                        int n = Integer.parseInt(suffix);
                        byN.putIfAbsent(n, id);
                    }
                }
            }
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
            log.warn("Listado conversaciones Firestore interrumpido: {}", e.getMessage());
        } catch (ExecutionException | TimeoutException e) {
            log.warn("No se pudo listar conversaciones en Firestore: {}", e.getMessage());
        } catch (RuntimeException e) {
            log.warn("Error listando conversaciones en Firestore: {}", e.getMessage());
        }
        if (byN.isEmpty()) {
            return threadPrefix + "0";
        }
        return byN.firstEntry().getValue();
    }

    private List<ChatHistoryEntryDto> loadFromConversation(String uid, String convId, int lim) {
        try {
            ApiFuture<QuerySnapshot> future = firestore
                    .collection(USERS_COLLECTION)
                    .document(uid)
                    .collection(CONVERSATIONS_SUBCOLLECTION)
                    .document(convId)
                    .collection(MESSAGES_SUBCOLLECTION)
                    .orderBy("createdAt", Query.Direction.DESCENDING)
                    .limit(lim)
                    .get();
            QuerySnapshot snap = future.get(20, TimeUnit.SECONDS);
            return snapshotsToRows(snap);
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
            log.warn("Lectura historial Firestore interrumpida: {}", e.getMessage());
            return List.of();
        } catch (ExecutionException | TimeoutException e) {
            log.warn("No se pudo leer el historial en Firestore: {}", e.getMessage());
            return List.of();
        } catch (RuntimeException e) {
            log.warn("Error leyendo historial en Firestore: {}", e.getMessage());
            return List.of();
        }
    }

    /** Formato antiguo: {@code users/{uid}/messages}. */
    private List<ChatHistoryEntryDto> loadLegacyFlat(String uid, int lim) {
        try {
            ApiFuture<QuerySnapshot> future = firestore
                    .collection(USERS_COLLECTION)
                    .document(uid)
                    .collection(MESSAGES_SUBCOLLECTION)
                    .orderBy("createdAt", Query.Direction.DESCENDING)
                    .limit(lim)
                    .get();
            QuerySnapshot snap = future.get(20, TimeUnit.SECONDS);
            return snapshotsToRows(snap);
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
            return List.of();
        } catch (ExecutionException | TimeoutException | RuntimeException e) {
            log.debug("Sin historial legacy o error al leer: {}", e.toString());
            return List.of();
        }
    }

    private static List<ChatHistoryEntryDto> snapshotsToRows(QuerySnapshot snap) {
        List<ChatHistoryEntryDto> rows = new ArrayList<>();
        for (QueryDocumentSnapshot doc : snap.getDocuments()) {
            ChatHistoryEntryDto dto = new ChatHistoryEntryDto();
            dto.setId(doc.getId());
            dto.setQuestion(stringField(doc, "question"));
            dto.setAnswer(stringField(doc, "answer"));
            dto.setSources(stringListField(doc, "sources"));
            dto.setRepoLabel(stringField(doc, "repoLabel"));
            Timestamp ts = doc.getTimestamp("createdAt");
            if (ts != null) {
                Instant instant = Instant.ofEpochSecond(ts.getSeconds(), ts.getNanos());
                dto.setCreatedAt(instant.toString());
            }
            rows.add(dto);
        }
        Collections.reverse(rows);
        return rows;
    }

    private static String stringField(QueryDocumentSnapshot doc, String key) {
        Object v = doc.get(key);
        return v != null ? String.valueOf(v) : "";
    }

    @SuppressWarnings("unchecked")
    private static List<String> stringListField(QueryDocumentSnapshot doc, String key) {
        Object v = doc.get(key);
        if (v instanceof List<?> list) {
            List<String> out = new ArrayList<>();
            for (Object o : list) {
                if (o != null) {
                    out.add(String.valueOf(o));
                }
            }
            return out;
        }
        return List.of();
    }

    public void saveTurn(String rawUserId, String question, String answer, List<String> sources, String repoLabel) {
        saveTurn(rawUserId, question, answer, sources, repoLabel, ChatConversationIds.DEFAULT);
    }

    public void saveTurn(
            String rawUserId,
            String question,
            String answer,
            List<String> sources,
            String repoLabel,
            String conversationId) {
        if (firestore == null) {
            return;
        }
        if (rawUserId == null || rawUserId.isBlank()) {
            return;
        }
        try {
            String uid = UserIdSanitizer.forFilesystem(rawUserId);
            String convId = sanitizeConversationId(conversationId);
            Map<String, Object> data = new HashMap<>();
            data.put("question", question != null ? question : "");
            data.put("answer", answer != null ? answer : "");
            data.put("sources", sources != null ? sources : List.of());
            data.put("repoLabel", repoLabel != null ? repoLabel : "");
            data.put("createdAt", FieldValue.serverTimestamp());

            DocumentReference ref = firestore
                    .collection(USERS_COLLECTION)
                    .document(uid)
                    .collection(CONVERSATIONS_SUBCOLLECTION)
                    .document(convId)
                    .collection(MESSAGES_SUBCOLLECTION)
                    .document();

            ApiFuture<WriteResult> future = ref.set(data);
            future.get(12, TimeUnit.SECONDS);
            log.debug("Conversación guardada: users/{}/conversations/{}/messages/{}", uid, convId, ref.getId());
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
            log.warn("Persistencia Firestore interrumpida: {}", e.getMessage());
        } catch (ExecutionException | TimeoutException e) {
            log.warn("No se pudo guardar la conversación en Firestore: {}", e.getMessage());
        } catch (RuntimeException e) {
            log.warn("Error guardando conversación en Firestore: {}", e.getMessage());
        }
    }

    static String sanitizeConversationId(String conversationId) {
        if (conversationId == null || conversationId.isBlank()) {
            return ChatConversationIds.DEFAULT;
        }
        String s = UserIdSanitizer.forFilesystem(conversationId.trim());
        if (s.isEmpty()) {
            return ChatConversationIds.DEFAULT;
        }
        if (s.length() > 200) {
            return s.substring(0, 200);
        }
        return s;
    }
}
