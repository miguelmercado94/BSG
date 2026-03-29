CREATE OR REPLACE TRIGGER trg_bu_c2700001_vald_gerl
  BEFORE UPDATE
  ON C2700001   REFERENCING NEW AS new OLD AS old
  FOR EACH ROW
DECLARE
  tmpvar           NUMBER;
  total            NUMBER := 0;
  --
  v_dep_ubicacion  c2700024.dep_ubicacion%TYPE;
  v_mun_ubicacion  c2700024.mun_ubicacion%TYPE;
  --
  PRAGMA AUTONOMOUS_TRANSACTION;
/****************************************************************************************************************************
   NAME:       BU_C2700001_VALD_GERL
   PURPOSE:
   REVISIONS:
   VER        DATE        AUTHOR           DESCRIPTION
   ---------  ----------  ---------------  ----------------------------------------------------------------------------------
   1.0        22/04/2009  INTASI32        1. CONTROL PARA EL NO CAMBIO DE ESTADO EXCEPTO LOS ING Y RET EN LA TABLA
                                             C2700001.
   1.1        23/04/2009  INTASI32        2. CONTROL PARA  QUE NO SE ACTUALICE EL NIT SI ESTE PRESENTA YA UN INGRESO.
   1.2        27/10/2009  INTASI32        1. VALIDACION EN EL EVENTO QUE SE ACTUALICE LA CEDULA O EL TIPO DE IDENTIFICACION
                                             HE INSERTA DEPENDIENTO DE A FECHA DE CREACION EN LA C2700024 (RUAF).
   1.3        04/12/2023  MDURAN          1. EN AJUSTE DEL 27/10/2023, EL TIPO DE DOCUMENTO QUE INSERTA ES EL ORIGINAL DE LA
                                             C2700001 (EL. 'C') Y DEBE SER TRADUCCION DE DOS DIGITOS, ES DECIR DEBE SER 'CC'
                                             ESTCORE-9282                                             
   NOTES:
   AUTOMATICALLY AVAILABLE AUTO REPLACE KEYWORDS:
      OBJECT NAME:     BU_C2700001_VALD_GERL
      SYSDATE:         23/04/2009
      DATE AND TIME:   23/04/2009, 10:32:17 A.M., AND 23/04/2009 10:32:17 A.M.
      USERNAME:         (SET IN TOAD OPTIONS, PROC TEMPLATES)
NEW PL/SQL OBJECT
NEW PL/SQL OBJECT
******************************************************************************/
BEGIN
  /*   VALIDA QUE NO SE ACTUALICE ESTADOS DIFERENTES A INGRESOS Y RETIROS       */
  BEGIN
    IF :new.estado NOT IN ('RET', 'ING') AND :old.estado <> :new.estado THEN
      raise_application_error( -20010
                              ,' No Se Permite La Actualizacion Del Estado En La Tabla C2700001' );
    END IF;
  END;

  /*       VALIDA QUE NO SE ACTUALICE EL NIT SI ESTE PRESENTA YA UN INGRESO     */
  BEGIN
    IF :old.nit <> :new.nit AND :new.estado = 'ING' THEN
      BEGIN
        total  := 0;

        SELECT COUNT( 9 )
          INTO total
          FROM c2700001 a
         WHERE a.nit = :new.nit
           AND a.estado = 'ING'
           AND a.num_pol1 = :new.num_pol1
           AND a.depend_indepen = :new.depend_indepen;

        IF total > 0 THEN
          raise_application_error(
                                   -20011
                                  ,'No Es Posible Actualizar El Trabajador En La C2700001 - Presenta Un Ing'
          );
        END IF;
      END;
    END IF;
  END;

  --27 DE OCTUBRE DE 2009
  BEGIN
    IF :old.nit <> :new.nit OR :old.ide_nit <> :new.ide_nit THEN
      IF TO_CHAR( :old.fecha_creacion, 'MMYYYY' ) = TO_CHAR( SYSDATE, 'MMYYYY' )
     AND :old.estado = 'ING' THEN
        ---
        BEGIN
          SELECT UNIQUE dep_ubicacion
                       ,mun_ubicacion
            INTO v_dep_ubicacion
                ,v_mun_ubicacion
            FROM c2700024
           WHERE num_pol1 = :old.num_pol1 AND nit_trabajador = :old.nit AND ROWNUM < 2;
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            v_dep_ubicacion  := NULL;
            v_mun_ubicacion  := NULL;
        END;

        ---
        --INSERTA INGRESO CON LOS DATOS DE LA NUEVA CEDULA
        BEGIN
          /*MDURAN ESTCORE-9282 MDURAN-ASESOFTWARE 04/12/2023
          IMPLEMENTA ARL_PCK_UTILS.FUN_IDENTIF_TIPO_DOC*/
          pck270_insert_tablas.prc_insert_c2700024( :old.cod_cia
                                                   ,:old.cod_secc
                                                   ,:old.num_pol1
                                                   ,:old.centro_trab
                                                   ,:old.estado
                                                   ,ARL_PCK_UTILS.FUN_IDENTIF_TIPO_DOC(:new.ide_nit)
                                                   ,:new.nit
                                                   ,:old.sexo
                                                   ,:old.fec_nace
                                                   ,:old.fec_ingreso
                                                   ,:old.depend_indepen
                                                   ,NULL
                                                   ,:old.cod_cargo
                                                   ,v_dep_ubicacion
                                                   ,v_mun_ubicacion
                                                   ,:old.fec_baja
                                                   ,:old.cod_causa_ret
                                                   ,NULL
                                                   ,NULL
                                                   ,:old.fec_equipo
                                                   ,SYSDATE
                                                   ,USER );
        EXCEPTION
          WHEN OTHERS THEN
            DBMS_OUTPUT.put_line( ' ERROR AL INSERTAR EN PRC_INSERT_C2700024' );
        END;
      ELSIF TO_CHAR( :old.fecha_creacion, 'MMYYYY' ) <> TO_CHAR( SYSDATE, 'MMYYYY' ) AND :old.estado = 'ING' THEN
        --
        BEGIN
          SELECT UNIQUE dep_ubicacion
                       ,mun_ubicacion
            INTO v_dep_ubicacion
                ,v_mun_ubicacion
            FROM c2700024
           WHERE num_pol1 = :old.num_pol1 AND nit_trabajador = :old.nit AND ROWNUM < 2;
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            v_dep_ubicacion  := NULL;
            v_mun_ubicacion  := NULL;
        END;

        --
        --INSERTA RETIRO CON LOS DATOS ORIGINALES
        BEGIN
          pck270_insert_tablas.prc_insert_c2700024( :old.cod_cia
                                                   ,:old.cod_secc
                                                   ,:old.num_pol1
                                                   ,:old.centro_trab
                                                   ,'RET'
                                                   ,ARL_PCK_UTILS.FUN_IDENTIF_TIPO_DOC(:old.ide_nit)
                                                   ,:old.nit
                                                   ,:old.sexo
                                                   ,:old.fec_nace
                                                   ,:old.fec_ingreso
                                                   ,:old.depend_indepen
                                                   ,NULL
                                                   ,:old.cod_cargo
                                                   ,v_dep_ubicacion
                                                   ,v_mun_ubicacion
                                                   ,:old.fec_baja
                                                   ,:old.cod_causa_ret
                                                   ,NULL
                                                   ,NULL
                                                   ,:old.fec_equipo
                                                   ,SYSDATE
                                                   ,USER );
        EXCEPTION
          WHEN OTHERS THEN
            DBMS_OUTPUT.put_line( ' ERROR AL INSERTAR EN PRC_INSERT_C2700024' );
        END;

        --INSERTA INGRESO CON LOS DATOS DE LA NUEVA CEDULA
        BEGIN
          pck270_insert_tablas.prc_insert_c2700024( :old.cod_cia
                                                   ,:old.cod_secc
                                                   ,:old.num_pol1
                                                   ,:old.centro_trab
                                                   ,:old.estado
                                                   ,ARL_PCK_UTILS.FUN_IDENTIF_TIPO_DOC(NVL( :new.ide_nit, :old.ide_nit ))
                                                   ,:new.nit
                                                   ,:old.sexo
                                                   ,:old.fec_nace
                                                   ,:old.fec_ingreso
                                                   ,:old.depend_indepen
                                                   ,NULL
                                                   ,:old.cod_cargo
                                                   ,v_dep_ubicacion
                                                   ,v_mun_ubicacion
                                                   ,:old.fec_baja
                                                   ,:old.cod_causa_ret
                                                   ,NULL
                                                   ,NULL
                                                   ,:old.fec_equipo
                                                   ,SYSDATE
                                                   ,USER );
        EXCEPTION
          WHEN OTHERS THEN
            DBMS_OUTPUT.put_line( ' ERROR AL INSERTAR EN PRC_INSERT_C2700024' );
        END;
      END IF;

      COMMIT;
    END IF;
  END;
END trg_bu_c2700001_vald_gerl;
/
