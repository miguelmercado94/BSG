CREATE OR REPLACE TRIGGER cg$AUS_SIM_FER_CERTIFICADO
AFTER UPDATE ON SIM_FER_CERTIFICADO
DECLARE
    idx        BINARY_INTEGER := SIM_PCK_FER_CERTIFICADO.cg$table.FIRST;
    cg$old_rec SIM_PCK_FER_CERTIFICADO.cg$row_type;
    cg$rec     SIM_PCK_FER_CERTIFICADO.cg$row_type;
    cg$ind     SIM_PCK_FER_CERTIFICADO.cg$ind_type;
BEGIN
--  Application_logic Pre-After-Update-statement <<Start>>
--  Application_logic Pre-After-Update-statement << End >>

    WHILE idx IS NOT NULL LOOP
        cg$old_rec.NUMERO_CERTIFICADO := SIM_PCK_FER_CERTIFICADO.cg$table(idx).NUMERO_CERTIFICADO;
        cg$old_rec.CONSECUTIVO := SIM_PCK_FER_CERTIFICADO.cg$table(idx).CONSECUTIVO;
        cg$old_rec.ESTADO_RIESGO := SIM_PCK_FER_CERTIFICADO.cg$table(idx).ESTADO_RIESGO;

    IF NOT (SIM_PCK_FER_CERTIFICADO.called_from_package) THEN
        idx := SIM_PCK_FER_CERTIFICADO.cg$table.NEXT(idx);
        cg$rec.NUMERO_CERTIFICADO := SIM_PCK_FER_CERTIFICADO.cg$table(idx).NUMERO_CERTIFICADO;
        cg$ind.NUMERO_CERTIFICADO := updating('NUMERO_CERTIFICADO');
        cg$rec.CONSECUTIVO := SIM_PCK_FER_CERTIFICADO.cg$table(idx).CONSECUTIVO;
        cg$ind.CONSECUTIVO := updating('CONSECUTIVO');
        cg$rec.ESTADO_RIESGO := SIM_PCK_FER_CERTIFICADO.cg$table(idx).ESTADO_RIESGO;
        cg$ind.ESTADO_RIESGO := updating('ESTADO_RIESGO');

        SIM_PCK_FER_CERTIFICADO.validate_foreign_keys_upd(cg$rec, cg$old_rec, cg$ind);

        SIM_PCK_FER_CERTIFICADO.upd_denorm2( cg$rec,
                                       SIM_PCK_FER_CERTIFICADO.cg$tableind(idx)
                                     );
        SIM_PCK_FER_CERTIFICADO.upd_oper_denorm2( cg$rec,
                                            cg$old_rec,
                                            SIM_PCK_FER_CERTIFICADO.cg$tableind(idx)
								                  );
        SIM_PCK_FER_CERTIFICADO.cascade_update(cg$rec, cg$old_rec);
        SIM_PCK_FER_CERTIFICADO.domain_cascade_update(cg$rec, cg$ind, cg$old_rec);

		SIM_PCK_FER_CERTIFICADO.called_from_package := FALSE;
	END IF;
        idx := SIM_PCK_FER_CERTIFICADO.cg$table.NEXT(idx);
    END LOOP;

    SIM_PCK_FER_CERTIFICADO.cg$table.DELETE;

--  Application_logic Post-After-Update-statement <<Start>>
--  Application_logic Post-After-Update-statement << End >>

END;
/
