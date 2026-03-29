CREATE OR REPLACE TRIGGER SIM_TRG_COPROP_AI
AFTER INSERT
  ON A2000030 --OPS$PUMA.A2000030
  FOR EACH ROW
DECLARE
ip_proceso sim_typ_proceso;
op_arrErrores sim_typ_array_error;
op_resultado number;

BEGIN
  IF (    (:NEW.COD_CIA = 3) 
      AND (:NEW.COD_SECC = 4) 
      AND (:NEW.COD_RAMO = 445) 
      AND (:NEW.TIPO_END='AT') 
      AND (
           (TO_DATE(:NEW.FECHA_VIG_POL,'DD/MM/YYYY')) = 
           (TO_DATE(:NEW.FECHA_VIG_END,'DD/MM/YYYY'))
          )
     ) THEN
    -- Inicializando parametros para el procedimiento
    ip_proceso                := NEW sim_typ_proceso();
    ip_proceso.p_cod_cia      := :NEW.COD_CIA;
    ip_proceso.p_cod_secc     := :NEW.COD_SECC;
    ip_proceso.p_cod_producto := :NEW.COD_RAMO;
    IP_PROCESO.P_COD_USR      := :NEW.SIM_USUARIO_CREACION;
    op_arrErrores             := NEW sim_typ_array_error();

    sim_pck_atgc_coop.edicionCopropiedad(ip_proceso,
                                         :NEW.NUM_POL1,
                                         :NEW.NUM_END,
                                         :NEW.NUM_SECU_POL,
                                         :new.tdoc_tercero,
                                         :new.Nro_Documto,
                                         :new.Sec_Tercero,
                                         'ANULA_POLIZA',
                                         op_resultado,
                                         op_arrErrores);

  END IF;

  IF (    (:NEW.COD_CIA = 3) 
      AND (:NEW.COD_SECC = 4) 
      AND (:NEW.COD_RAMO = 445) 
      AND (:NEW.TIPO_END='AT') 
      AND (
           (TO_DATE(:NEW.FECHA_VIG_POL,'DD/MM/YYYY')) <> 
           (TO_DATE(:NEW.FECHA_VIG_END,'DD/MM/YYYY'))
          )
     ) THEN
    -- Inicializando parametros para el procedimiento
    ip_proceso                := NEW sim_typ_proceso();
    ip_proceso.p_cod_cia      := :NEW.COD_CIA;
    ip_proceso.p_cod_secc     := :NEW.COD_SECC;
    ip_proceso.p_cod_producto := :NEW.COD_RAMO;
    IP_PROCESO.P_COD_USR      := :NEW.SIM_USUARIO_CREACION;
    op_arrErrores             := NEW sim_typ_array_error();

    sim_pck_atgc_coop.edicionCopropiedad(ip_proceso,
                                         :NEW.NUM_POL1,
                                         :NEW.NUM_END,
                                         :NEW.NUM_SECU_POL,
                                         :new.tdoc_tercero,
                                         :new.Nro_Documto,
                                         :new.Sec_Tercero,
                                         'CANCELA_POLIZA',
                                         op_resultado,
                                         op_arrErrores);
  END IF;
  
  IF(    (:NEW.COD_CIA = 3)
     AND (:NEW.COD_SECC = 4)
     AND (:NEW.COD_RAMO = 445)
     AND (:NEW.COD_END = 445)
     AND (:NEW.SUB_COD_END = 2)
    ) THEN

    -- Inicializando parametros para el procedimiento
    ip_proceso                := NEW sim_typ_proceso();
    ip_proceso.p_cod_cia      := :NEW.COD_CIA;
    ip_proceso.p_cod_secc     := :NEW.COD_SECC;
    ip_proceso.p_cod_producto := :NEW.COD_RAMO;
    IP_PROCESO.P_COD_USR      := :NEW.SIM_USUARIO_CREACION;
    op_arrErrores             := NEW sim_typ_array_error();

    --Invocar servicio en SIM_PCK_ATGC_COOP
    sim_pck_atgc_coop.edicionCopropiedad(ip_proceso,
                                         :NEW.NUM_POL1,
                                         :NEW.NUM_END,
                                         :NEW.NUM_SECU_POL,
                                         :new.tdoc_tercero,
                                         :new.Nro_Documto,
                                         :new.Sec_Tercero,
                                         'CAMBIO_NDOC',
                                         op_resultado,
                                         op_arrErrores);

  END IF;

  EXCEPTION
  WHEN OTHERS THEN
     sim_proc_log('SIM_TRG_COPROP_AI',sqlcode||' - '||sqlerrm);

END;
/
