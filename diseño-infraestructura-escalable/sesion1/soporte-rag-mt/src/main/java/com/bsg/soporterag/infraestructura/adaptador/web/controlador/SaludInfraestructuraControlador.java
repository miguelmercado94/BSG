package com.bsg.soporterag.infraestructura.adaptador.web.controlador;

import com.bsg.soporterag.aplicacion.dto.response.SaludInfraestructuraDto;
import com.bsg.soporterag.aplicacion.puerto.entrada.ConsultarSaludInfraestructuraCasoDeUso;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import reactor.core.publisher.Mono;

@RestController
@RequestMapping("/api/v1/infraestructura")
public class SaludInfraestructuraControlador {

    private final ConsultarSaludInfraestructuraCasoDeUso casoDeUso;

    public SaludInfraestructuraControlador(ConsultarSaludInfraestructuraCasoDeUso casoDeUso) {
        this.casoDeUso = casoDeUso;
    }

    @GetMapping("/salud")
    public Mono<SaludInfraestructuraDto> salud() {
        return casoDeUso.ejecutar();
    }
}
