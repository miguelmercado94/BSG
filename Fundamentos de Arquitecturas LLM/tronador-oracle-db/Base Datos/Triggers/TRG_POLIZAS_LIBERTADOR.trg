CREATE OR REPLACE TRIGGER Trg_Polizas_Libertador
  AFTER DELETE OR INSERT OR UPDATE OF Num_Pol1, Mca_Provisorio, Fecha_Vig_Pol, Fecha_Vig_End, Fecha_Venc_Pol, Fecha_Venc_End, Num_Pol_Ant, Num_Secu_Pol, Nro_Documto, Num_End, Cod_End, Sub_Cod_End, Tipo_End, Tdoc_Tercero, fecha_equipo ON A2000030 
  REFERENCING NEW AS NEW OLD AS OLD
  FOR EACH ROW
WHEN ((NEW.Cod_Cia = 3 AND NEW.Cod_Secc = 37 AND NEW.Cod_Ramo = 486) or
       (old.Cod_Cia = 3 AND old.Cod_Secc = 37 AND old.Cod_Ramo = 486))
DECLARE
  ls_tipo_poliza      VARCHAR2(2) := 'I'; --I Individual --C Colectiva
  v_descripcion_error VARCHAR2(2000);

BEGIN

  IF DELETING THEN
    --2022-05-19 Sheila Uhia: Modifica el trigger para que cuando sea se borre un endoso funcione el DELETING ya que tenía antes los valores :new
    UPDATE POLIZAS_SIMON ps
       SET ESTADO_CARGUE_SIMON = 'E',
           OBSERVACION_SIMON   = OBSERVACION_SIMON ||
                                 ' - Se eliminó en Simon el endoso, Validar. ' ||
                                 sysdate || '.'
     WHERE Num_Secu_Pol = :old.Num_Secu_Pol
       AND Num_End = :old.Num_End
       and ps.secuencia =
           (select max(t.secuencia)
              from polizas_simon t
             where t.num_secu_pol = ps.num_secu_pol
               and t.num_end = ps.num_end
               and t.estado_cargue_simon <> 'E');
  
  ELSIF UPDATING THEN
    UPDATE POLIZAS_SIMON f
       SET ESTADO_CARGUE_SIMON = 'A',
           OBSERVACION_SIMON   = OBSERVACION_SIMON ||
                                 ' - Se Actualizó la Póliza en Simon en campo, Validar. ' ||
                                 sysdate || '.'
     WHERE Num_Secu_Pol = :NEW.Num_Secu_Pol
       AND Num_End = :NEW.Num_End
       AND ESTADO_CARGUE_SIMON = 'C'
       and f.estado_cargue_sai = 'T'
       and f.secuencia =
           (select max(t.secuencia)
              from polizas_simon t
             where t.num_secu_pol = f.num_secu_pol
               and t.num_end = f.num_end
               AND t.ESTADO_CARGUE_SIMON = f.ESTADO_CARGUE_SIMON
               and t.estado_cargue_sai = f.estado_cargue_sai); --Solo Modifica el estado de cargue Simon garantizando que efectivamnte SAI ya cargo la póliza.
  
    ---Actualización de Observación unicamente sin estado dado que SAI toma todo lo que esta en estado  'c'
    UPDATE POLIZAS_SIMON f
       SET OBSERVACION_SIMON = OBSERVACION_SIMON ||
                               ' - Se Actualizó la Póliza en Simon en campo, Validar. ' ||
                               sysdate || '.'
     WHERE Num_Secu_Pol = :NEW.Num_Secu_Pol
       AND Num_End = :NEW.Num_End
       AND ESTADO_CARGUE_SIMON = 'C'
       and f.estado_cargue_sai is null; --Solo Modifica el estado de cargue Simon garantizando que efectivamnte SAI ya cargo la póliza.
    -------------------------
  
    UPDATE POLIZAS_SIMON f
       SET f.poliza_simon    = :NEW.num_pol1,
           OBSERVACION_SIMON = OBSERVACION_SIMON ||
                               ' - Actualizó Número de Póliza para Cotización. ' ||
                               sysdate || '.'
     WHERE Num_Secu_Pol = :NEW.Num_Secu_Pol
       AND Num_End = :NEW.Num_End
       AND ESTADO_CARGUE_SIMON = 'I'
       AND num_pol_cotizacion > 0
       AND poliza_simon is null;
  
    UPDATE POLIZAS_SIMON f -----------------Endoso Cero
       SET f.poliza_simon      = :NEW.num_pol1,
           f.mca_provisorio    = :NEW.mca_provisorio,
           f.OBSERVACION_SIMON = OBSERVACION_SIMON ||
                                 ' - Actualizó Número para póliza Provisoria. Nueva Poliza: ' ||
                                 :NEW.num_pol1 || sysdate || '.' --|| - 'Póliza Anterior: ' || :OLd.num_pol1 || sysdate || '.'
     WHERE Num_Secu_Pol = :NEW.Num_Secu_Pol
          --AND Num_End = :NEW.Num_End De deben actualizar todos los Endosos.
       AND f.ESTADO_CARGUE_SIMON = 'I'
       AND f.poliza_simon > 0
       and f.poliza_simon <> :NEW.num_pol1;
  
    UPDATE POLIZAS_SIMON ps
       SET fecha_movimiento  = :NEW.fecha_equipo,
           OBSERVACION_SIMON = OBSERVACION_SIMON ||
                               ' - Actualizó Fecha de Equipo. ' || sysdate || '.'
     WHERE Num_Secu_Pol = :NEW.Num_Secu_Pol
       AND Num_End = :NEW.Num_End
       AND ESTADO_CARGUE_SIMON = 'I'
       AND FECHA_MOVIMIENTO IS NULL
       and ps.secuencia =
           (select max(t.secuencia)
              from polizas_simon t
             where t.num_secu_pol = ps.num_secu_pol
               and t.num_end = ps.num_end
               and t.estado_cargue_simon = ps.ESTADO_CARGUE_SIMON);
  
  ELSE
    BEGIN
      INSERT INTO POLIZAS_SIMON
        (secuencia,
         cod_cia,
         cod_secc,
         cod_ramo,
         tipo_movimiento,
         anualidad,
         solicitud,
         num_End,
         cod_end,
         Sub_Cod_End,
         tipo_end,
         Tipo_documento,
         Numero_Documento,
         Cod_Ries,
         num_secu_pol,
         poliza_simon,
         clave,
         tipo_poliza,
         fecha_movimiento,
         fecha_inicio_vigencia,
         fecha_final_vigencia,
         fecha_vig_end,
         fecha_venc_end,
         Num_Pol_Ant,
         Renovada_Por,
         Fec_Anu_Pol,
         Fec_Anu_End,
         Mca_Provisorio,
         num_pol_cotizacion,
         estado_cargue_simon,
         fecha_creacion,
         usuario_creacion)
      VALUES
        (LIBERTADOR_SEQ.NEXTVAL,
         :NEW.Cod_Cia,
         :NEW.Cod_Secc,
         :NEW.Cod_Ramo,
         0,
         :NEW.CANT_ANUAL,
         0,
         :NEW.Num_End,
         :NEW.Cod_End,
         :NEW.Sub_Cod_End,
         :NEW.Tipo_End,
         :NEW.Tdoc_Tercero,
         :NEW.Nro_Documto,
         1,
         :NEW.num_secu_pol,
         :NEW.num_pol1,
         :NEW.cod_prod,
         ls_tipo_poliza,
         :NEW.Fecha_Equipo,
         :NEW.Fecha_Vig_Pol,
         :NEW.Fecha_Venc_Pol,
         :NEW.Fecha_Vig_End,
         :NEW.Fecha_Venc_End,
         :NEW.Num_Pol_Ant,
         :NEW.Renovada_Por,
         :NEW.Fec_Anu_Pol,
         :NEW.Fec_Anu_End,
         :NEW.Mca_Provisorio,
         :NEW.Num_pol_cotiz,
         'I',
         sysdate,
         user);
      NULL;
    EXCEPTION
      WHEN OTHERS THEN
        v_descripcion_error := SUBSTR(SQLERRM, 1, 2000);
      
        BEGIN
        
          INSERT INTO polizas_simonlib_audit
            (cod_cia,
             cod_secc,
             cod_producto,
             tipo_identificacion,
             numero_identificacion,
             numero_poliza,
             numero_secu_pol,
             tipo_poliza,
             numero_solicitud,
             num_end,
             cod_end,
             sub_cod_end,
             usuario,
             fecha_dia,
             descripcion_error)
          VALUES
            (:NEW.Cod_Cia,
             :NEW.Cod_Secc,
             :NEW.Cod_Ramo,
             :NEW.Tdoc_Tercero,
             :NEW.Nro_Documto,
             :NEW.Num_Pol1,
             :NEW.Num_Secu_Pol,
             ls_tipo_poliza,
             0,
             :NEW.Num_End,
             :NEW.Cod_End,
             :NEW.Sub_Cod_End,
             user,
             sysdate,
             v_descripcion_error);
        
        EXCEPTION
          WHEN OTHERS THEN
            NULL;
        END;
      
        null;
    END;
  END IF;
END Trg_Polizas_Libertador;
/
