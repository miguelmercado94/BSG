package com.bsg.docviz.config;

import com.bsg.docviz.security.DocvizAuthorizationFilter;
import com.bsg.docviz.security.DocvizUserFilter;
import org.springframework.boot.web.servlet.FilterRegistrationBean;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
@Configuration
public class FilterRegistrationConfig {

    @Bean
    public DocvizUserFilter docvizUserFilter() {
        return new DocvizUserFilter();
    }

    @Bean
    public DocvizAuthorizationFilter docvizAuthorizationFilter() {
        return new DocvizAuthorizationFilter();
    }

    @Bean
    public FilterRegistrationBean<DocvizUserFilter> docvizUserFilterRegistration(DocvizUserFilter filter) {
        FilterRegistrationBean<DocvizUserFilter> reg = new FilterRegistrationBean<>(filter);
        // Después del CorsFilter de Spring para que OPTIONS reciba cabeceras CORS antes de filtros de app.
        reg.setOrder(200);
        reg.addUrlPatterns("/*");
        return reg;
    }

    @Bean
    public FilterRegistrationBean<DocvizAuthorizationFilter> docvizAuthorizationFilterRegistration(
            DocvizAuthorizationFilter filter) {
        FilterRegistrationBean<DocvizAuthorizationFilter> reg = new FilterRegistrationBean<>(filter);
        reg.setOrder(210);
        reg.addUrlPatterns("/*");
        return reg;
    }
}
