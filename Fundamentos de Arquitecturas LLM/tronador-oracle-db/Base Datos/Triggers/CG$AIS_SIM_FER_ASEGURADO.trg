CREATE OR REPLACE TRIGGER cg$AIS_SIM_FER_ASEGURADO
AFTER INSERT ON SIM_FER_ASEGURADO
DECLARE
    idx      BINARY_INTEGER := SIM_PCK_FER_ASEGURADO.cg$table.FIRST;
    cg$rec   SIM_PCK_FER_ASEGURADO.cg$row_type;
    cg$old_rec   SIM_PCK_FER_ASEGURADO.cg$row_type;
    fk_check INTEGER;
BEGIN
--  Application_logic Pre-After-Insert-statement <<Start>>
--  Application_logic Pre-After-Insert-statement << End >>


    IF NOT (SIM_PCK_FER_ASEGURADO.called_from_package) THEN
        WHILE idx IS NOT NULL LOOP
            cg$rec.NUMERO_DOCUMENTO := SIM_PCK_FER_ASEGURADO.cg$table(idx).NUMERO_DOCUMENTO;
            cg$rec.TIPO_IDENTIFICACION := SIM_PCK_FER_ASEGURADO.cg$table(idx).TIPO_IDENTIFICACION;
            cg$rec.NUMERO_CERTIFICADO := SIM_PCK_FER_ASEGURADO.cg$table(idx).NUMERO_CERTIFICADO;
            cg$rec.CONSECUTIVO := SIM_PCK_FER_ASEGURADO.cg$table(idx).CONSECUTIVO;
            cg$rec.NUMERO_GR := SIM_PCK_FER_ASEGURADO.cg$table(idx).NUMERO_GR;
            cg$rec.FECHA_INICIO_VIGENCIA := SIM_PCK_FER_ASEGURADO.cg$table(idx).FECHA_INICIO_VIGENCIA;
            cg$rec.VALOR_ASEGURADO := SIM_PCK_FER_ASEGURADO.cg$table(idx).VALOR_ASEGURADO;
            cg$rec.OPCION_COBERTURA := SIM_PCK_FER_ASEGURADO.cg$table(idx).OPCION_COBERTURA;
            cg$rec.PRIMA := SIM_PCK_FER_ASEGURADO.cg$table(idx).PRIMA;
            cg$rec.EXTRAPRIMA := SIM_PCK_FER_ASEGURADO.cg$table(idx).EXTRAPRIMA;
            cg$rec.PORCENTAJE_EXTRAPRIMA := SIM_PCK_FER_ASEGURADO.cg$table(idx).PORCENTAJE_EXTRAPRIMA;
            cg$rec.TIPO_AFILIACION := SIM_PCK_FER_ASEGURADO.cg$table(idx).TIPO_AFILIACION;
            cg$rec.FECHA_CANCELACION := SIM_PCK_FER_ASEGURADO.cg$table(idx).FECHA_CANCELACION;
            cg$rec.FECHA_CREACION := SIM_PCK_FER_ASEGURADO.cg$table(idx).FECHA_CREACION;
            cg$rec.SUCURSAL := SIM_PCK_FER_ASEGURADO.cg$table(idx).SUCURSAL;

            SIM_PCK_FER_ASEGURADO.validate_foreign_keys_ins(cg$rec);

            SIM_PCK_FER_ASEGURADO.upd_oper_denorm2( cg$rec,
                                                cg$old_rec,
                                                SIM_PCK_FER_ASEGURADO.cg$tableind(idx),
                                                'INS'
                                              );

            idx := SIM_PCK_FER_ASEGURADO.cg$table.NEXT(idx);
        END LOOP;
    END IF;

--  Application_logic Post-After-Insert-statement <<Start>>
--  Application_logic Post-After-Insert-statement << End >>

END;
/
