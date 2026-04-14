package com.bsg.docviz.service;

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
import java.util.concurrent.ExecutionException;
import java.util.concurrent.TimeUnit;
import java.util.concurrent.TimeoutException;

/**
 * Persiste turnos del chat RAG en Firestore: {@code users/{userId}/messages/{autoId}}.
 * El {@code userId} coincide con {@code X-DocViz-User} (sanitizado), mismo espacio de nombres que el filtro.
 * Si Firebase no está activo, no hace nada.
 */
@Service
public class ChatConversationPersistenceService {

    private static final Logger log = LoggerFactory.getLogger(ChatConversationPersistenceService.class);

    static final String USERS_COLLECTION = "users";
    static final String MESSAGES_SUBCOLLECTION = "messages";

    private final Firestore firestore;

    public ChatConversationPersistenceService(@Autowired(required = false) Firestore firestore) {
        this.firestore = firestore;
    }

    /**
     * Últimos turnos guardados, del más antiguo al más reciente (para UI y para contexto multi-turno).
     *
     * @param rawUserId mismo identificador que {@link com.bsg.docviz.security.CurrentUser} (ya sanitizado por el filtro)
     */
    public List<ChatHistoryEntryDto> loadRecentTurns(String rawUserId, int limit) {
        if (firestore == null) {
            return List.of();
        }
        if (rawUserId == null || rawUserId.isBlank()) {
            return List.of();
        }
        int lim = Math.min(Math.max(1, limit), 100);
        String uid = UserIdSanitizer.forFilesystem(rawUserId);
        try {
            ApiFuture<QuerySnapshot> future = firestore
                    .collection(USERS_COLLECTION)
                    .document(uid)
                    .collection(MESSAGES_SUBCOLLECTION)
                    .orderBy("createdAt", Query.Direction.DESCENDING)
                    .limit(lim)
                    .get();
            QuerySnapshot snap = future.get(20, TimeUnit.SECONDS);
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

    /**
     * @param rawUserId identificador tal como viene del usuario (se sanitiza para la ruta Firestore)
     */
    public void saveTurn(String rawUserId, String question, String answer, List<String> sources, String repoLabel) {
        if (firestore == null) {
            return;
        }
        if (rawUserId == null || rawUserId.isBlank()) {
            return;
        }
        try {
            String uid = UserIdSanitizer.forFilesystem(rawUserId);
            Map<String, Object> data = new HashMap<>();
            data.put("question", question != null ? question : "");
            data.put("answer", answer != null ? answer : "");
            data.put("sources", sources != null ? sources : List.of());
            data.put("repoLabel", repoLabel != null ? repoLabel : "");
            data.put("createdAt", FieldValue.serverTimestamp());

            DocumentReference ref = firestore
                    .collection(USERS_COLLECTION)
                    .document(uid)
                    .collection(MESSAGES_SUBCOLLECTION)
                    .document();

            ApiFuture<WriteResult> future = ref.set(data);
            future.get(12, TimeUnit.SECONDS);
            log.debug("Conversación guardada en Firestore: users/{}/messages/{}", uid, ref.getId());
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
            log.warn("Persistencia Firestore interrumpida: {}", e.getMessage());
        } catch (ExecutionException | TimeoutException e) {
            log.warn("No se pudo guardar la conversación en Firestore: {}", e.getMessage());
        } catch (RuntimeException e) {
            log.warn("Error guardando conversación en Firestore: {}", e.getMessage());
        }
    }
}
