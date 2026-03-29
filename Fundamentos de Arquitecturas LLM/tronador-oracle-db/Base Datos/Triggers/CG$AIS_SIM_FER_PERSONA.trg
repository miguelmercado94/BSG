CREATE OR REPLACE TRIGGER cg$AIS_SIM_FER_PERSONA
AFTER INSERT ON SIM_FER_PERSONA
DECLARE
    idx      BINARY_INTEGER := SIM_PCK_FER_PERSONA.cg$table.FIRST;
    cg$rec   SIM_PCK_FER_PERSONA.cg$row_type;
    cg$old_rec   SIM_PCK_FER_PERSONA.cg$row_type;
    fk_check INTEGER;
BEGIN
--  Application_logic Pre-After-Insert-statement <<Start>>
--  Application_logic Pre-After-Insert-statement << End >>


    IF NOT (SIM_PCK_FER_PERSONA.called_from_package) THEN
        WHILE idx IS NOT NULL LOOP
            cg$rec.NUMERO_DOCUMENTO := SIM_PCK_FER_PERSONA.cg$table(idx).NUMERO_DOCUMENTO;
            cg$rec.TIPO_IDENTIFICACION := SIM_PCK_FER_PERSONA.cg$table(idx).TIPO_IDENTIFICACION;
            cg$rec.CONSECUTIVO := SIM_PCK_FER_PERSONA.cg$table(idx).CONSECUTIVO;
            cg$rec.PRIMER_NOMBRE := SIM_PCK_FER_PERSONA.cg$table(idx).PRIMER_NOMBRE;
            cg$rec.SEGUNDO_NOMBRE := SIM_PCK_FER_PERSONA.cg$table(idx).SEGUNDO_NOMBRE;
            cg$rec.PRIMER_APELLIDO := SIM_PCK_FER_PERSONA.cg$table(idx).PRIMER_APELLIDO;
            cg$rec.SEGUNDO_APELLIDO := SIM_PCK_FER_PERSONA.cg$table(idx).SEGUNDO_APELLIDO;
            cg$rec.SEXO := SIM_PCK_FER_PERSONA.cg$table(idx).SEXO;
            cg$rec.FECHA_NACIMIENTO := SIM_PCK_FER_PERSONA.cg$table(idx).FECHA_NACIMIENTO;

            SIM_PCK_FER_PERSONA.validate_foreign_keys_ins(cg$rec);

            SIM_PCK_FER_PERSONA.upd_oper_denorm2( cg$rec,
                                                cg$old_rec,
                                                SIM_PCK_FER_PERSONA.cg$tableind(idx),
                                                'INS'
                                              );

            idx := SIM_PCK_FER_PERSONA.cg$table.NEXT(idx);
        END LOOP;
    END IF;

--  Application_logic Post-After-Insert-statement <<Start>>
--  Application_logic Post-After-Insert-statement << End >>

END;
/
