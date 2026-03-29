CREATE OR REPLACE TRIGGER C2990540_RECH_CTRL_TEC
AFTER INSERT  ON c2990540
FOR EACH ROW
BEGIN
  CASE
    WHEN :NEW.ESTADO NOT IN ('A','S','P') AND :NEW.NUM_POL IS NOT NULL AND
         :NEW.COD_CIA = 3 AND :NEW.COD_SECCION = 1 AND :NEW.COD_RAMO = 250 THEN
      BEGIN
        PKG_ENVIO_CORREOS.RECHAZOCONTROLTECNICO(p_consecutivo            => :NEW.CONSECUTIVO,
                                                p_num_pol                => :NEW.NUM_POL,
                                                p_cod_ramo               => :NEW.COD_RAMO,
                                                p_cod_cia                => :NEW.COD_CIA,
                                                p_cod_seccion            => :NEW.COD_SECCION,
                                                p_num_end                => :NEW.NUM_END,
                                                p_num_secu_pol           => :NEW.NUM_SECU_POL,
                                                p_solicitante            => :NEW.SOLICITANTE,
                                                p_observaciones          => :NEW.OBSERVACIONES,
                                                p_cod_stellent           => :NEW.COD_STELLENT,
                                                p_estado                 => :NEW.ESTADO,
                                                p_fecha_operacion        => :NEW.FECHA_OPERACION,
                                                p_tipo_negocio           => :NEW.TIPO_NEGOCIO,
                                                p_tipo_error             => :NEW.TIPO_ERROR,
                                                p_tipo_modificacion      => :NEW.TIPO_MODIFICACION,
                                                p_cod_causal             => :NEW.COD_CAUSAL);
      EXCEPTION
        WHEN OTHERS THEN
             NULL;
      END;
    ELSE
       NULL;
  END CASE;
END;
/
