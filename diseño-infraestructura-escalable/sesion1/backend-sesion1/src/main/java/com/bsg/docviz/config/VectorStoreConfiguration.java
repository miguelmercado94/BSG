package com.bsg.docviz.config;

import com.bsg.docviz.vector.PgVectorStore;
import com.bsg.docviz.vector.PineconeVectorStore;
import com.bsg.docviz.vector.VectorStore;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

import javax.sql.DataSource;

@Configuration
public class VectorStoreConfiguration {

    @Bean
    @ConditionalOnProperty(name = "docviz.vector.store", havingValue = "pgvector", matchIfMissing = true)
    public VectorStore pgVectorStore(DataSource dataSource, VectorProperties props) {
        return new PgVectorStore(dataSource, props);
    }

    @Bean
    @ConditionalOnProperty(name = "docviz.vector.store", havingValue = "pinecone")
    public VectorStore pineconeVectorStore(VectorProperties props) {
        return new PineconeVectorStore(props);
    }
}
