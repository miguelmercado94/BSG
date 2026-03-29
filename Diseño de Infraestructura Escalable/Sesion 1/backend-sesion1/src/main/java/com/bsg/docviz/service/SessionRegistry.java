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
}
