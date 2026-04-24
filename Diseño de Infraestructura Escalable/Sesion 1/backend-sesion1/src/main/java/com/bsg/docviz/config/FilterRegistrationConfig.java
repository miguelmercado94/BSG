package com.bsg.docviz.config;

import com.bsg.docviz.security.DocvizAuthorizationFilter;
import com.bsg.docviz.security.DocvizUserFilter;
import org.springframework.boot.web.servlet.FilterRegistrationBean;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.core.Ordered;

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
        reg.setOrder(Ordered.HIGHEST_PRECEDENCE);
        reg.addUrlPatterns("/*");
        return reg;
    }

    @Bean
    public FilterRegistrationBean<DocvizAuthorizationFilter> docvizAuthorizationFilterRegistration(
            DocvizAuthorizationFilter filter) {
        FilterRegistrationBean<DocvizAuthorizationFilter> reg = new FilterRegistrationBean<>(filter);
        reg.setOrder(Ordered.HIGHEST_PRECEDENCE + 10);
        reg.addUrlPatterns("/*");
        return reg;
    }
}
