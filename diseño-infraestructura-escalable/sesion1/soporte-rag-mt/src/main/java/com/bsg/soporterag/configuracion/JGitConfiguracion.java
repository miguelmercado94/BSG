package com.bsg.soporterag.configuracion;

import com.bsg.soporterag.dominio.puerto.salida.RepositorioGitPort;
import com.bsg.soporterag.infraestructura.adaptador.git.JGitRepositorioAdaptador;
import org.springframework.boot.autoconfigure.condition.ConditionalOnMissingBean;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import reactor.core.scheduler.Scheduler;
import reactor.core.scheduler.Schedulers;

@Configuration
public class JGitConfiguracion {

    /**
     * Scheduler dedicado para aislar las operaciones bloqueantes (I/O y Red) de JGit.
     */
    @Bean(name = "gitScheduler")
    Scheduler gitScheduler() {
        int hilosMaximos = Runtime.getRuntime().availableProcessors() * 2;
        return Schedulers.newBoundedElastic(hilosMaximos, 1000, "jgit-worker");
    }

    @Bean
    @ConditionalOnMissingBean(RepositorioGitPort.class)
    RepositorioGitPort repositorioGitPort(Scheduler gitScheduler) {
        return new JGitRepositorioAdaptador(gitScheduler);
    }
}