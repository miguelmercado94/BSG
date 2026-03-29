CREATE OR REPLACE TRIGGER trg_empresa_arp
BEFORE INSERT OR
       DELETE OR
       UPDATE OF valor_campo
                ,cod_campo
                ,cod_ries
                ,mca_baja_ries
                ,mca_vigente
                ,num_end
   ON A2000020
FOR EACH ROW
WHEN (
       NEW.cod_campo = 'NUMERO_TRAB' OR
       NEW.cod_campo = 'APORTE_APROX'
      )
DECLARE
  ---------------------------------------------------------------------------------------------------------------------------------------------
  --Objetivo   : Actualizar la tabla cambios_prevencion, poliza_empresa y centro_trabajo de SIPAB ante cambios sin endoso
  --                     en número de trabajadores y aporte aproximado
  --Modificado : Luisa Fernanda Leguizamón Bayona
  --Fecha      : 04/03/2020
  ---------------------------------------------------------------------------------------------------------------------------------------------
  -- Objetivo : insertar en la tabla cambios_prevencion para actualizar la informacion en el sistema de informacion de SIPAB
  -- Autor    : Elsa Victoria Duque Gomez
  -- Fecha    : Agosto 24 de 20001
  -- Fecha    : septiembre 30 de 20004 por recomendacion de Innovacion tecnologica--se cambio el trigger, para conseguir un mejor desempeno
  ---------------------------------------------------------------------------------------------------------------------------------------------
  mensaje VARCHAR2(60);
  codsecc NUMBER;

