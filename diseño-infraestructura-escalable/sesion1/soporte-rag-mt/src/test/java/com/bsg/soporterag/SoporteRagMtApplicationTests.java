package com.bsg.soporterag;

import com.bsg.soporterag.infraestructura.adaptador.persistencia.mongodb.repositorio.CelulaRepositorioRepositorioMongo;
import com.bsg.soporterag.infraestructura.adaptador.persistencia.mongodb.repositorio.DocumentoSoporteRepositorioMongo;
import com.bsg.soporterag.infraestructura.adaptador.persistencia.mongodb.repositorio.RepositorioRepositorioMongo;
import com.bsg.soporterag.dominio.puerto.salida.CelulaRepositorioPort;
import com.bsg.soporterag.dominio.puerto.salida.RepositorioRepositorioPort;
import org.junit.jupiter.api.Test;
import org.springframework.ai.chat.model.ChatModel;
import org.springframework.ai.embedding.EmbeddingModel;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.test.mock.mockito.MockBean;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.test.context.ActiveProfiles;

import javax.sql.DataSource;

@SpringBootTest
@ActiveProfiles("test")
class SoporteRagMtApplicationTests {

    @MockBean
    private DataSource dataSource;

    @MockBean
    private JdbcTemplate jdbcTemplate;

    @MockBean
    private DocumentoSoporteRepositorioMongo documentoSoporteRepositorioMongo;

    @MockBean
    private CelulaRepositorioRepositorioMongo celulaRepositorioRepositorioMongo;

    @MockBean
    private RepositorioRepositorioPort repositorioRepositorioPort;

    @MockBean
    private CelulaRepositorioPort celulaRepositorioPort;

    @MockBean
    private RepositorioRepositorioMongo repositorioRepositorioMongo;

    @MockBean
    private com.bsg.soporterag.dominio.puerto.salida.RepositorioGitPort repositorioGitPort;

    @MockBean
    private ChatModel chatModel;

    @MockBean
    private EmbeddingModel embeddingModel;

    @Test
    void contextoCarga() {
    }
}
