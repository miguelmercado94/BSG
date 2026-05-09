package com.bsg.security.config.security;

import com.bsg.security.config.security.authentication.filter.JwtAuthenticationFilter;
import com.bsg.security.exception.JsonAccessDeniedHandler;
import com.bsg.security.exception.JsonAuthenticationEntryPoint;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.http.HttpMethod;
import org.springframework.security.authorization.ReactiveAuthorizationManager;
import org.springframework.security.config.annotation.web.reactive.EnableWebFluxSecurity;
import org.springframework.security.config.web.server.ServerHttpSecurity;
import org.springframework.security.config.web.server.SecurityWebFiltersOrder;
import org.springframework.security.web.server.SecurityWebFilterChain;
import org.springframework.security.web.server.authorization.AuthorizationContext;
import org.springframework.security.web.server.context.NoOpServerSecurityContextRepository;

@Configuration
@EnableWebFluxSecurity
public class SecurityConfig {

    @Bean
    public SecurityWebFilterChain securityWebFilterChain(ServerHttpSecurity http,
                                                         JwtAuthenticationFilter jwtAuthenticationFilter,
                                                         JsonAuthenticationEntryPoint authenticationEntryPoint,
                                                         JsonAccessDeniedHandler accessDeniedHandler,
                                                         ReactiveAuthorizationManager<AuthorizationContext> authorizationManager) {
        return http
                .csrf(ServerHttpSecurity.CsrfSpec::disable)
                .securityContextRepository(NoOpServerSecurityContextRepository.getInstance())
                .exceptionHandling(ex -> ex
                        .authenticationEntryPoint(authenticationEntryPoint)
                        .accessDeniedHandler(accessDeniedHandler)
                )
                .authorizeExchange(exchanges -> exchanges
                        // CORS preflight must be unauthenticated and return 2xx.
                        .pathMatchers(HttpMethod.OPTIONS, "/**").permitAll()
                        .pathMatchers("/v3/api-docs/**", "/swagger-ui.html", "/swagger-ui/**").permitAll()
                        // Públicas (equiv. permite_all en BD); sin filas en operation en RDS el manager denegaba todo.
                        .pathMatchers(HttpMethod.GET, "/api/public/health", "/actuator/health").permitAll()
                        .pathMatchers(HttpMethod.POST,
                                "/api/v1/auth/login",
                                "/api/v1/auth/refresh",
                                "/api/v1/auth/logout",
                                "/api/v1/auth/forgot-password",
                                "/api/v1/auth/reset-password",
                                "/api/v1/customers")
                                .permitAll()
                        .pathMatchers(HttpMethod.GET, "/api/v1/auth/validate").permitAll()
                        .anyExchange().access(authorizationManager)
                )
                .httpBasic(ServerHttpSecurity.HttpBasicSpec::disable)
                .formLogin(ServerHttpSecurity.FormLoginSpec::disable)
                .addFilterAt(jwtAuthenticationFilter, SecurityWebFiltersOrder.AUTHENTICATION)
                .build();
    }
}
