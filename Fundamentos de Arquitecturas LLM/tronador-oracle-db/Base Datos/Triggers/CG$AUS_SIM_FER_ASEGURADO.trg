CREATE OR REPLACE TRIGGER cg$AUS_SIM_FER_ASEGURADO
AFTER UPDATE ON SIM_FER_ASEGURADO
DECLARE
    idx        BINARY_INTEGER := SIM_PCK_FER_ASEGURADO.cg$table.FIRST;
    cg$old_rec SIM_PCK_FER_ASEGURADO.cg$row_type;
    cg$rec     SIM_PCK_FER_ASEGURADO.cg$row_type;
    cg$ind     SIM_PCK_FER_ASEGURADO.cg$ind_type;
BEGIN
--  Application_logic Pre-After-Update-statement <<Start>>
--  Application_logic Pre-After-Update-statement << End >>

    WHILE idx IS NOT NULL LOOP
        cg$old_rec.NUMERO_DOCUMENTO := SIM_PCK_FER_ASEGURADO.cg$table(idx).NUMERO_DOCUMENTO;
        cg$old_rec.TIPO_IDENTIFICACION := SIM_PCK_FER_ASEGURADO.cg$table(idx).TIPO_IDENTIFICACION;
        cg$old_rec.NUMERO_CERTIFICADO := SIM_PCK_FER_ASEGURADO.cg$table(idx).NUMERO_CERTIFICADO;
        cg$old_rec.CONSECUTIVO := SIM_PCK_FER_ASEGURADO.cg$table(idx).CONSECUTIVO;
        cg$old_rec.NUMERO_GR := SIM_PCK_FER_ASEGURADO.cg$table(idx).NUMERO_GR;
        cg$old_rec.FECHA_INICIO_VIGENCIA := SIM_PCK_FER_ASEGURADO.cg$table(idx).FECHA_INICIO_VIGENCIA;
        cg$old_rec.VALOR_ASEGURADO := SIM_PCK_FER_ASEGURADO.cg$table(idx).VALOR_ASEGURADO;
        cg$old_rec.OPCION_COBERTURA := SIM_PCK_FER_ASEGURADO.cg$table(idx).OPCION_COBERTURA;
        cg$old_rec.PRIMA := SIM_PCK_FER_ASEGURADO.cg$table(idx).PRIMA;
        cg$old_rec.EXTRAPRIMA := SIM_PCK_FER_ASEGURADO.cg$table(idx).EXTRAPRIMA;
        cg$old_rec.PORCENTAJE_EXTRAPRIMA := SIM_PCK_FER_ASEGURADO.cg$table(idx).PORCENTAJE_EXTRAPRIMA;
        cg$old_rec.TIPO_AFILIACION := SIM_PCK_FER_ASEGURADO.cg$table(idx).TIPO_AFILIACION;
        cg$old_rec.FECHA_CANCELACION := SIM_PCK_FER_ASEGURADO.cg$table(idx).FECHA_CANCELACION;
        cg$old_rec.FECHA_CREACION := SIM_PCK_FER_ASEGURADO.cg$table(idx).FECHA_CREACION;
        cg$old_rec.SUCURSAL := SIM_PCK_FER_ASEGURADO.cg$table(idx).SUCURSAL;

    IF NOT (SIM_PCK_FER_ASEGURADO.called_from_package) THEN
        idx := SIM_PCK_FER_ASEGURADO.cg$table.NEXT(idx);
        cg$rec.NUMERO_DOCUMENTO := SIM_PCK_FER_ASEGURADO.cg$table(idx).NUMERO_DOCUMENTO;
        cg$ind.NUMERO_DOCUMENTO := updating('NUMERO_DOCUMENTO');
        cg$rec.TIPO_IDENTIFICACION := SIM_PCK_FER_ASEGURADO.cg$table(idx).TIPO_IDENTIFICACION;
        cg$ind.TIPO_IDENTIFICACION := updating('TIPO_IDENTIFICACION');
        cg$rec.NUMERO_CERTIFICADO := SIM_PCK_FER_ASEGURADO.cg$table(idx).NUMERO_CERTIFICADO;
        cg$ind.NUMERO_CERTIFICADO := updating('NUMERO_CERTIFICADO');
        cg$rec.CONSECUTIVO := SIM_PCK_FER_ASEGURADO.cg$table(idx).CONSECUTIVO;
        cg$ind.CONSECUTIVO := updating('CONSECUTIVO');
        cg$rec.NUMERO_GR := SIM_PCK_FER_ASEGURADO.cg$table(idx).NUMERO_GR;
        cg$ind.NUMERO_GR := updating('NUMERO_GR');
        cg$rec.FECHA_INICIO_VIGENCIA := SIM_PCK_FER_ASEGURADO.cg$table(idx).FECHA_INICIO_VIGENCIA;
        cg$ind.FECHA_INICIO_VIGENCIA := updating('FECHA_INICIO_VIGENCIA');
        cg$rec.VALOR_ASEGURADO := SIM_PCK_FER_ASEGURADO.cg$table(idx).VALOR_ASEGURADO;
        cg$ind.VALOR_ASEGURADO := updating('VALOR_ASEGURADO');
        cg$rec.OPCION_COBERTURA := SIM_PCK_FER_ASEGURADO.cg$table(idx).OPCION_COBERTURA;
        cg$ind.OPCION_COBERTURA := updating('OPCION_COBERTURA');
        cg$rec.PRIMA := SIM_PCK_FER_ASEGURADO.cg$table(idx).PRIMA;
        cg$ind.PRIMA := updating('PRIMA');
        cg$rec.EXTRAPRIMA := SIM_PCK_FER_ASEGURADO.cg$table(idx).EXTRAPRIMA;
        cg$ind.EXTRAPRIMA := updating('EXTRAPRIMA');
        cg$rec.PORCENTAJE_EXTRAPRIMA := SIM_PCK_FER_ASEGURADO.cg$table(idx).PORCENTAJE_EXTRAPRIMA;
        cg$ind.PORCENTAJE_EXTRAPRIMA := updating('PORCENTAJE_EXTRAPRIMA');
        cg$rec.TIPO_AFILIACION := SIM_PCK_FER_ASEGURADO.cg$table(idx).TIPO_AFILIACION;
        cg$ind.TIPO_AFILIACION := updating('TIPO_AFILIACION');
        cg$rec.FECHA_CANCELACION := SIM_PCK_FER_ASEGURADO.cg$table(idx).FECHA_CANCELACION;
        cg$ind.FECHA_CANCELACION := updating('FECHA_CANCELACION');
        cg$rec.FECHA_CREACION := SIM_PCK_FER_ASEGURADO.cg$table(idx).FECHA_CREACION;
        cg$ind.FECHA_CREACION := updating('FECHA_CREACION');
        cg$rec.SUCURSAL := SIM_PCK_FER_ASEGURADO.cg$table(idx).SUCURSAL;
        cg$ind.SUCURSAL := updating('SUCURSAL');

        SIM_PCK_FER_ASEGURADO.validate_foreign_keys_upd(cg$rec, cg$old_rec, cg$ind);

        SIM_PCK_FER_ASEGURADO.upd_denorm2( cg$rec,
                                       SIM_PCK_FER_ASEGURADO.cg$tableind(idx)
                                     );
        SIM_PCK_FER_ASEGURADO.upd_oper_denorm2( cg$rec,
                                            cg$old_rec,
                                            SIM_PCK_FER_ASEGURADO.cg$tableind(idx)
								                  );
        SIM_PCK_FER_ASEGURADO.cascade_update(cg$rec, cg$old_rec);
        SIM_PCK_FER_ASEGURADO.domain_cascade_update(cg$rec, cg$ind, cg$old_rec);

		SIM_PCK_FER_ASEGURADO.called_from_package := FALSE;
	END IF;
        idx := SIM_PCK_FER_ASEGURADO.cg$table.NEXT(idx);
    END LOOP;

    SIM_PCK_FER_ASEGURADO.cg$table.DELETE;

--  Application_logic Post-After-Update-statement <<Start>>
--  Application_logic Post-After-Update-statement << End >>

END;
/
