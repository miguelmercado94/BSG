CREATE OR REPLACE TRIGGER SIM_TGR_FER_PERSONA
BEFORE INSERT ON SIM_FER_PERSONA
BEGIN
--  Application_logic Pre-Before-Insert-statement <<Start>>
--  Application_logic Pre-Before-Insert-statement << End >>

    SIM_PCK_FER_PERSONA.cg$table.DELETE;
    SIM_PCK_FER_PERSONA.cg$tableind.DELETE;
    SIM_PCK_FER_PERSONA.idx := 1;

--  Application_logic Post-Before-Insert-statement <<Start>>
--  Application_logic Post-Before-Insert-statement << End >>
END;
/
