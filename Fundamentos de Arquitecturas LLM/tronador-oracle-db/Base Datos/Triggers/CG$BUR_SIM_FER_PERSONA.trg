CREATE OR REPLACE TRIGGER cg$BUR_SIM_FER_PERSONA
BEFORE UPDATE ON SIM_FER_PERSONA FOR EACH ROW
DECLARE
    cg$rec     SIM_PCK_FER_PERSONA.cg$row_type;
    cg$ind     SIM_PCK_FER_PERSONA.cg$ind_type;
    cg$old_rec SIM_PCK_FER_PERSONA.cg$row_type;
BEGIN
--  Application_logic Pre-Before-Update-row <<Start>>
--  Application_logic Pre-Before-Update-row << End >>

--  Load cg$rec/cg$ind values from new

    cg$rec.NUMERO_DOCUMENTO := :new.NUMERO_DOCUMENTO;
    cg$ind.NUMERO_DOCUMENTO :=    (:new.NUMERO_DOCUMENTO IS NULL AND :old.NUMERO_DOCUMENTO IS NOT NULL )
                        OR (:new.NUMERO_DOCUMENTO IS NOT NULL AND :old.NUMERO_DOCUMENTO IS NULL)
                        OR NOT(:new.NUMERO_DOCUMENTO = :old.NUMERO_DOCUMENTO) ;
    SIM_PCK_FER_PERSONA.cg$table(SIM_PCK_FER_PERSONA.idx).NUMERO_DOCUMENTO := :old.NUMERO_DOCUMENTO;
    cg$rec.TIPO_IDENTIFICACION := :new.TIPO_IDENTIFICACION;
    cg$ind.TIPO_IDENTIFICACION :=    (:new.TIPO_IDENTIFICACION IS NULL AND :old.TIPO_IDENTIFICACION IS NOT NULL )
                        OR (:new.TIPO_IDENTIFICACION IS NOT NULL AND :old.TIPO_IDENTIFICACION IS NULL)
                        OR NOT(:new.TIPO_IDENTIFICACION = :old.TIPO_IDENTIFICACION) ;
    SIM_PCK_FER_PERSONA.cg$table(SIM_PCK_FER_PERSONA.idx).TIPO_IDENTIFICACION := :old.TIPO_IDENTIFICACION;
    cg$rec.CONSECUTIVO := :new.CONSECUTIVO;
    cg$ind.CONSECUTIVO :=    (:new.CONSECUTIVO IS NULL AND :old.CONSECUTIVO IS NOT NULL )
                        OR (:new.CONSECUTIVO IS NOT NULL AND :old.CONSECUTIVO IS NULL)
                        OR NOT(:new.CONSECUTIVO = :old.CONSECUTIVO) ;
    SIM_PCK_FER_PERSONA.cg$table(SIM_PCK_FER_PERSONA.idx).CONSECUTIVO := :old.CONSECUTIVO;
    cg$rec.PRIMER_NOMBRE := :new.PRIMER_NOMBRE;
    cg$ind.PRIMER_NOMBRE :=    (:new.PRIMER_NOMBRE IS NULL AND :old.PRIMER_NOMBRE IS NOT NULL )
                        OR (:new.PRIMER_NOMBRE IS NOT NULL AND :old.PRIMER_NOMBRE IS NULL)
                        OR NOT(:new.PRIMER_NOMBRE = :old.PRIMER_NOMBRE) ;
    SIM_PCK_FER_PERSONA.cg$table(SIM_PCK_FER_PERSONA.idx).PRIMER_NOMBRE := :old.PRIMER_NOMBRE;
    cg$rec.SEGUNDO_NOMBRE := :new.SEGUNDO_NOMBRE;
    cg$ind.SEGUNDO_NOMBRE :=    (:new.SEGUNDO_NOMBRE IS NULL AND :old.SEGUNDO_NOMBRE IS NOT NULL )
                        OR (:new.SEGUNDO_NOMBRE IS NOT NULL AND :old.SEGUNDO_NOMBRE IS NULL)
                        OR NOT(:new.SEGUNDO_NOMBRE = :old.SEGUNDO_NOMBRE) ;
    SIM_PCK_FER_PERSONA.cg$table(SIM_PCK_FER_PERSONA.idx).SEGUNDO_NOMBRE := :old.SEGUNDO_NOMBRE;
    cg$rec.PRIMER_APELLIDO := :new.PRIMER_APELLIDO;
    cg$ind.PRIMER_APELLIDO :=    (:new.PRIMER_APELLIDO IS NULL AND :old.PRIMER_APELLIDO IS NOT NULL )
                        OR (:new.PRIMER_APELLIDO IS NOT NULL AND :old.PRIMER_APELLIDO IS NULL)
                        OR NOT(:new.PRIMER_APELLIDO = :old.PRIMER_APELLIDO) ;
    SIM_PCK_FER_PERSONA.cg$table(SIM_PCK_FER_PERSONA.idx).PRIMER_APELLIDO := :old.PRIMER_APELLIDO;
    cg$rec.SEGUNDO_APELLIDO := :new.SEGUNDO_APELLIDO;
    cg$ind.SEGUNDO_APELLIDO :=    (:new.SEGUNDO_APELLIDO IS NULL AND :old.SEGUNDO_APELLIDO IS NOT NULL )
                        OR (:new.SEGUNDO_APELLIDO IS NOT NULL AND :old.SEGUNDO_APELLIDO IS NULL)
                        OR NOT(:new.SEGUNDO_APELLIDO = :old.SEGUNDO_APELLIDO) ;
    SIM_PCK_FER_PERSONA.cg$table(SIM_PCK_FER_PERSONA.idx).SEGUNDO_APELLIDO := :old.SEGUNDO_APELLIDO;
    cg$rec.SEXO := :new.SEXO;
    cg$ind.SEXO :=    (:new.SEXO IS NULL AND :old.SEXO IS NOT NULL )
                        OR (:new.SEXO IS NOT NULL AND :old.SEXO IS NULL)
                        OR NOT(:new.SEXO = :old.SEXO) ;
    SIM_PCK_FER_PERSONA.cg$table(SIM_PCK_FER_PERSONA.idx).SEXO := :old.SEXO;
    cg$rec.FECHA_NACIMIENTO := :new.FECHA_NACIMIENTO;
    cg$ind.FECHA_NACIMIENTO :=    (:new.FECHA_NACIMIENTO IS NULL AND :old.FECHA_NACIMIENTO IS NOT NULL )
                        OR (:new.FECHA_NACIMIENTO IS NOT NULL AND :old.FECHA_NACIMIENTO IS NULL)
                        OR NOT(:new.FECHA_NACIMIENTO = :old.FECHA_NACIMIENTO) ;
    SIM_PCK_FER_PERSONA.cg$table(SIM_PCK_FER_PERSONA.idx).FECHA_NACIMIENTO := :old.FECHA_NACIMIENTO;


    SIM_PCK_FER_PERSONA.idx := SIM_PCK_FER_PERSONA.idx + 1;

    if not (SIM_PCK_FER_PERSONA.called_from_package) then
        SIM_PCK_FER_PERSONA.validate_arc(cg$rec);
        SIM_PCK_FER_PERSONA.validate_domain(cg$rec, cg$ind);
        SIM_PCK_FER_PERSONA.validate_domain_cascade_update(cg$old_rec);

        SIM_PCK_FER_PERSONA.upd(cg$rec, cg$ind, FALSE);
        SIM_PCK_FER_PERSONA.called_from_package := FALSE;
    end if;

    :new.CONSECUTIVO := cg$rec.CONSECUTIVO;
    :new.PRIMER_NOMBRE := cg$rec.PRIMER_NOMBRE;
    :new.SEGUNDO_NOMBRE := cg$rec.SEGUNDO_NOMBRE;
    :new.PRIMER_APELLIDO := cg$rec.PRIMER_APELLIDO;
    :new.SEGUNDO_APELLIDO := cg$rec.SEGUNDO_APELLIDO;
    :new.SEXO := cg$rec.SEXO;
    :new.FECHA_NACIMIENTO := cg$rec.FECHA_NACIMIENTO;
--  Application_logic Post-Before-Update-row <<Start>>
--  Application_logic Post-Before-Update-row << End >>
END;
/
