CREATE OR REPLACE TRIGGER cg$ADS_SIM_FER_ASEGURADO
AFTER DELETE ON SIM_FER_ASEGURADO
DECLARE
    idx        BINARY_INTEGER := SIM_PCK_FER_ASEGURADO.cg$table.FIRST;
    cg$rec   SIM_PCK_FER_ASEGURADO.cg$row_type;
    cg$old_rec   SIM_PCK_FER_ASEGURADO.cg$row_type;
BEGIN
--  Application_logic Pre-After-Delete-statement <<Start>>
--  Application_logic Pre-After-Delete-statement << End >>

    IF NOT (SIM_PCK_FER_ASEGURADO.called_from_package) THEN
        WHILE idx IS NOT NULL LOOP
            cg$rec.NUMERO_DOCUMENTO := SIM_PCK_FER_ASEGURADO.cg$table(idx).NUMERO_DOCUMENTO;
            SIM_PCK_FER_ASEGURADO.cg$tableind(idx).NUMERO_DOCUMENTO := TRUE;
            cg$rec.TIPO_IDENTIFICACION := SIM_PCK_FER_ASEGURADO.cg$table(idx).TIPO_IDENTIFICACION;
            SIM_PCK_FER_ASEGURADO.cg$tableind(idx).TIPO_IDENTIFICACION := TRUE;
            cg$rec.NUMERO_CERTIFICADO := SIM_PCK_FER_ASEGURADO.cg$table(idx).NUMERO_CERTIFICADO;
            SIM_PCK_FER_ASEGURADO.cg$tableind(idx).NUMERO_CERTIFICADO := TRUE;
            cg$rec.CONSECUTIVO := SIM_PCK_FER_ASEGURADO.cg$table(idx).CONSECUTIVO;
            SIM_PCK_FER_ASEGURADO.cg$tableind(idx).CONSECUTIVO := TRUE;
            cg$rec.NUMERO_GR := SIM_PCK_FER_ASEGURADO.cg$table(idx).NUMERO_GR;
            SIM_PCK_FER_ASEGURADO.cg$tableind(idx).NUMERO_GR := TRUE;
            cg$rec.FECHA_INICIO_VIGENCIA := SIM_PCK_FER_ASEGURADO.cg$table(idx).FECHA_INICIO_VIGENCIA;
            SIM_PCK_FER_ASEGURADO.cg$tableind(idx).FECHA_INICIO_VIGENCIA := TRUE;
            cg$rec.VALOR_ASEGURADO := SIM_PCK_FER_ASEGURADO.cg$table(idx).VALOR_ASEGURADO;
            SIM_PCK_FER_ASEGURADO.cg$tableind(idx).VALOR_ASEGURADO := TRUE;
            cg$rec.OPCION_COBERTURA := SIM_PCK_FER_ASEGURADO.cg$table(idx).OPCION_COBERTURA;
            SIM_PCK_FER_ASEGURADO.cg$tableind(idx).OPCION_COBERTURA := TRUE;
            cg$rec.PRIMA := SIM_PCK_FER_ASEGURADO.cg$table(idx).PRIMA;
            SIM_PCK_FER_ASEGURADO.cg$tableind(idx).PRIMA := TRUE;
            cg$rec.EXTRAPRIMA := SIM_PCK_FER_ASEGURADO.cg$table(idx).EXTRAPRIMA;
            SIM_PCK_FER_ASEGURADO.cg$tableind(idx).EXTRAPRIMA := TRUE;
            cg$rec.PORCENTAJE_EXTRAPRIMA := SIM_PCK_FER_ASEGURADO.cg$table(idx).PORCENTAJE_EXTRAPRIMA;
            SIM_PCK_FER_ASEGURADO.cg$tableind(idx).PORCENTAJE_EXTRAPRIMA := TRUE;
            cg$rec.TIPO_AFILIACION := SIM_PCK_FER_ASEGURADO.cg$table(idx).TIPO_AFILIACION;
            SIM_PCK_FER_ASEGURADO.cg$tableind(idx).TIPO_AFILIACION := TRUE;
            cg$rec.FECHA_CANCELACION := SIM_PCK_FER_ASEGURADO.cg$table(idx).FECHA_CANCELACION;
            SIM_PCK_FER_ASEGURADO.cg$tableind(idx).FECHA_CANCELACION := TRUE;
            cg$rec.FECHA_CREACION := SIM_PCK_FER_ASEGURADO.cg$table(idx).FECHA_CREACION;
            SIM_PCK_FER_ASEGURADO.cg$tableind(idx).FECHA_CREACION := TRUE;
            cg$rec.SUCURSAL := SIM_PCK_FER_ASEGURADO.cg$table(idx).SUCURSAL;
            SIM_PCK_FER_ASEGURADO.cg$tableind(idx).SUCURSAL := TRUE;

            SIM_PCK_FER_ASEGURADO.validate_foreign_keys_del(cg$rec);
            SIM_PCK_FER_ASEGURADO.upd_oper_denorm2( cg$rec,
                                                cg$old_rec,
                                                SIM_PCK_FER_ASEGURADO.cg$tableind(idx),
                                                'DEL'
                                              );

            SIM_PCK_FER_ASEGURADO.cascade_delete(cg$rec);
            SIM_PCK_FER_ASEGURADO.domain_cascade_delete(cg$rec);

            idx := SIM_PCK_FER_ASEGURADO.cg$table.NEXT(idx);
        END LOOP;
    END IF;

--  Application_logic Post-After-Delete-statement <<Start>>
--  Application_logic Post-After-Delete-statement << End >>

END;
/
