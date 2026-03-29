CREATE OR REPLACE TRIGGER "TRG_AIUD_001_C2700539" AFTER UPDATE OR INSERT OR DELETE ON "C2700539"
REFERENCING OLD AS OLD NEW AS NEW FOR EACH ROW
DECLARE
    V_Fecha_Vig_Pol DATE;
    V_Afl_secuencia number;   
    V_TipoDocumentoEmpleador varchar2(2);
    v_NumeroDocumentoEmpleador varchar2(16);
    v_periodo NUMBER(6);
    v_TipoReporte NUMBER(1);
/******************************************************************************
   NAME:       Trg_Aiud_001_C2700539
   PURPOSE:

   REVISIONS:
   Ver        Date        Author           Description
   ---------  ----------  ---------------  ------------------------------------
   1.0        24/8/2020      79704401       1. Created this trigger.
   1.2        31/05/2023  Jaime A. Sabogal  1. Se adiciona validación cuando el procedimiento almacenado es
                                               ARL_SAT_MINSALUD_PCK_EMPLEADOR.PROC_ARL_EMPLEADOR_SALUD ya que
                                               todos los registros quedan pendientes y se reprocesan.
                                            2. Se adiciona validación cuando el servicio de afiliación retorna glosa porque
                                               ya esta afiliado a otra ARL, se actualiza el metodo de envío a traslado de ARL
                                               y se deja en pendiente para que el servicio lo reenvíe.
                                            3. Se adiciona validación cuando el servicio de afiliación de Sedes retorna
                                               glosas porque ya existe una sede principla se cambia a actualización para
                                               garantizar que los datos de SAT queden como los tiene Seguros Bolivar.
                                            4. Se adiciona validación cuando el procedimiento almacenado es
                                               ARL_SAT_MINSALUD_PCK_EMPLEADOR.ARL_SAT_MINSALUD_PCK_PG_APORTS ya que
                                               todos los registros quedan pendientes y se reprocesan indefinidamente.
    1.3        05/09/2023 Brian Manjarres   1. Se adiciona FECHA TRASLADO a las notificaciones de traslado que serán tramitadas
                                               a través del servicio web [SW][09]. La fecha de traslado corresponde a la fecha de
                                               emisión de la póliza menos 45 días calendario.
    1.4        26/11/2024 Yeison Orozco     1. Se agregan dos nuevos servicios al flujo   
    1.5        02/07/2025 Yeison Orozco     1. Se borran asignaciones de variable no utilizadas
                                            2. Se elimina Intervalo de -45 dias a la fecha de traslado.                                    
   NOTES:

   Automatically available Auto Replace Keywords:
      Object Name:     Trg_Aiud_001_C2700539
      Sysdate:         24/8/2020
      Date and Time:   24/8/2020, 1:35:47 PM, and 24/8/2020 1:35:47 PM
      Username:        79704401 (set in TOAD Options, Proc Templates)
      Table Name:      C2700539 (set in the "New PL/SQL Object" dialog)
      Trigger Options:  (set in the "New PL/SQL Object" dialog)
******************************************************************************/
BEGIN
    IF INSERTING
    THEN
        
    --Yeison Orozco Reporte de mora manual 
    If :new.Svr_Procedure = 'ARL_SAT_MINSALUD_PCK_PG_APORTS.PROC_ARL_PAGOAPORTES_SALUD' 
        then
            BEGIN 
                --poner afl_secuencia 539
                 BEGIN
    -- Intentamos hacer la consulta y asignar el valor a la variable
    SELECT a.afl_secuencia,
    REGEXP_SUBSTR(:new.http_requests, 'TipoDocumentoEmpleador=([^,}]+)', 1, 1, NULL, 1) AS TipoDocumentoEmpleador,
    REGEXP_SUBSTR(:new.http_requests, 'NumeroDocumentoEmpleador=([0-9]+)', 1, 1, NULL, 1) AS NumeroDocumentoEmpleador,
    REPLACE(REGEXP_SUBSTR(:new.http_requests, 'Periodo=([^,}]+)', 1, 1, NULL, 1), '-', '') AS Periodo,
    CASE 
        WHEN REGEXP_SUBSTR(:new.http_requests, 'TipoReporte=([^,}]+)', 1, 1, NULL, 1) = 'D' THEN '1'
        WHEN REGEXP_SUBSTR(:new.http_requests, 'TipoReporte=([^,}]+)', 1, 1, NULL, 1) = 'M' THEN '2'
        WHEN REGEXP_SUBSTR(:new.http_requests, 'TipoReporte=([^,}]+)', 1, 1, NULL, 1) = 'A' THEN '3'
        WHEN REGEXP_SUBSTR(:new.http_requests, 'TipoReporte=([^,}]+)', 1, 1, NULL, 1) = 'I' THEN '4'
        ELSE NULL -- En caso de que no coincida con ninguna opción
    END AS TipoReporte
    INTO V_Afl_secuencia,V_TipoDocumentoEmpleador 
    ,v_NumeroDocumentoEmpleador
    ,v_periodo
    ,v_TipoReporte
    FROM c2700534 a
    WHERE a.afl_nro_identificacion = ( REGEXP_SUBSTR(:new.http_requests, 'NumeroDocumentoEmpleador=([0-9]+)', 1, 1, NULL, 1)
        );
    
   -- Update C2700539 set afl_secuencia = V_Afl_secuencia where reg_secuencia = :new.reg_secuencia;
    Update C2700534 set afl_tipo_identificacion = V_TipoDocumentoEmpleador, 
    afl_nro_identificacion = v_NumeroDocumentoEmpleador,AFL_PERIODO_MORA = v_periodo, AFL_ESTADO_PAGO = v_TipoReporte where
    afl_secuencia = V_Afl_secuencia;
    
    
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        DBMS_OUTPUT.PUT_LINE('Error no data found: ' || SQLCODE || ' - ' || SQLERRM);      
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Error: ' || SQLCODE || ' - ' || SQLERRM);
END;
                
                END;
            
            end if;
    --1.4
    IF :new.Svr_Procedure = 'ARL_SAT_MINSALUD_PCK_RT_TS_EMP.PROC_ARL_RT_TS_EMP_SALUD'
        THEN
            UPDATE C2700534
                   SET C2700534.Afl_Estado_Envio  = :new.Estado
                 WHERE C2700534.Afl_Secuencia = :new.Afl_Secuencia;
            END IF;
     --1.4
    IF :new.Svr_Procedure = 'ARL_SAT_MINSALUD_PCK_RECLS_CT.PROC_ARL_RECLS_CT_SALUD'
        THEN
            UPDATE C2700536
                   SET C2700536.Ctr_Estado_Envio  = :new.Estado
                 WHERE C2700536.Afl_Secuencia = :new.Afl_Secuencia
                   AND C2700536.Ctr_Secuencia = :new.Ctr_Secuencia;
            END IF;
    --
        IF :new.Svr_Procedure = 'ARL_SAT_MINSALUD_PCK_AFLIA_ARL.PROC_ARL_AFILACION_SALUD'
        THEN
            BEGIN
                UPDATE C2700534
                   SET C2700534.Afl_Estado_Envio  = :new.Estado
                 WHERE C2700534.Afl_Secuencia = :new.Afl_Secuencia;

            END;

            IF dbms_lob.instr(:new.HTTP_RESPONSE,'Ya existe una afiliación a la ARL') > 0
            THEN
                BEGIN
                    SELECT FECHA_VIG_POL
                    INTO V_Fecha_Vig_Pol
                    FROM SIM_ARL_SAT_EMPRESAS
                    WHERE NRO_DOCUMTO = (SELECT AFL_NRO_IDENTIFICACION
                                         FROM C2700534
                                         WHERE AFL_SECUENCIA = :new.AFL_SECUENCIA
                                         AND :new.ESTADO = 'F'
                                         AND AFL_MEDIO_ENVIO = '[SW][01]');

                    UPDATE C2700534
                    SET C2700534.Afl_Estado_Envio  = 'P', AFL_MEDIO_ENVIO = '[SW][09]', AFL_FECHA_TRASLADO = V_Fecha_Vig_Pol
                    WHERE C2700534.Afl_Secuencia = :new.Afl_Secuencia
                    AND AFL_MEDIO_ENVIO = '[SW][01]' AND :new.Estado = 'F';

                    UPDATE C2700536
                    SET CTR_ESTADO_ENVIO = 'S'
                    WHERE AFL_SECUENCIA = :new.AFL_SECUENCIA;

                    UPDATE C2700535
                    SET SDE_ESTADO_ENVIO = 'S'
                    WHERE AFL_SECUENCIA = :new.AFL_SECUENCIA;

                    UPDATE C2700537
                    SET ATR_ESTADO_ENVIO = 'S'
                    WHERE AFL_SECUENCIA = :new.AFL_SECUENCIA;

                    COMMIT;

                END;
            END IF;

        IF dbms_lob.instr(:new.HTTP_RESPONSE,'Razón social o nombre de la empresa') > 0
        THEN
            BEGIN
                UPDATE C2700534
                   SET C2700534.Afl_Estado_Envio  = 'P', AFL_RAZON_SOCIAL = SUBSTR(TO_CHAR(:new.HTTP_RESPONSE), 90, INSTR(TO_CHAR(:new.HTTP_RESPONSE), ')"') - 90)
                 WHERE C2700534.Afl_Secuencia = :new.Afl_Secuencia
                       AND AFL_MEDIO_ENVIO = '[SW][01]' AND :new.Estado = 'F';
            END;
        END IF;



        END IF;

        IF :new.Svr_Procedure = 'ARL_SAT_MINSALUD_PCK_SEDES.PROC_ARL_SEDES_SALUD'
        THEN
            BEGIN
                UPDATE C2700535
                   SET C2700535.Sde_Estado_Envio  = :new.Estado
                 WHERE C2700535.Afl_Secuencia = :new.Afl_Secuencia
                   AND C2700535.Sde_Secuencia = :new.Sde_Secuencia;


                IF dbms_lob.instr(:new.HTTP_RESPONSE,'La sede ya existe, no se puede crear otra con el mismo código, sólo permite actualización') > 0
                THEN
                    BEGIN
                        UPDATE C2700535
                         SET C2700535.Sde_Estado_Envio  = 'P', Sde_Estado_Afiliado = 'A'
                       WHERE C2700535.Afl_Secuencia = :new.Afl_Secuencia
                         AND C2700535.Sde_Secuencia = :new.Sde_Secuencia;
                    END;
                END IF;

           END;

        END IF;

        IF :new.Svr_Procedure = 'ARL_SAT_MINSALUD_PCK_CTROTRAB.PROC_ARL_CENTROTRAB_SALUD'
        THEN
            BEGIN
                UPDATE C2700536
                   SET C2700536.Ctr_Estado_Envio  = :new.Estado
                 WHERE C2700536.Afl_Secuencia = :new.Afl_Secuencia
                   AND C2700536.Ctr_Secuencia = :new.Ctr_Secuencia;

                IF dbms_lob.instr(:new.HTTP_RESPONSE,'El centro de trabajo  ya existe') > 0
                THEN
                    BEGIN
                        UPDATE C2700536
                         SET C2700536.CTR_ESTADO_ENVIO  = 'P', CTR_ESTADO_AFILIADO = 'A'
                        WHERE C2700536.Afl_Secuencia = :new.Afl_Secuencia
                              AND C2700536.Ctr_Secuencia = :new.Ctr_Secuencia;
                    END;
                END IF;

            END;
        END IF;

        IF :new.Svr_Procedure = 'ARL_SAT_MINSALUD_PCK_REL_LBRL.PROC_ARL_REL_LABORAL_SALUD'
        THEN
            BEGIN
                UPDATE C2700537
                   SET C2700537.Atr_Estado_Envio  = :new.Estado
                 WHERE C2700537.Atr_Secuencia = :new.Atr_Secuencia
                   AND C2700537.Afl_Secuencia = :new.Afl_Secuencia
                   AND C2700537.Ctr_Secuencia = :new.Ctr_Secuencia;
            END;
        END IF;

        IF :new.Svr_Procedure = 'ARL_SAT_MINSALUD_PCK_COR_TSCOT.PROC_ARL_COR_TIP_COT'
        THEN
            BEGIN
                UPDATE C2700537
                   SET C2700537.Atr_Estado_Envio  = :new.Estado
                 WHERE C2700537.Atr_Secuencia = :new.Atr_Secuencia
                   AND C2700537.Afl_Secuencia = :new.Afl_Secuencia
                   AND C2700537.Ctr_Secuencia = :new.Ctr_Secuencia;
            END;
        END IF;

        IF :new.Svr_Procedure = 'ARL_SAT_MINSALUD_PCK_EMP_SGRL.PROC_ARL_RET_DEF_EMPSGRL_SALUD'
        THEN
            BEGIN
                UPDATE C2700534
                   SET C2700534.Afl_Estado_Envio  = :new.Estado
                 WHERE C2700534.Afl_Secuencia = :new.Afl_Secuencia;
            END;
        END IF;

        -- Marca modificación 1.2.
        IF :new.Svr_Procedure = 'ARL_SAT_MINSALUD_PCK_EMPLEADOR.PROC_ARL_EMPLEADOR_SALUD'
        THEN
            BEGIN
                UPDATE C2700534
                   SET C2700534.Afl_Estado_Envio  = :new.Estado
                 WHERE C2700534.Afl_Secuencia = :new.Afl_Secuencia;
            END;
        END IF;

        IF :new.Svr_Procedure = 'ARL_SAT_MINSALUD_PCK_EMPLEADOR.PROC_ARL_EMPLEADOR_SALUD'
           AND dbms_lob.instr(:new.HTTP_RESPONSE,'Existe una afiliación a la ARL que reporta para el empleador en el SAT') > 0
        THEN
            BEGIN
                UPDATE C2700534
                   SET C2700534.Afl_Estado_Envio  = 'S'
                 WHERE C2700534.Afl_Secuencia = :new.Afl_Secuencia;
            END;
        END IF;

        IF :new.Svr_Procedure = 'ARL_SAT_MINSALUD_PCK_EMPLEADOR.PROC_ARL_EMPLEADOR_SALUD'
           AND dbms_lob.instr(:new.HTTP_RESPONSE,'El aportante tiene una novedad de traslado en curso a la ARL (14-7)') > 0
        THEN
            BEGIN
                UPDATE C2700534
                   SET C2700534.Afl_Estado_Envio  = 'S'
                 WHERE C2700534.Afl_Secuencia = :new.Afl_Secuencia;
            END;
        END IF;

        -- Marca modificación 1.3.
        IF :new.Svr_Procedure = 'ARL_SAT_MINSALUD_PCK_PG_APORTS.PROC_ARL_PAGOAPORTES_SALUD'
        THEN
            BEGIN
                UPDATE C2700534
                   SET C2700534.Afl_Estado_Envio  = :new.Estado
                 WHERE C2700534.Afl_Secuencia = :new.Afl_Secuencia;
            END;
        END IF;

        IF :new.Svr_Procedure = 'ARL_SAT_MINSALUD_PCK_TER_RLARL.PROC_ARL_TER_REL_LAB_ARL'
        THEN
            BEGIN
                UPDATE C2700537
                   SET C2700537.Atr_Estado_Envio  = :new.Estado
                 WHERE C2700537.Atr_Secuencia = :new.Atr_Secuencia
                   AND C2700537.Afl_Secuencia = :new.Afl_Secuencia
                   AND C2700537.Ctr_Secuencia = :new.Ctr_Secuencia;
            END;
        END IF;

        IF :new.Svr_Procedure = 'ARL_SAT_MINSALUD_PCK_TER_LABRL.PROC_ARL_PRAC_FORMA_SALUD'
        THEN
            BEGIN
                UPDATE C2700537
                   SET C2700537.Atr_Estado_Envio  = :new.Estado
                 WHERE C2700537.Atr_Secuencia = :new.Atr_Secuencia
                   AND C2700537.Afl_Secuencia = :new.Afl_Secuencia
                   AND C2700537.Ctr_Secuencia = :new.Ctr_Secuencia;
            END;
        END IF;

        IF :new.Svr_Procedure = 'ARL_SAT_MINSALUD_PCK_VRIACN_CT.PROC_ARL_VRIACN_CT_SALUD'
        THEN
            BEGIN
                UPDATE C2700537
                   SET C2700537.Atr_Estado_Envio  = :new.Estado
                 WHERE C2700537.Atr_Secuencia = :new.Atr_Secuencia
                   AND C2700537.Afl_Secuencia = :new.Afl_Secuencia
                   AND C2700537.Ctr_Secuencia = :new.Ctr_Secuencia;
            END;
        END IF;

        IF :new.Svr_Procedure = 'ARL_SAT_MINSALUD_PCK_MODIF_ACT_ECO.PROC_ARL_MODIFICACION_ACT_ECO'
        THEN
            BEGIN
                UPDATE C2700534
                   SET C2700534.Afl_Estado_Envio  = :new.Estado
                 WHERE C2700534.Afl_Secuencia = :new.Afl_Secuencia;
            END;
        END IF;

    ELSIF UPDATING
    THEN
        IF :new.Svr_Procedure = 'ARL_SAT_MINSALUD_PCK_AFLIA_ARL.PROC_ARL_AFILACION_SALUD'
        THEN
            BEGIN
                 UPDATE C2700534
                 SET C2700534.Afl_Estado_Envio  = :new.Estado
                 WHERE C2700534.Afl_Secuencia = :new.Afl_Secuencia;
            END;
        END IF;

        IF :new.Svr_Procedure = 'ARL_SAT_MINSALUD_PCK_SEDES.PROC_ARL_SEDES_SALUD'
        THEN
            BEGIN
                UPDATE C2700535
                   SET C2700535.Sde_Estado_Envio  = :new.Estado
                 WHERE C2700535.Afl_Secuencia = :new.Afl_Secuencia
                   AND C2700535.Sde_Secuencia = :new.Sde_Secuencia;

                IF dbms_lob.instr(:new.HTTP_RESPONSE,'La sede ya existe, no se puede crear otra con el mismo código, sólo permite actualización') > 0
                THEN
                    BEGIN
                        UPDATE C2700535
                         SET C2700535.Sde_Estado_Envio  = 'P', Sde_Estado_Afiliado = 'A'
                       WHERE C2700535.Afl_Secuencia = :new.Afl_Secuencia
                         AND C2700535.Sde_Secuencia = :new.Sde_Secuencia;
                    END;
                END IF;

           END;

        END IF;

        IF :new.Svr_Procedure = 'ARL_SAT_MINSALUD_PCK_CTROTRAB.PROC_ARL_CENTROTRAB_SALUD'
        THEN
            BEGIN
                UPDATE C2700536
                   SET C2700536.Ctr_Estado_Envio  = :new.Estado
                 WHERE C2700536.Afl_Secuencia = :new.Afl_Secuencia
                   AND C2700536.Ctr_Secuencia = :new.Ctr_Secuencia;

                IF dbms_lob.instr(:new.HTTP_RESPONSE,'El centro de trabajo  ya existe') > 0
                THEN
                    BEGIN
                        UPDATE C2700536
                         SET C2700536.CTR_ESTADO_ENVIO  = 'P', CTR_ESTADO_AFILIADO = 'A'
                        WHERE C2700536.Afl_Secuencia = :new.Afl_Secuencia
                              AND C2700536.Ctr_Secuencia = :new.Ctr_Secuencia;
                    END;
                END IF;

            END;
        END IF;

        IF :new.Svr_Procedure = 'ARL_SAT_MINSALUD_PCK_REL_LBRL.PROC_ARL_REL_LABORAL_SALUD'
        THEN
            BEGIN
                UPDATE C2700537
                   SET C2700537.Atr_Estado_Envio  = :new.Estado
                 WHERE C2700537.Atr_Secuencia = :new.Atr_Secuencia
                   AND C2700537.Afl_Secuencia = :new.Afl_Secuencia
                   AND C2700537.Ctr_Secuencia = :new.Ctr_Secuencia;
            END;
        END IF;

        IF :new.Svr_Procedure = 'ARL_SAT_MINSALUD_PCK_EMPLEADOR.PROC_ARL_EMPLEADOR_SALUD'
        THEN
            BEGIN
                UPDATE C2700534
                   SET C2700534.Afl_Estado_Envio  = :new.Estado
                 WHERE C2700534.Afl_Secuencia = :new.Afl_Secuencia;
            END;
        END IF;

        IF :new.Svr_Procedure = 'ARL_SAT_MINSALUD_PCK_EMPLEADOR.PROC_ARL_EMPLEADOR_SALUD'
           AND dbms_lob.instr(:new.HTTP_RESPONSE,'Existe una afiliación a la ARL que reporta para el empleador en el SAT') > 0
        THEN
            BEGIN
                UPDATE C2700534
                   SET C2700534.Afl_Estado_Envio  = 'S'
                 WHERE C2700534.Afl_Secuencia = :new.Afl_Secuencia;
            END;
        END IF;

        IF :new.Svr_Procedure = 'ARL_SAT_MINSALUD_PCK_EMPLEADOR.PROC_ARL_EMPLEADOR_SALUD'
           AND dbms_lob.instr(:new.HTTP_RESPONSE,'El aportante tiene una novedad de traslado en curso a la ARL (14-7)') > 0
        THEN
            BEGIN
                UPDATE C2700534
                   SET C2700534.Afl_Estado_Envio  = 'S'
                 WHERE C2700534.Afl_Secuencia = :new.Afl_Secuencia;
            END;
        END IF;

    ELSIF DELETING
    THEN
        NULL;
    END IF;
EXCEPTION
    WHEN OTHERS
    THEN
        -- CONSIDER LOGGING THE ERROR AND THEN RE-RAISE
        --RAISE;
        NULL;
END Trg_Aiud_001_C2700539;
-- SHOW ERRORS;