package com.bsg.soporterag.aplicacion.servicio.impl;

import com.bsg.soporterag.aplicacion.servicio.ServicioDeParches;
import com.bsg.soporterag.infraestructura.adaptador.ia.model.CambioPropuestoDtoIa;
import com.bsg.soporterag.infraestructura.adaptador.ia.model.PropuestaModificacionArchivoDtoIa;
import org.eclipse.jgit.diff.DiffFormatter;
import org.eclipse.jgit.diff.EditList;
import org.eclipse.jgit.diff.HistogramDiff;
import org.eclipse.jgit.diff.RawText;
import org.eclipse.jgit.diff.RawTextComparator;
import org.springframework.stereotype.Service;
import reactor.core.publisher.Mono;

import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.util.Arrays;
import java.util.LinkedList;
import java.util.List;

@Service
public class ServicioDeParchesImpl implements ServicioDeParches {

    @Override
    public Mono<String> generarDiff(PropuestaModificacionArchivoDtoIa propuesta, String contenidoOriginal) {
        return Mono.fromCallable(() -> {
            List<String> lineasOriginales = new LinkedList<>(Arrays.asList(contenidoOriginal.split("\n")));
            List<String> lineasModificadas = aplicarCambios(lineasOriginales, propuesta.getCambios());

            String originalConSaltos = String.join("\n", lineasOriginales);
            String modificadoConSaltos = String.join("\n", lineasModificadas);

            return crearDiffConJGit(propuesta.getFilePath(), originalConSaltos, modificadoConSaltos);
        });
    }

    private List<String> aplicarCambios(List<String> lineasOriginales, List<CambioPropuestoDtoIa> cambios) {
        // La lista de cambios ya viene ordenada de abajo hacia arriba
        for (CambioPropuestoDtoIa cambio : cambios) {
            int lineaInicial = cambio.getLineaInicial() - 1; // Ajuste a índice 0
            int lineaFinal = cambio.getLineaFinal() - 1;

            switch (cambio.getOperacion()) {
                case DELETE:
                    if (lineaInicial >= 0 && lineaFinal < lineasOriginales.size()) {
                        lineasOriginales.subList(lineaInicial, lineaFinal + 1).clear();
                    }
                    break;
                case UPDATE:
                    if (lineaInicial >= 0 && lineaFinal < lineasOriginales.size()) {
                        lineasOriginales.subList(lineaInicial, lineaFinal + 1).clear();
                        lineasOriginales.addAll(lineaInicial, cambio.getNuevasLineas());
                    }
                    break;
                case INSERT:
                    if (lineaInicial >= 0 && lineaInicial <= lineasOriginales.size()) {
                        lineasOriginales.addAll(lineaInicial, cambio.getNuevasLineas());
                    }
                    break;
            }
        }
        return lineasOriginales;
    }

    private String crearDiffConJGit(String filePath, String original, String modificado) throws IOException {
        RawText textoOriginal = new RawText(original.getBytes());
        RawText textoModificado = new RawText(modificado.getBytes());

        EditList diffList = new HistogramDiff().diff(RawTextComparator.DEFAULT, textoOriginal, textoModificado);

        try (ByteArrayOutputStream out = new ByteArrayOutputStream()) {
            try (DiffFormatter formatter = new DiffFormatter(out)) {
                formatter.format(diffList, textoOriginal, textoModificado);
            }
            
            String diffHeader = String.format("diff --git a/%s b/%s\n--- a/%s\n+++ b/%s\n", filePath, filePath, filePath, filePath);
            return diffHeader + out.toString();
        }
    }
}
