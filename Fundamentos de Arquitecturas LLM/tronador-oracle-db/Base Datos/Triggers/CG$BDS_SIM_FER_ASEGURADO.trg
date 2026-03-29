CREATE OR REPLACE TRIGGER cg$BDS_SIM_FER_ASEGURADO
BEFORE DELETE ON SIM_FER_ASEGURADO
BEGIN
--  Application_logic Pre-Before-Delete-statement <<Start>>
--  Application_logic Pre-Before-Delete-statement << End >>

    SIM_PCK_FER_ASEGURADO.cg$table.DELETE;
    SIM_PCK_FER_ASEGURADO.cg$tableind.DELETE;
    SIM_PCK_FER_ASEGURADO.idx := 1;

--  Application_logic Post-Before-Delete-statement <<Start>>
--  Application_logic Post-Before-Delete-statement << End >>
END;
/
