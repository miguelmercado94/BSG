CREATE OR REPLACE TRIGGER cg$BDR_SIM_FER_PERSONA
BEFORE DELETE ON SIM_FER_PERSONA FOR EACH ROW
DECLARE
    cg$pk SIM_PCK_FER_PERSONA.cg$pk_type;
    cg$rec SIM_PCK_FER_PERSONA.cg$row_type;
    cg$ind SIM_PCK_FER_PERSONA.cg$ind_type;
BEGIN
--  Application_logic Pre-Before-Delete-row <<Start>>
--  Application_logic Pre-Before-Delete-row << End >>

--  Load cg$rec/cg$ind values from new

    cg$pk.NUMERO_DOCUMENTO  := :old.NUMERO_DOCUMENTO;
    cg$rec.NUMERO_DOCUMENTO := :old.NUMERO_DOCUMENTO;
    SIM_PCK_FER_PERSONA.cg$table(SIM_PCK_FER_PERSONA.idx).NUMERO_DOCUMENTO := :old.NUMERO_DOCUMENTO;
    cg$pk.TIPO_IDENTIFICACION  := :old.TIPO_IDENTIFICACION;
    cg$rec.TIPO_IDENTIFICACION := :old.TIPO_IDENTIFICACION;
    SIM_PCK_FER_PERSONA.cg$table(SIM_PCK_FER_PERSONA.idx).TIPO_IDENTIFICACION := :old.TIPO_IDENTIFICACION;


    SIM_PCK_FER_PERSONA.idx := SIM_PCK_FER_PERSONA.idx + 1;

    if not (SIM_PCK_FER_PERSONA.called_from_package) then
        SIM_PCK_FER_PERSONA.validate_domain_cascade_delete(cg$rec);
        SIM_PCK_FER_PERSONA.del(cg$pk, FALSE);
        SIM_PCK_FER_PERSONA.called_from_package := FALSE;
    end if;

--  Application_logic Post-Before-Delete-row <<Start>>
--  Application_logic Post-Before-Delete-row << End >>
END;
/
