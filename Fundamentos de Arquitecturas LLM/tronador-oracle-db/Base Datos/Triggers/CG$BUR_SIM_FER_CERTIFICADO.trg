CREATE OR REPLACE TRIGGER cg$BUR_SIM_FER_CERTIFICADO
BEFORE UPDATE ON SIM_FER_CERTIFICADO FOR EACH ROW
DECLARE
    cg$rec     SIM_PCK_FER_CERTIFICADO.cg$row_type;
    cg$ind     SIM_PCK_FER_CERTIFICADO.cg$ind_type;
    cg$old_rec SIM_PCK_FER_CERTIFICADO.cg$row_type;
BEGIN
--  Application_logic Pre-Before-Update-row <<Start>>
--  Application_logic Pre-Before-Update-row << End >>

--  Load cg$rec/cg$ind values from new

    cg$rec.NUMERO_CERTIFICADO := :new.NUMERO_CERTIFICADO;
    cg$ind.NUMERO_CERTIFICADO :=    (:new.NUMERO_CERTIFICADO IS NULL AND :old.NUMERO_CERTIFICADO IS NOT NULL )
                        OR (:new.NUMERO_CERTIFICADO IS NOT NULL AND :old.NUMERO_CERTIFICADO IS NULL)
                        OR NOT(:new.NUMERO_CERTIFICADO = :old.NUMERO_CERTIFICADO) ;
    SIM_PCK_FER_CERTIFICADO.cg$table(SIM_PCK_FER_CERTIFICADO.idx).NUMERO_CERTIFICADO := :old.NUMERO_CERTIFICADO;
    cg$rec.CONSECUTIVO := :new.CONSECUTIVO;
    cg$ind.CONSECUTIVO :=    (:new.CONSECUTIVO IS NULL AND :old.CONSECUTIVO IS NOT NULL )
                        OR (:new.CONSECUTIVO IS NOT NULL AND :old.CONSECUTIVO IS NULL)
                        OR NOT(:new.CONSECUTIVO = :old.CONSECUTIVO) ;
    SIM_PCK_FER_CERTIFICADO.cg$table(SIM_PCK_FER_CERTIFICADO.idx).CONSECUTIVO := :old.CONSECUTIVO;
    cg$rec.ESTADO_RIESGO := :new.ESTADO_RIESGO;
    cg$ind.ESTADO_RIESGO :=    (:new.ESTADO_RIESGO IS NULL AND :old.ESTADO_RIESGO IS NOT NULL )
                        OR (:new.ESTADO_RIESGO IS NOT NULL AND :old.ESTADO_RIESGO IS NULL)
                        OR NOT(:new.ESTADO_RIESGO = :old.ESTADO_RIESGO) ;
    SIM_PCK_FER_CERTIFICADO.cg$table(SIM_PCK_FER_CERTIFICADO.idx).ESTADO_RIESGO := :old.ESTADO_RIESGO;


    SIM_PCK_FER_CERTIFICADO.idx := SIM_PCK_FER_CERTIFICADO.idx + 1;

    if not (SIM_PCK_FER_CERTIFICADO.called_from_package) then
        SIM_PCK_FER_CERTIFICADO.validate_arc(cg$rec);
        SIM_PCK_FER_CERTIFICADO.validate_domain(cg$rec, cg$ind);
        SIM_PCK_FER_CERTIFICADO.validate_domain_cascade_update(cg$old_rec);

        SIM_PCK_FER_CERTIFICADO.upd(cg$rec, cg$ind, FALSE);
        SIM_PCK_FER_CERTIFICADO.called_from_package := FALSE;
    end if;

    :new.CONSECUTIVO := cg$rec.CONSECUTIVO;
    :new.ESTADO_RIESGO := cg$rec.ESTADO_RIESGO;
--  Application_logic Post-Before-Update-row <<Start>>
--  Application_logic Post-Before-Update-row << End >>
END;
/