BEGIN
  BEGIN
    SELECT cod_Secc
      INTO codsecc
      FROM A2000030
     WHERE num_secu_pol = :NEW.num_secu_pol
       AND rownum = 1;
  EXCEPTION
    WHEN OTHERS THEN
      codsecc := 0;
  END;

  IF codsecc = 70 THEN
    IF UPDATING OR INSERTING THEN
      BEGIN
        if :old.num_secu_pol = :new.num_secu_pol AND NVL(:old.valor_campo, 'X') <> NVL(:new.valor_campo, 'X') then
           IF :new.Cod_Campo = 'APORTE_APROX' THEN
             BEGIN 
                --Actualiza tabla intermedia si está pendiente de procesar el registro de póliza
                 UPDATE CAMBIOS_PREVENCION c
                    SET c.valor_campo  = :new.valor_campo,
                        c.fecha_equipo = SYSDATE
                  WHERE c.num_secu_pol = :new.num_secu_pol
                    AND c.cod_campo    = :new.Cod_Campo
                    AND c.cod_ries IS NULL;
             EXCEPTION WHEN OTHERS THEN
                mensaje := SUBSTR('TRO_PRI '||SQLERRM, 1, 60);
                BEGIN
                  INSERT INTO INCONSISTENCIAS_PREVENCION
                    (num_secu_pol,
                     num_end,
                     cod_ries,
                     cod_campo,
                     valor_campo,
                     mca_baja_ries,
                     mca_vigente,
                     mensaje,
                     TABLA)
                  VALUES
                    (:NEW.num_secu_pol,
                     :NEW.num_end,
                     :NEW.cod_ries,
                     :NEW.cod_campo,
                     :NEW.valor_campo,
                     :NEW.mca_baja_ries,
                     :NEW.mca_vigente,
                     mensaje,
                     'A2000020');
                EXCEPTION
                  WHEN OTHERS THEN
                    NULL;
                END;
             END;
                
             BEGIN
                   --Actualiza la prima esperada en SIPAB si la póliza ya existe
                   UPDATE poliza_empresa pe
                     SET pe.valor_prima_esperada = :new.valor_campo,
                         pe.fecha_ultima_actualizacion = SYSDATE
                    WHERE pe.numero_interno_poliza = :new.num_secu_pol;
             EXCEPTION WHEN OTHERS THEN
                  mensaje := SUBSTR('SIP_PRI '||SQLERRM, 1, 60);
                  BEGIN
                    INSERT INTO INCONSISTENCIAS_PREVENCION
                      (num_secu_pol,
                       num_end,
                       cod_ries,
                       cod_campo,
                       valor_campo,
                       mca_baja_ries,
                       mca_vigente,
                       mensaje,
                       TABLA)
                    VALUES
                      (:NEW.num_secu_pol,
                       :NEW.num_end,
                       :NEW.cod_ries,
                       :NEW.cod_campo,
                       :NEW.valor_campo,
                       :NEW.mca_baja_ries,
                       :NEW.mca_vigente,
                       mensaje,
                       'A2000020');
                  EXCEPTION
                    WHEN OTHERS THEN
                      NULL;
                  END;
             END;
           ELSIF :new.Cod_Campo = 'NUMERO_TRAB' THEN
            BEGIN
              --Actualiza tabla intermedia si está pendiente de procesar el registro
             UPDATE CAMBIOS_PREVENCION c
                SET c.valor_campo  = :new.valor_campo
              WHERE c.num_secu_pol = :new.num_secu_pol
                AND c.cod_campo    = :new.Cod_Campo
                AND c.cod_ries     = :new.Cod_Ries;
             EXCEPTION WHEN OTHERS THEN
                mensaje := SUBSTR('TRON_TR '||SQLERRM, 1, 60);
                BEGIN
                  INSERT INTO INCONSISTENCIAS_PREVENCION
                    (num_secu_pol,
                     num_end,
                     cod_ries,
                     cod_campo,
                     valor_campo,
                     mca_baja_ries,
                     mca_vigente,
                     mensaje,
                     TABLA)
                  VALUES
                    (:NEW.num_secu_pol,
                     :NEW.num_end,
                     :NEW.cod_ries,
                     :NEW.cod_campo,
                     :NEW.valor_campo,
                     :NEW.mca_baja_ries,
                     :NEW.mca_vigente,
                     mensaje,
                     'A2000020');
                EXCEPTION
                  WHEN OTHERS THEN
                    NULL;
                END;
              END;
              
              BEGIN
                --Actualiza centro de trabajo en SIPAB
                UPDATE centro_trabajo c
                   SET c.cantidad_trabajadores = :new.valor_campo,
                       c.fecha_transaccion = SYSDATE,
                       c.usuario_transaccion = USER
                 WHERE c.numero_interno_poliza = :new.num_secu_pol
                   AND c.codigo_centro_trabajo = :new.Cod_Ries;
              EXCEPTION WHEN OTHERS THEN
                mensaje := SUBSTR('SIP_TR '||SQLERRM, 1, 60);
                BEGIN
                  INSERT INTO INCONSISTENCIAS_PREVENCION
                    (num_secu_pol,
                     num_end,
                     cod_ries,
                     cod_campo,
                     valor_campo,
                     mca_baja_ries,
                     mca_vigente,
                     mensaje,
                     TABLA)
                  VALUES
                    (:NEW.num_secu_pol,
                     :NEW.num_end,
                     :NEW.cod_ries,
                     :NEW.cod_campo,
                     :NEW.valor_campo,
                     :NEW.mca_baja_ries,
                     :NEW.mca_vigente,
                     mensaje,
                     'A2000020');
                EXCEPTION
                  WHEN OTHERS THEN
                    NULL;
                END;
             END;
           END IF;
        END IF;
      EXCEPTION
        WHEN OTHERS THEN
          mensaje := SUBSTR('SIPAB '||SQLERRM, 1, 60);
          BEGIN
            INSERT INTO INCONSISTENCIAS_PREVENCION
              (num_secu_pol,
               num_end,
               cod_ries,
               cod_campo,
               valor_campo,
               mca_baja_ries,
               mca_vigente,
               mensaje,
               TABLA)
            VALUES
              (:NEW.num_secu_pol,
               :NEW.num_end,
               :NEW.cod_ries,
               :NEW.cod_campo,
               :NEW.valor_campo,
               :NEW.mca_baja_ries,
               :NEW.mca_vigente,
               mensaje,
               'A2000020');
          EXCEPTION
            WHEN OTHERS THEN
              NULL;
          END;
      END;
    END IF; -- Si está actualizando o insertando
  END IF; --Sección ARL
END trg_empresa_arp;
/
