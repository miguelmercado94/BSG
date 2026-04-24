package com.bsg.docviz.dto;



/**

 * Listados S3: bucket, clave del objeto, nombre corto para UI y URL presignada GET.

 */

public record S3FileUrlItem(String bucket, String objectKey, String fileName, String url) {}


