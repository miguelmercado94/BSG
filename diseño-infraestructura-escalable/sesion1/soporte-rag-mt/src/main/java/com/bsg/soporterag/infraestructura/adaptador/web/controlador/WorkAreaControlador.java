package com.bsg.soporterag.infraestructura.adaptador.web.controlador;

import com.bsg.soporterag.aplicacion.servicio.ServicioBucketS3;
import com.bsg.soporterag.dominio.modelo.RolBucketS3;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.web.bind.annotation.*;
import reactor.core.publisher.Flux;
import reactor.core.publisher.Mono;

import java.util.Map;

@RestController
@RequestMapping("/api/v1/workspace")
@Tag(name = "Workspace S3", description = "API para gestionar archivos del workspace (borradores y workarea en S3)")
public class WorkAreaControlador {

    private final ServicioBucketS3 servicioBucketS3;

    public WorkAreaControlador(ServicioBucketS3 servicioBucketS3) {
        this.servicioBucketS3 = servicioBucketS3;
    }

    @Operation(summary = "Listar archivos S3", description = "Lista los archivos de un bucket (BORRADORES o WORKAREA) por prefijo. Devuelve nombre + URL presignada para cada archivo.")
    @GetMapping("/archivos")
    public Flux<Map<String, String>> listarArchivos(
            @Parameter(description = "Rol del bucket: BORRADORES o WORKAREA", required = true)
            @RequestParam("bucket") String bucket,
            @Parameter(description = "Prefijo/carpeta para filtrar (p.ej. codigoTarea/)", required = true)
            @RequestParam("prefijo") String prefijo) {

        RolBucketS3 rol = RolBucketS3.valueOf(bucket.toUpperCase());

        return servicioBucketS3.listarArchivos(rol, prefijo)
                .flatMap(clave -> servicioBucketS3.generarUrlLectura(rol, clave)
                        .map(url -> {
                            String fileName = clave.contains("/") ? clave.substring(clave.lastIndexOf("/") + 1) : clave;
                            return Map.of(
                                    "objectKey", clave,
                                    "fileName", fileName,
                                    "bucket", bucket.toLowerCase(),
                                    "url", url
                            );
                        })
                );
    }

    @Operation(summary = "Eliminar archivo S3", description = "Elimina un archivo específico de un bucket.")
    @DeleteMapping("/archivos")
    public Mono<Void> eliminarArchivo(
            @RequestParam("bucket") String bucket,
            @RequestParam("clave") String clave) {
        RolBucketS3 rol = RolBucketS3.valueOf(bucket.toUpperCase());
        return servicioBucketS3.eliminarCarpeta(rol, clave);
    }
}
