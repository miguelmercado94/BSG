CREATE OR REPLACE TRIGGER SIM_TGR_FER_ASEGURADO
BEFORE INSERT ON SIM_FER_ASEGURADO
BEGIN
--  Application_logic Pre-Before-Insert-statement <<Start>>
--  Application_logic Pre-Before-Insert-statement << End >>

    SIM_PCK_FER_ASEGURADO.cg$table.DELETE;
    SIM_PCK_FER_ASEGURADO.cg$tableind.DELETE;
    SIM_PCK_FER_ASEGURADO.idx := 1;

--  Application_logic Post-Before-Insert-statement <<Start>>
--  Application_logic Post-Before-Insert-statement << End >>
END;
/
