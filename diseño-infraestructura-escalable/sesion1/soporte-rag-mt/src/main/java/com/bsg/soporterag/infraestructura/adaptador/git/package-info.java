/**
 * Adaptadores Git de <strong>solo lectura</strong> para RAG.
 * <p>
 * No se crean, modifican ni eliminan archivos ni refs en el repositorio remoto.
 * Operaciones permitidas: comprobar conectividad ({@code ls-remote}),
 * clonar/fetch de objetos hacia un directorio temporal local y leer árboles/blobs/commits.
 */
package com.bsg.soporterag.infraestructura.adaptador.git;
