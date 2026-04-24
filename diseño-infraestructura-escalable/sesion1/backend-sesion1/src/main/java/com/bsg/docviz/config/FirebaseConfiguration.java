package com.bsg.docviz.config;

import com.google.auth.oauth2.GoogleCredentials;
import com.google.cloud.firestore.Firestore;
import com.google.firebase.FirebaseApp;
import com.google.firebase.FirebaseOptions;
import com.google.firebase.cloud.FirestoreClient;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Conditional;
import org.springframework.context.annotation.Configuration;

import java.io.IOException;
import java.io.InputStream;
import java.nio.file.Files;
import java.nio.file.Path;

@Configuration
@Conditional(FirebaseOnCredentialsPresentCondition.class)
public class FirebaseConfiguration {

    @Bean
    public FirebaseApp firebaseApp(FirebaseProperties props) throws IOException {
        if (!FirebaseApp.getApps().isEmpty()) {
            return FirebaseApp.getInstance();
        }
        String credPath = resolveCredentialsPath(props);
        if (credPath.isBlank()) {
            throw new IllegalStateException(
                    "Firebase activado: define docviz.firebase.credentials-path o la variable GOOGLE_APPLICATION_CREDENTIALS con la ruta al JSON de la cuenta de servicio.");
        }
        Path p = Path.of(credPath);
        if (!Files.isRegularFile(p)) {
            throw new IllegalStateException("No se encuentra el archivo de credenciales Firebase: " + p.toAbsolutePath());
        }
        try (InputStream in = Files.newInputStream(p)) {
            FirebaseOptions options = FirebaseOptions.builder()
                    .setCredentials(GoogleCredentials.fromStream(in))
                    .setProjectId(props.getProjectId())
                    .build();
            return FirebaseApp.initializeApp(options);
        }
    }

    @Bean
    public Firestore firestore(FirebaseApp app) {
        return FirestoreClient.getFirestore(app);
    }

    private static String resolveCredentialsPath(FirebaseProperties props) {
        if (props.getCredentialsPath() != null && !props.getCredentialsPath().isBlank()) {
            return props.getCredentialsPath();
        }
        String env = System.getenv("GOOGLE_APPLICATION_CREDENTIALS");
        return env != null ? env.trim() : "";
    }
}
