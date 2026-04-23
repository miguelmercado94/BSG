package com.bsg.docviz.config;

import org.springframework.boot.autoconfigure.condition.AnyNestedCondition;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
/**
 * Carga el cliente S3 compartido (LocalStack / AWS) si el módulo de soporte o el área de trabajo lo necesitan.
 */
public class DocvizS3ClientEnabledCondition extends AnyNestedCondition {

    public DocvizS3ClientEnabledCondition() {
        super(org.springframework.context.annotation.ConfigurationCondition.ConfigurationPhase.REGISTER_BEAN);
    }

    @ConditionalOnProperty(name = "docviz.support.enabled", havingValue = "true")
    static class SupportEnabled {}

    @ConditionalOnProperty(name = "docviz.workspace-s3.enabled", havingValue = "true")
    static class WorkspaceS3Enabled {}
}
