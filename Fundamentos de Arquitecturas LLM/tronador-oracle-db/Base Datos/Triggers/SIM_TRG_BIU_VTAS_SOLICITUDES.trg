CREATE OR REPLACE TRIGGER SIM_TRG_BIU_VTAS_SOLICITUDES
  BEFORE INSERT OR UPDATE on sim_vtas_solicitudes  
  for each row
declare
  -- local variables here
BEGIN
  -- Si el tipo de solicitud es SOLI, el campo que se recibe en Cod_causal desde SimonQuotation
  -- es el tipo de solicitud de modificacion. Si es diferente de Soli, lo que se recibe es el codigo
  -- de causal de cancelacion o de cambio de clave
  IF inserting THEN 
    IF :NEW.TIPO_SOL = 'SOLI' THEN
      IF :NEW.COD_CAUSAL IS NOT NULL THEN
        :NEW.ID_TIPSOLMODIFPROD := :NEW.COD_CAUSAL;
        :new.cod_causal := NULL;
      END IF;
    END IF;
  END IF;    
  IF updating THEN
    IF (nvl(:new.estado,'XXXX') <> nvl(:old.estado,'XXXX')) AND nvl(:NEW.ESTADO,'XXXX') = 'ADIC'  THEN
      -- Cuando se cambia el estado de la solicitud a datos adicionales, se incluye comentario en 
      -- sim_seg_controles_tecnicos automáticamente
      -- Wesv 20180402 - Mantis 63363
      INSERT INTO sim_seg_ctroles_tecnicos ssct
                          (id_segcontec, 
                           id_controltec, 
                           comentario_creacion, 
                           resultado, 
                           cod_cia, 
                           cod_secc, 
                           num_secu_pol, 
                           num_pol_provisorio, 
                           num_pol1, 
                           estado, 
                           usuario_destino, 
                           comentario_respuesta, 
                           usuario_creacion, 
                           fecha_creacion, 
                           usuario_modificacion, 
                           fecha_modificacion, 
                           num_end)
                   VALUES (sim_seq_seg_ctrl_tecnico.nextval
                          ,:NEW.ID_SOLICITUD
                          ,'Cambio de estado de la solicitud a Datos Adicionales'
                          ,0
                          ,:new.Cod_Cia
                          ,:new.Cod_Secc
                          ,:new.Num_Secu_Pol
                          ,:new.Num_Pol 
                          ,:new.num_pol                        
                          ,'A'
                          ,:NEW.USUARIO_SOLICITUD
                          ,NULL
                          ,:NEW.USUARIO_MODIFICA
                          ,SYSDATE
                          ,NULL
                          ,NULL
                          ,:NEW.num_end);
      ELSIF nvl(:new.estado,'XXXX') IN ('RECH','ATEN') THEN
        -- se inactivan comentarios asociados en la bitácora de seg
        -- para que no sigan saliendo pendientes de lectura
        UPDATE sim_bitacora_seg_ct sbst
           SET sbst.leido = 'S'
          WHERE sbst.id_seg_ctr_tec IN (SELECT ssct.id_controltec
                                          FROM sim_seg_ctroles_tecnicos ssct
                                         WHERE ssct.id_controltec = :NEW.ID_SOLICITUD);
    END IF;
    
  END IF;
end SIM_TRG_VTAS_SOLICITUDES;
/
