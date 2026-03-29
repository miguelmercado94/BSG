CREATE OR REPLACE TRIGGER cg$BDS_SIM_FER_CERTIFICADO
BEFORE DELETE ON SIM_FER_CERTIFICADO
BEGIN
--  Application_logic Pre-Before-Delete-statement <<Start>>
--  Application_logic Pre-Before-Delete-statement << End >>

    SIM_PCK_FER_CERTIFICADO.cg$table.DELETE;
    SIM_PCK_FER_CERTIFICADO.cg$tableind.DELETE;
    SIM_PCK_FER_CERTIFICADO.idx := 1;

--  Application_logic Post-Before-Delete-statement <<Start>>
--  Application_logic Post-Before-Delete-statement << End >>
END;
/
