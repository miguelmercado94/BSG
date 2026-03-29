CREATE OR REPLACE TRIGGER cg$AUS_SIM_FER_PERSONA
AFTER UPDATE ON SIM_FER_PERSONA
DECLARE
    idx        BINARY_INTEGER := SIM_PCK_FER_PERSONA.cg$table.FIRST;
    cg$old_rec SIM_PCK_FER_PERSONA.cg$row_type;
    cg$rec     SIM_PCK_FER_PERSONA.cg$row_type;
    cg$ind     SIM_PCK_FER_PERSONA.cg$ind_type;
BEGIN
--  Application_logic Pre-After-Update-statement <<Start>>
--  Application_logic Pre-After-Update-statement << End >>

    WHILE idx IS NOT NULL LOOP
        cg$old_rec.NUMERO_DOCUMENTO := SIM_PCK_FER_PERSONA.cg$table(idx).NUMERO_DOCUMENTO;
        cg$old_rec.TIPO_IDENTIFICACION := SIM_PCK_FER_PERSONA.cg$table(idx).TIPO_IDENTIFICACION;
        cg$old_rec.CONSECUTIVO := SIM_PCK_FER_PERSONA.cg$table(idx).CONSECUTIVO;
        cg$old_rec.PRIMER_NOMBRE := SIM_PCK_FER_PERSONA.cg$table(idx).PRIMER_NOMBRE;
        cg$old_rec.SEGUNDO_NOMBRE := SIM_PCK_FER_PERSONA.cg$table(idx).SEGUNDO_NOMBRE;
        cg$old_rec.PRIMER_APELLIDO := SIM_PCK_FER_PERSONA.cg$table(idx).PRIMER_APELLIDO;
        cg$old_rec.SEGUNDO_APELLIDO := SIM_PCK_FER_PERSONA.cg$table(idx).SEGUNDO_APELLIDO;
        cg$old_rec.SEXO := SIM_PCK_FER_PERSONA.cg$table(idx).SEXO;
        cg$old_rec.FECHA_NACIMIENTO := SIM_PCK_FER_PERSONA.cg$table(idx).FECHA_NACIMIENTO;

    IF NOT (SIM_PCK_FER_PERSONA.called_from_package) THEN
        idx := SIM_PCK_FER_PERSONA.cg$table.NEXT(idx);
        cg$rec.NUMERO_DOCUMENTO := SIM_PCK_FER_PERSONA.cg$table(idx).NUMERO_DOCUMENTO;
        cg$ind.NUMERO_DOCUMENTO := updating('NUMERO_DOCUMENTO');
        cg$rec.TIPO_IDENTIFICACION := SIM_PCK_FER_PERSONA.cg$table(idx).TIPO_IDENTIFICACION;
        cg$ind.TIPO_IDENTIFICACION := updating('TIPO_IDENTIFICACION');
        cg$rec.CONSECUTIVO := SIM_PCK_FER_PERSONA.cg$table(idx).CONSECUTIVO;
        cg$ind.CONSECUTIVO := updating('CONSECUTIVO');
        cg$rec.PRIMER_NOMBRE := SIM_PCK_FER_PERSONA.cg$table(idx).PRIMER_NOMBRE;
        cg$ind.PRIMER_NOMBRE := updating('PRIMER_NOMBRE');
        cg$rec.SEGUNDO_NOMBRE := SIM_PCK_FER_PERSONA.cg$table(idx).SEGUNDO_NOMBRE;
        cg$ind.SEGUNDO_NOMBRE := updating('SEGUNDO_NOMBRE');
        cg$rec.PRIMER_APELLIDO := SIM_PCK_FER_PERSONA.cg$table(idx).PRIMER_APELLIDO;
        cg$ind.PRIMER_APELLIDO := updating('PRIMER_APELLIDO');
        cg$rec.SEGUNDO_APELLIDO := SIM_PCK_FER_PERSONA.cg$table(idx).SEGUNDO_APELLIDO;
        cg$ind.SEGUNDO_APELLIDO := updating('SEGUNDO_APELLIDO');
        cg$rec.SEXO := SIM_PCK_FER_PERSONA.cg$table(idx).SEXO;
        cg$ind.SEXO := updating('SEXO');
        cg$rec.FECHA_NACIMIENTO := SIM_PCK_FER_PERSONA.cg$table(idx).FECHA_NACIMIENTO;
        cg$ind.FECHA_NACIMIENTO := updating('FECHA_NACIMIENTO');

        SIM_PCK_FER_PERSONA.validate_foreign_keys_upd(cg$rec, cg$old_rec, cg$ind);

        SIM_PCK_FER_PERSONA.upd_denorm2( cg$rec,
                                       SIM_PCK_FER_PERSONA.cg$tableind(idx)
                                     );
        SIM_PCK_FER_PERSONA.upd_oper_denorm2( cg$rec,
                                            cg$old_rec,
                                            SIM_PCK_FER_PERSONA.cg$tableind(idx)
								                  );
        SIM_PCK_FER_PERSONA.cascade_update(cg$rec, cg$old_rec);
        SIM_PCK_FER_PERSONA.domain_cascade_update(cg$rec, cg$ind, cg$old_rec);

		SIM_PCK_FER_PERSONA.called_from_package := FALSE;
	END IF;
        idx := SIM_PCK_FER_PERSONA.cg$table.NEXT(idx);
    END LOOP;

    SIM_PCK_FER_PERSONA.cg$table.DELETE;

--  Application_logic Post-After-Update-statement <<Start>>
--  Application_logic Post-After-Update-statement << End >>

END;
/
