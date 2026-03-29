CREATE OR REPLACE TRIGGER cg$BUS_SIM_FER_CERTIFICADO
BEFORE UPDATE ON SIM_FER_CERTIFICADO
BEGIN
--  Application_logic Pre-Before-Update-statement <<Start>>
--  Application_logic Pre-Before-Update-statement << End >>

    SIM_PCK_FER_CERTIFICADO.cg$table.DELETE;
    SIM_PCK_FER_CERTIFICADO.cg$tableind.DELETE;
    SIM_PCK_FER_CERTIFICADO.idx := 1;

--  Application_logic Post-Before-Update-statement <<Start>>
--  Application_logic Post-Before-Update-statement << End >>

END;
/
