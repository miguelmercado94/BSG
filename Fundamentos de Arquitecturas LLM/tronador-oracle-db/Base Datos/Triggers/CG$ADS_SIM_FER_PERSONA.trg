CREATE OR REPLACE TRIGGER cg$ADS_SIM_FER_PERSONA
AFTER DELETE ON SIM_FER_PERSONA
DECLARE
    idx        BINARY_INTEGER := SIM_PCK_FER_PERSONA.cg$table.FIRST;
    cg$rec   SIM_PCK_FER_PERSONA.cg$row_type;
    cg$old_rec   SIM_PCK_FER_PERSONA.cg$row_type;
BEGIN
--  Application_logic Pre-After-Delete-statement <<Start>>
--  Application_logic Pre-After-Delete-statement << End >>

    IF NOT (SIM_PCK_FER_PERSONA.called_from_package) THEN
        WHILE idx IS NOT NULL LOOP
            cg$rec.NUMERO_DOCUMENTO := SIM_PCK_FER_PERSONA.cg$table(idx).NUMERO_DOCUMENTO;
            SIM_PCK_FER_PERSONA.cg$tableind(idx).NUMERO_DOCUMENTO := TRUE;
            cg$rec.TIPO_IDENTIFICACION := SIM_PCK_FER_PERSONA.cg$table(idx).TIPO_IDENTIFICACION;
            SIM_PCK_FER_PERSONA.cg$tableind(idx).TIPO_IDENTIFICACION := TRUE;
            cg$rec.CONSECUTIVO := SIM_PCK_FER_PERSONA.cg$table(idx).CONSECUTIVO;
            SIM_PCK_FER_PERSONA.cg$tableind(idx).CONSECUTIVO := TRUE;
            cg$rec.PRIMER_NOMBRE := SIM_PCK_FER_PERSONA.cg$table(idx).PRIMER_NOMBRE;
            SIM_PCK_FER_PERSONA.cg$tableind(idx).PRIMER_NOMBRE := TRUE;
            cg$rec.SEGUNDO_NOMBRE := SIM_PCK_FER_PERSONA.cg$table(idx).SEGUNDO_NOMBRE;
            SIM_PCK_FER_PERSONA.cg$tableind(idx).SEGUNDO_NOMBRE := TRUE;
            cg$rec.PRIMER_APELLIDO := SIM_PCK_FER_PERSONA.cg$table(idx).PRIMER_APELLIDO;
            SIM_PCK_FER_PERSONA.cg$tableind(idx).PRIMER_APELLIDO := TRUE;
            cg$rec.SEGUNDO_APELLIDO := SIM_PCK_FER_PERSONA.cg$table(idx).SEGUNDO_APELLIDO;
            SIM_PCK_FER_PERSONA.cg$tableind(idx).SEGUNDO_APELLIDO := TRUE;
            cg$rec.SEXO := SIM_PCK_FER_PERSONA.cg$table(idx).SEXO;
            SIM_PCK_FER_PERSONA.cg$tableind(idx).SEXO := TRUE;
            cg$rec.FECHA_NACIMIENTO := SIM_PCK_FER_PERSONA.cg$table(idx).FECHA_NACIMIENTO;
            SIM_PCK_FER_PERSONA.cg$tableind(idx).FECHA_NACIMIENTO := TRUE;

            SIM_PCK_FER_PERSONA.validate_foreign_keys_del(cg$rec);
            SIM_PCK_FER_PERSONA.upd_oper_denorm2( cg$rec,
                                                cg$old_rec,
                                                SIM_PCK_FER_PERSONA.cg$tableind(idx),
                                                'DEL'
                                              );

            SIM_PCK_FER_PERSONA.cascade_delete(cg$rec);
            SIM_PCK_FER_PERSONA.domain_cascade_delete(cg$rec);

            idx := SIM_PCK_FER_PERSONA.cg$table.NEXT(idx);
        END LOOP;
    END IF;

--  Application_logic Post-After-Delete-statement <<Start>>
--  Application_logic Post-After-Delete-statement << End >>

END;
/
