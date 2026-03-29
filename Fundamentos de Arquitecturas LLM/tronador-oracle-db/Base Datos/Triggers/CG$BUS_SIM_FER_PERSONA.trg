CREATE OR REPLACE TRIGGER cg$BUS_SIM_FER_PERSONA
BEFORE UPDATE ON SIM_FER_PERSONA
BEGIN
--  Application_logic Pre-Before-Update-statement <<Start>>
--  Application_logic Pre-Before-Update-statement << End >>

    SIM_PCK_FER_PERSONA.cg$table.DELETE;
    SIM_PCK_FER_PERSONA.cg$tableind.DELETE;
    SIM_PCK_FER_PERSONA.idx := 1;

--  Application_logic Post-Before-Update-statement <<Start>>
--  Application_logic Post-Before-Update-statement << End >>

END;
/
