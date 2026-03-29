CREATE OR REPLACE TRIGGER cg$BUS_SIM_FER_ASEGURADO
BEFORE UPDATE ON SIM_FER_ASEGURADO
BEGIN
--  Application_logic Pre-Before-Update-statement <<Start>>
--  Application_logic Pre-Before-Update-statement << End >>

    SIM_PCK_FER_ASEGURADO.cg$table.DELETE;
    SIM_PCK_FER_ASEGURADO.cg$tableind.DELETE;
    SIM_PCK_FER_ASEGURADO.idx := 1;

--  Application_logic Post-Before-Update-statement <<Start>>
--  Application_logic Post-Before-Update-statement << End >>

END;
/
