CREATE OR REPLACE TRIGGER SIM_TGR_FER_CERTIFICADO
BEFORE INSERT ON SIM_FER_CERTIFICADO
BEGIN
--  Application_logic Pre-Before-Insert-statement <<Start>>
--  Application_logic Pre-Before-Insert-statement << End >>

    SIM_PCK_FER_CERTIFICADO.cg$table.DELETE;
    SIM_PCK_FER_CERTIFICADO.cg$tableind.DELETE;
    SIM_PCK_FER_CERTIFICADO.idx := 1;

--  Application_logic Post-Before-Insert-statement <<Start>>
--  Application_logic Post-Before-Insert-statement << End >>
END;
/
