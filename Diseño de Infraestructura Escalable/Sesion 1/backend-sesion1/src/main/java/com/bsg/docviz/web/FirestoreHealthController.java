package com.bsg.docviz.web;

import com.bsg.docviz.config.FirebaseProperties;
import com.google.api.core.ApiFuture;
import com.google.cloud.firestore.DocumentReference;
import com.google.cloud.firestore.DocumentSnapshot;
import com.google.cloud.firestore.FieldValue;
import com.google.cloud.firestore.Firestore;
import org.springframework.boot.autoconfigure.condition.ConditionalOnBean;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.HashMap;
import java.util.Map;
import java.util.concurrent.TimeUnit;

/**
 * Comprueba conectividad con Firestore (escribe/lee un documento en la colección {@code _system}).
 */
@RestController
@RequestMapping("/firestore")
@ConditionalOnBean(Firestore.class)
public class FirestoreHealthController {

    private static final String COLLECTION = "_system";
    private static final String DOC = "ping";

    private final Firestore firestore;
    private final FirebaseProperties firebaseProperties;

    public FirestoreHealthController(Firestore firestore, FirebaseProperties firebaseProperties) {
        this.firestore = firestore;
        this.firebaseProperties = firebaseProperties;
    }

    @GetMapping("/health")
    public ResponseEntity<Map<String, Object>> health() {
        Map<String, Object> body = new HashMap<>();
        body.put("projectId", firebaseProperties.getProjectId());
        try {
            DocumentReference ref = firestore.collection(COLLECTION).document(DOC);
            Map<String, Object> data = new HashMap<>();
            data.put("lastCheck", FieldValue.serverTimestamp());
            data.put("app", "docviz-backend");
            ApiFuture<com.google.cloud.firestore.WriteResult> write = ref.set(data);
            write.get(15, TimeUnit.SECONDS);
            ApiFuture<DocumentSnapshot> read = ref.get();
            DocumentSnapshot snap = read.get(15, TimeUnit.SECONDS);
            body.put("ok", true);
            body.put("message", "Firestore respondió correctamente (escritura + lectura).");
            body.put("documentExists", snap.exists());
            return ResponseEntity.ok(body);
        } catch (Exception e) {
            body.put("ok", false);
            body.put("error", e.getMessage());
            return ResponseEntity.status(503).body(body);
        }
    }
}
