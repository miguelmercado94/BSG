package com.bsg.docviz.web;

import com.bsg.docviz.service.SessionLogoutService;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/session")
public class SessionController {

    private final SessionLogoutService sessionLogoutService;

    public SessionController(SessionLogoutService sessionLogoutService) {
        this.sessionLogoutService = sessionLogoutService;
    }

    @PostMapping("/logout")
    public ResponseEntity<Void> logout() {
        sessionLogoutService.logout();
        return ResponseEntity.noContent().build();
    }
}
