CREATE OR REPLACE TRIGGER cg$AIS_SIM_FER_CERTIFICADO
AFTER INSERT ON SIM_FER_CERTIFICADO
DECLARE
    idx      BINARY_INTEGER := SIM_PCK_FER_CERTIFICADO.cg$table.FIRST;
    cg$rec   SIM_PCK_FER_CERTIFICADO.cg$row_type;
    cg$old_rec   SIM_PCK_FER_CERTIFICADO.cg$row_type;
    fk_check INTEGER;
BEGIN
--  Application_logic Pre-After-Insert-statement <<Start>>
--  Application_logic Pre-After-Insert-statement << End >>


    IF NOT (SIM_PCK_FER_CERTIFICADO.called_from_package) THEN
        WHILE idx IS NOT NULL LOOP
            cg$rec.NUMERO_CERTIFICADO := SIM_PCK_FER_CERTIFICADO.cg$table(idx).NUMERO_CERTIFICADO;
            cg$rec.CONSECUTIVO := SIM_PCK_FER_CERTIFICADO.cg$table(idx).CONSECUTIVO;
            cg$rec.ESTADO_RIESGO := SIM_PCK_FER_CERTIFICADO.cg$table(idx).ESTADO_RIESGO;

            SIM_PCK_FER_CERTIFICADO.validate_foreign_keys_ins(cg$rec);

            SIM_PCK_FER_CERTIFICADO.upd_oper_denorm2( cg$rec,
                                                cg$old_rec,
                                                SIM_PCK_FER_CERTIFICADO.cg$tableind(idx),
                                                'INS'
                                              );

            idx := SIM_PCK_FER_CERTIFICADO.cg$table.NEXT(idx);
        END LOOP;
    END IF;

--  Application_logic Post-After-Insert-statement <<Start>>
--  Application_logic Post-After-Insert-statement << End >>

END;
/
