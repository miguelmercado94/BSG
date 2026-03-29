CREATE OR REPLACE TRIGGER SIM_TRG_AI_A2000030
  AFTER INSERT ON A2000030
  FOR EACH ROW
DECLARE
  IP_PROCESO SIM_TYP_PROCESO;
  OP_ARRERRORES sim_typ_array_error;
  OP_RESULTADO NUMBER;
BEGIN
  IF ((:NEW.COD_CIA = 3) AND
      (:NEW.COD_SECC= 4) AND
      (:NEW.COD_RAMO = 445) AND
      (:NEW.TIPO_END is null)
     ) THEN
    ip_proceso :=NEW sim_typ_proceso();
    ip_proceso.p_cod_cia := :NEW.COD_CIA;
    ip_proceso.p_cod_secc:= :NEW.COD_SECC;
    ip_proceso.p_cod_producto:= :NEW.COD_RAMO;
    IP_PROCESO.P_COD_USR     := :NEW.SIM_USUARIO_CREACION;
    op_arrErrores := NEW sim_typ_array_error();
    sim_pck_atgc_coop.registrarUsuario(ip_proceso
                                      ,:NEW.NUM_POL1
                                      ,:NEW.NUM_END
                                      ,:NEW.NUM_SECU_POL
                                      ,:new.tdoc_tercero
                                      ,:new.Nro_Documto
                                      ,:new.Sec_Tercero
                                      ,op_resultado
                                      ,op_arrErrores);
  END IF;
         ----------------------------------------------------------------------
         --Se adiciona código para el proyecto de recorridos cuando se cancela
         --la póliza se debe registrar en traza y luego enviar inf. a scope
         ----------------------------------------------------------------------

  IF ((:NEW.COD_CIA = 3) AND
      (:NEW.COD_SECC= 1) AND
      (:NEW.COD_RAMO = 250)) THEN
      IF :new.sim_subproducto = 376 and nvl(:new.tipo_end,'XX') IN ('AT') THEN
         SIM_PCK_SINCRONIZACION.Proc_Sincroniza_Subprod(
                                  :new.cod_cia,
                                  :new.cod_secc,
                                  :new.cod_ramo,
                                  :new.Num_secu_pol,
                                  :new.Num_end,
                                  :new.sim_subproducto,
                                  :new.tipo_end,
                                  :new.cod_end,
                                  :new.sub_cod_end,
                                  :new.fecha_vig_end,
                                  :new.fecha_vig_pol,
                                  :new.fecha_venc_pol,
                                  :new.mca_anu_pol,
                                  :new.cod_usr,
                                  :new.num_pol1,
                                  :new.sim_usuario_creacion,
                                  Op_Resultado);
      END IF;
  END IF;
EXCEPTION
  WHEN OTHERS THEN
     sim_proc_log('SIM_TRG_AI_A2000030',sqlcode||' - '||sqlerrm);
END SIM_TRG_AI_A2000030;
/
