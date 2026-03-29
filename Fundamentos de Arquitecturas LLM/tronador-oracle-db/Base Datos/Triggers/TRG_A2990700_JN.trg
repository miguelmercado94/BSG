CREATE OR REPLACE TRIGGER trg_a2990700_jn AFTER
    DELETE OR INSERT OR UPDATE of COD_SITUACION ON A2990700 
    REFERENCING
            NEW AS new
            OLD AS old
    FOR EACH ROW
DECLARE
    v_operacion   VARCHAR2(3);
/******************************************************************************
    NOMBEW:    trg_a2990700_jn
    PROPOSITO: HACER SEGUIMIENTO DE MOVIMIENTOS DE DATOS EN LA TABLA A2990700
              Y DETERMINAR PORQUE ALGUNA SFACTURAS QUEDAN EN ESTADO EP

    REVISIONES:
    Verion        Fecha       Autor                            Descripcion
    ---------  ----------  -----------------------    ------------------------------------
    1.0        24/06/2022  Mario Duran Asesoftware    Creacion del trigger.
******************************************************************************/
BEGIN

    IF (:NEW.COD_CIA = 2 AND :NEW.COD_SECC = 70 AND :NEW.COD_RAMO IN (722,782))
        OR (:OLD.COD_CIA = 2 AND :OLD.COD_SECC = 70 AND :OLD.COD_RAMO IN (722,782))
    THEN
        IF
            inserting
        THEN
            v_operacion := 'INS';
        ELSIF updating THEN
            v_operacion := 'UPD';
        ELSIF deleting THEN
            v_operacion := 'DEL';
        END IF;

        IF
            inserting
        THEN
            INSERT INTO A2990700_JN (
                    COD_CIA, 
                    COD_SECC, 
                    NUM_POL1, 
                    NUM_END, 
                    COD_SITUACION, 
                    FECHA_EMI_END, 
                    FEC_INI_VIG_PER, 
                    FEC_SITU, 
                    FEC_VALOR, 
                    FEC_EFECTO, 
                    FEC_VCTO, 
                    IMP_PRIMA, 
                    IMP_MONEDA_LOCAL, 
                    IMP_COMISION_LOCAL, 
                    COD_MON, 
                    NRO_DOCUMTO, 
                    NOM_TOMADOR, 
                    COD_RAMO, 
                    FECHA_EQUIPO, 
                    NUM_FACTURA, 
                    NUM_SECU_POL, 
                    FECHA_CREACION, 
                    TDOC_TERCERO,
                    USUARIO_JN, 
                    FECHA_JN, 
                    OPERACION_JN
            ) VALUES (
                    :NEW.COD_CIA, 
                    :NEW.COD_SECC, 
                    :NEW.NUM_POL1, 
                    :NEW.NUM_END, 
                    :NEW.COD_SITUACION, 
                    :NEW.FECHA_EMI_END, 
                    :NEW.FEC_INI_VIG_PER, 
                    :NEW.FEC_SITU, 
                    :NEW.FEC_VALOR, 
                    :NEW.FEC_EFECTO, 
                    :NEW.FEC_VCTO, 
                    :NEW.IMP_PRIMA, 
                    :NEW.IMP_MONEDA_LOCAL, 
                    :NEW.IMP_COMISION_LOCAL, 
                    :NEW.COD_MON, 
                    :NEW.NRO_DOCUMTO, 
                    :NEW.NOM_TOMADOR, 
                    :NEW.COD_RAMO, 
                    :NEW.FECHA_EQUIPO, 
                    :NEW.NUM_FACTURA, 
                    :NEW.NUM_SECU_POL, 
                    :NEW.FECHA_CREACION, 
                    :NEW.TDOC_TERCERO,
                   USER,
                   SYSDATE,
                   v_operacion
            );

        ELSE
            INSERT INTO A2990700_JN (
                    COD_CIA, 
                    COD_SECC, 
                    NUM_POL1, 
                    NUM_END, 
                    COD_SITUACION, 
                    FECHA_EMI_END, 
                    FEC_INI_VIG_PER, 
                    FEC_SITU, 
                    FEC_VALOR, 
                    FEC_EFECTO, 
                    FEC_VCTO, 
                    IMP_PRIMA, 
                    IMP_MONEDA_LOCAL, 
                    IMP_COMISION_LOCAL, 
                    COD_MON, 
                    NRO_DOCUMTO, 
                    NOM_TOMADOR, 
                    COD_RAMO, 
                    FECHA_EQUIPO, 
                    NUM_FACTURA, 
                    NUM_SECU_POL, 
                    FECHA_CREACION, 
                    TDOC_TERCERO,
                    USUARIO_JN, 
                    FECHA_JN, 
                    OPERACION_JN
            ) VALUES (
                    :OLD.COD_CIA, 
                    :OLD.COD_SECC, 
                    :OLD.NUM_POL1, 
                    :OLD.NUM_END, 
                    :OLD.COD_SITUACION, 
                    :OLD.FECHA_EMI_END, 
                    :OLD.FEC_INI_VIG_PER, 
                    :OLD.FEC_SITU, 
                    :OLD.FEC_VALOR, 
                    :OLD.FEC_EFECTO, 
                    :OLD.FEC_VCTO, 
                    :OLD.IMP_PRIMA, 
                    :OLD.IMP_MONEDA_LOCAL, 
                    :OLD.IMP_COMISION_LOCAL, 
                    :OLD.COD_MON, 
                    :OLD.NRO_DOCUMTO, 
                    :OLD.NOM_TOMADOR, 
                    :OLD.COD_RAMO, 
                    :OLD.FECHA_EQUIPO, 
                    :OLD.NUM_FACTURA, 
                    :OLD.NUM_SECU_POL, 
                    :OLD.FECHA_CREACION, 
                    :OLD.TDOC_TERCERO,
                   USER,
                   SYSDATE,
                   v_operacion
            );

        END IF;
    END IF;
EXCEPTION
    WHEN OTHERS THEN
        raise_application_error(-20001,sqlerrm);
END;
/
