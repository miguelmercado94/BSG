CREATE OR REPLACE TRIGGER cg$BIR_SIM_FER_CERTIFICADO
BEFORE INSERT ON SIM_FER_CERTIFICADO FOR EACH ROW
DECLARE
    cg$rec SIM_PCK_FER_CERTIFICADO.cg$row_type;
    cg$ind SIM_PCK_FER_CERTIFICADO.cg$ind_type;
BEGIN
--  Application_logic Pre-Before-Insert-row <<Start>>
--  Application_logic Pre-Before-Insert-row << End >>

--  Load cg$rec/cg$ind values from new

    cg$rec.NUMERO_CERTIFICADO := :new.NUMERO_CERTIFICADO;
    cg$ind.NUMERO_CERTIFICADO := TRUE;
    cg$rec.CONSECUTIVO := :new.CONSECUTIVO;
    cg$ind.CONSECUTIVO := TRUE;
    cg$rec.ESTADO_RIESGO := :new.ESTADO_RIESGO;
    cg$ind.ESTADO_RIESGO := TRUE;

    if not (SIM_PCK_FER_CERTIFICADO.called_from_package) then
        SIM_PCK_FER_CERTIFICADO.validate_arc(cg$rec);
        SIM_PCK_FER_CERTIFICADO.validate_domain(cg$rec);

        SIM_PCK_FER_CERTIFICADO.ins(cg$rec, cg$ind, FALSE);
        SIM_PCK_FER_CERTIFICADO.called_from_package := FALSE;
    end if;

    SIM_PCK_FER_CERTIFICADO.cg$table(SIM_PCK_FER_CERTIFICADO.idx).NUMERO_CERTIFICADO := cg$rec.NUMERO_CERTIFICADO;
    SIM_PCK_FER_CERTIFICADO.cg$tableind(SIM_PCK_FER_CERTIFICADO.idx).NUMERO_CERTIFICADO := cg$ind.NUMERO_CERTIFICADO;

    SIM_PCK_FER_CERTIFICADO.cg$table(SIM_PCK_FER_CERTIFICADO.idx).CONSECUTIVO := cg$rec.CONSECUTIVO;
    SIM_PCK_FER_CERTIFICADO.cg$tableind(SIM_PCK_FER_CERTIFICADO.idx).CONSECUTIVO := cg$ind.CONSECUTIVO;

    SIM_PCK_FER_CERTIFICADO.cg$table(SIM_PCK_FER_CERTIFICADO.idx).ESTADO_RIESGO := cg$rec.ESTADO_RIESGO;
    SIM_PCK_FER_CERTIFICADO.cg$tableind(SIM_PCK_FER_CERTIFICADO.idx).ESTADO_RIESGO := cg$ind.ESTADO_RIESGO;

    SIM_PCK_FER_CERTIFICADO.idx := SIM_PCK_FER_CERTIFICADO.idx + 1;

    :new.NUMERO_CERTIFICADO := cg$rec.NUMERO_CERTIFICADO;
    :new.CONSECUTIVO := cg$rec.CONSECUTIVO;
    :new.ESTADO_RIESGO := cg$rec.ESTADO_RIESGO;

--  Application_logic Post-Before-Insert-row <<Start>>
--  Application_logic Post-Before-Insert-row << End >>
END;
/
