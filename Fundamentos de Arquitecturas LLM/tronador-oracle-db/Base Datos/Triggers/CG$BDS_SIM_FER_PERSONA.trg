CREATE OR REPLACE TRIGGER cg$BDS_SIM_FER_PERSONA
BEFORE DELETE ON SIM_FER_PERSONA
BEGIN
--  Application_logic Pre-Before-Delete-statement <<Start>>
--  Application_logic Pre-Before-Delete-statement << End >>

    SIM_PCK_FER_PERSONA.cg$table.DELETE;
    SIM_PCK_FER_PERSONA.cg$tableind.DELETE;
    SIM_PCK_FER_PERSONA.idx := 1;

--  Application_logic Post-Before-Delete-statement <<Start>>
--  Application_logic Post-Before-Delete-statement << End >>
END;
/
