CREATE OR REPLACE TRIGGER cg$BDR_SIM_FER_CERTIFICADO
BEFORE DELETE ON SIM_FER_CERTIFICADO FOR EACH ROW
DECLARE
    cg$pk SIM_PCK_FER_CERTIFICADO.cg$pk_type;
    cg$rec SIM_PCK_FER_CERTIFICADO.cg$row_type;
    cg$ind SIM_PCK_FER_CERTIFICADO.cg$ind_type;
BEGIN
--  Application_logic Pre-Before-Delete-row <<Start>>
--  Application_logic Pre-Before-Delete-row << End >>

--  Load cg$rec/cg$ind values from new

    cg$pk.NUMERO_CERTIFICADO  := :old.NUMERO_CERTIFICADO;
    cg$rec.NUMERO_CERTIFICADO := :old.NUMERO_CERTIFICADO;
    SIM_PCK_FER_CERTIFICADO.cg$table(SIM_PCK_FER_CERTIFICADO.idx).NUMERO_CERTIFICADO := :old.NUMERO_CERTIFICADO;


    SIM_PCK_FER_CERTIFICADO.idx := SIM_PCK_FER_CERTIFICADO.idx + 1;

    if not (SIM_PCK_FER_CERTIFICADO.called_from_package) then
        SIM_PCK_FER_CERTIFICADO.validate_domain_cascade_delete(cg$rec);
        SIM_PCK_FER_CERTIFICADO.del(cg$pk, FALSE);
        SIM_PCK_FER_CERTIFICADO.called_from_package := FALSE;
    end if;

--  Application_logic Post-Before-Delete-row <<Start>>
--  Application_logic Post-Before-Delete-row << End >>
END;
/
