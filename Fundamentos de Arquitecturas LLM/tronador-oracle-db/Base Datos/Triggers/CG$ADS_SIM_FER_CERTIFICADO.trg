CREATE OR REPLACE TRIGGER cg$ADS_SIM_FER_CERTIFICADO
AFTER DELETE ON SIM_FER_CERTIFICADO
DECLARE
    idx        BINARY_INTEGER := SIM_PCK_FER_CERTIFICADO.cg$table.FIRST;
    cg$rec   SIM_PCK_FER_CERTIFICADO.cg$row_type;
    cg$old_rec   SIM_PCK_FER_CERTIFICADO.cg$row_type;
BEGIN
--  Application_logic Pre-After-Delete-statement <<Start>>
--  Application_logic Pre-After-Delete-statement << End >>

    IF NOT (SIM_PCK_FER_CERTIFICADO.called_from_package) THEN
        WHILE idx IS NOT NULL LOOP
            cg$rec.NUMERO_CERTIFICADO := SIM_PCK_FER_CERTIFICADO.cg$table(idx).NUMERO_CERTIFICADO;
            SIM_PCK_FER_CERTIFICADO.cg$tableind(idx).NUMERO_CERTIFICADO := TRUE;
            cg$rec.CONSECUTIVO := SIM_PCK_FER_CERTIFICADO.cg$table(idx).CONSECUTIVO;
            SIM_PCK_FER_CERTIFICADO.cg$tableind(idx).CONSECUTIVO := TRUE;
            cg$rec.ESTADO_RIESGO := SIM_PCK_FER_CERTIFICADO.cg$table(idx).ESTADO_RIESGO;
            SIM_PCK_FER_CERTIFICADO.cg$tableind(idx).ESTADO_RIESGO := TRUE;

            SIM_PCK_FER_CERTIFICADO.validate_foreign_keys_del(cg$rec);
            SIM_PCK_FER_CERTIFICADO.upd_oper_denorm2( cg$rec,
                                                cg$old_rec,
                                                SIM_PCK_FER_CERTIFICADO.cg$tableind(idx),
                                                'DEL'
                                              );

            SIM_PCK_FER_CERTIFICADO.cascade_delete(cg$rec);
            SIM_PCK_FER_CERTIFICADO.domain_cascade_delete(cg$rec);

            idx := SIM_PCK_FER_CERTIFICADO.cg$table.NEXT(idx);
        END LOOP;
    END IF;

--  Application_logic Post-After-Delete-statement <<Start>>
--  Application_logic Post-After-Delete-statement << End >>

END;
/
