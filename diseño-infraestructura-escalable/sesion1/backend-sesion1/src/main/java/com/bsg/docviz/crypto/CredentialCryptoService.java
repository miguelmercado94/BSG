package com.bsg.docviz.crypto;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

import javax.crypto.Cipher;
import javax.crypto.SecretKey;
import javax.crypto.spec.GCMParameterSpec;
import javax.crypto.spec.SecretKeySpec;
import java.nio.ByteBuffer;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.security.SecureRandom;
import java.util.Base64;

/**
 * Cifrado simétrico AES-GCM para credenciales Git almacenadas en BD.
 * Clave: {@code docviz.domain.encryption-key} (Base64 de 32 bytes) o derivada por defecto (solo dev).
 */
@Service
public class CredentialCryptoService {

    private static final int GCM_IV_LENGTH = 12;
    private static final int GCM_TAG_LENGTH = 128;

    private final SecretKey secretKey;
    private final SecureRandom random = new SecureRandom();

    public CredentialCryptoService(@Value("${docviz.domain.encryption-key:}") String base64Key) {
        byte[] keyBytes;
        if (base64Key != null && !base64Key.isBlank()) {
            keyBytes = Base64.getDecoder().decode(base64Key.trim());
        } else {
            // SHA-256 → 32 bytes; sin clave en env solo para desarrollo (definir docviz.domain.encryption-key en prod)
            try {
                keyBytes = MessageDigest.getInstance("SHA-256")
                        .digest("docviz-dev-credential-key-material".getBytes(StandardCharsets.UTF_8));
            } catch (NoSuchAlgorithmException e) {
                throw new IllegalStateException(e);
            }
        }
        if (keyBytes.length != 16 && keyBytes.length != 24 && keyBytes.length != 32) {
            throw new IllegalStateException("docviz.domain.encryption-key debe decodificar a 16, 24 o 32 bytes");
        }
        this.secretKey = new SecretKeySpec(keyBytes, "AES");
    }

    public String encrypt(String plainText) {
        if (plainText == null || plainText.isEmpty()) {
            return null;
        }
        try {
            byte[] iv = new byte[GCM_IV_LENGTH];
            random.nextBytes(iv);
            Cipher cipher = Cipher.getInstance("AES/GCM/NoPadding");
            cipher.init(Cipher.ENCRYPT_MODE, secretKey, new GCMParameterSpec(GCM_TAG_LENGTH, iv));
            byte[] cipherText = cipher.doFinal(plainText.getBytes(StandardCharsets.UTF_8));
            ByteBuffer buf = ByteBuffer.allocate(iv.length + cipherText.length);
            buf.put(iv);
            buf.put(cipherText);
            return Base64.getEncoder().encodeToString(buf.array());
        } catch (Exception e) {
            throw new IllegalStateException("No se pudo cifrar credencial", e);
        }
    }

    public String decrypt(String encoded) {
        if (encoded == null || encoded.isBlank()) {
            return null;
        }
        try {
            byte[] combined = Base64.getDecoder().decode(encoded.trim());
            ByteBuffer buf = ByteBuffer.wrap(combined);
            byte[] iv = new byte[GCM_IV_LENGTH];
            buf.get(iv);
            byte[] cipherBytes = new byte[buf.remaining()];
            buf.get(cipherBytes);
            Cipher cipher = Cipher.getInstance("AES/GCM/NoPadding");
            cipher.init(Cipher.DECRYPT_MODE, secretKey, new GCMParameterSpec(GCM_TAG_LENGTH, iv));
            byte[] plain = cipher.doFinal(cipherBytes);
            return new String(plain, StandardCharsets.UTF_8);
        } catch (Exception e) {
            throw new IllegalStateException("No se pudo descifrar credencial", e);
        }
    }
}
