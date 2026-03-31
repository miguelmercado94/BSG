package com.bsg.docviz.service;

import com.bsg.docviz.security.CurrentUser;
import org.springframework.stereotype.Component;

import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;

@Component
public class SessionRegistry {

    private final Map<String, UserRepositoryState> byUser = new ConcurrentHashMap<>();

    public UserRepositoryState current() {
        return byUser.computeIfAbsent(CurrentUser.require(), k -> new UserRepositoryState());
    }

    /** Sin crear entrada nueva (p. ej. cierre de sesión). */
    public UserRepositoryState getIfPresent(String userId) {
        return byUser.get(userId);
    }

    public void remove(String userId) {
        byUser.remove(userId);
    }
}
