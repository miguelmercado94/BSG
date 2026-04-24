package com.bsg.docviz.config;

import com.google.cloud.firestore.Firestore;
import jakarta.annotation.PostConstruct;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.core.env.Environment;
import org.springframework.stereotype.Component;

/**
 * Si Firestore está solicitado por configuración pero el bean no cargó (credenciales ausentes o ruta inválida en Docker),
 * deja una traza clara en logs.
 */
@Component
public class DocvizFirebaseStartupWarning {

    private static final Logger log = LoggerFactory.getLogger(DocvizFirebaseStartupWarning.class);

    private final Environment env;

    @Autowired(required = false)
    private Firestore firestore;

    public DocvizFirebaseStartupWarning(Environment env) {
        this.env = env;
    }

    @PostConstruct
    void warnIfMisconfigured() {
        boolean want =
                Boolean.parseBoolean(env.getProperty("docviz.firebase.enabled", "false"));
        if (!want) {
            return;
        }
        if (firestore != null) {
            log.info("DocViz: Firestore activo (historial RAG en users/{{uid}}/conversations/{{id}}/messages).");
            return;
        }
        log.warn(
                "DocViz: docviz.firebase.enabled=true pero Firestore NO está activo. "
                        + "Comprueba que exista el JSON de la cuenta de servicio y que la ruta sea válida DENTRO del proceso "
                        + "(en Docker: monta el archivo y usa p. ej. FIREBASE_CREDENTIALS_PATH=/run/secrets/firebase-adminsdk.json). "
                        + "Sin Firestore no se persisten chats ni verás documentos nuevos en la consola.");
    }
}
