CREATE OR REPLACE TRIGGER cg$BDR_SIM_FER_ASEGURADO
BEFORE DELETE ON SIM_FER_ASEGURADO FOR EACH ROW
DECLARE
    cg$pk SIM_PCK_FER_ASEGURADO.cg$pk_type;
    cg$rec SIM_PCK_FER_ASEGURADO.cg$row_type;
    cg$ind SIM_PCK_FER_ASEGURADO.cg$ind_type;
BEGIN
--  Application_logic Pre-Before-Delete-row <<Start>>
--  Application_logic Pre-Before-Delete-row << End >>

--  Load cg$rec/cg$ind values from new

    cg$pk.NUMERO_CERTIFICADO  := :old.NUMERO_CERTIFICADO;
    cg$rec.NUMERO_CERTIFICADO := :old.NUMERO_CERTIFICADO;
    SIM_PCK_FER_ASEGURADO.cg$table(SIM_PCK_FER_ASEGURADO.idx).NUMERO_CERTIFICADO := :old.NUMERO_CERTIFICADO;
    cg$pk.NUMERO_DOCUMENTO  := :old.NUMERO_DOCUMENTO;
    cg$rec.NUMERO_DOCUMENTO := :old.NUMERO_DOCUMENTO;
    SIM_PCK_FER_ASEGURADO.cg$table(SIM_PCK_FER_ASEGURADO.idx).NUMERO_DOCUMENTO := :old.NUMERO_DOCUMENTO;
    cg$pk.TIPO_IDENTIFICACION  := :old.TIPO_IDENTIFICACION;
    cg$rec.TIPO_IDENTIFICACION := :old.TIPO_IDENTIFICACION;
    SIM_PCK_FER_ASEGURADO.cg$table(SIM_PCK_FER_ASEGURADO.idx).TIPO_IDENTIFICACION := :old.TIPO_IDENTIFICACION;


    SIM_PCK_FER_ASEGURADO.idx := SIM_PCK_FER_ASEGURADO.idx + 1;

    if not (SIM_PCK_FER_ASEGURADO.called_from_package) then
        SIM_PCK_FER_ASEGURADO.validate_domain_cascade_delete(cg$rec);
        SIM_PCK_FER_ASEGURADO.del(cg$pk, FALSE);
        SIM_PCK_FER_ASEGURADO.called_from_package := FALSE;
    end if;

--  Application_logic Post-Before-Delete-row <<Start>>
--  Application_logic Post-Before-Delete-row << End >>
END;
/
