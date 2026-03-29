CREATE OR REPLACE TRIGGER TRG_DECENAL_COTPOL
    AFTER UPDATE OF MCA_AUTORIZA ON A2000220
    FOR EACH ROW
DECLARE
  ip_proceso    sim_typ_proceso;
  L_COD_SECC    NUMBER;
  L_ENDOSO      NUMBER;
  OP_RESULTADO  NUMBER;
  op_arrerrores sim_typ_array_error;
BEGIN
   OP_RESULTADO                  := 0;
   Op_arrerrores                 := new sim_typ_array_error();
   ip_proceso                    := NEW sim_typ_proceso;
   ip_proceso.p_cod_cia          := 3;
   ip_proceso.p_cod_secc         := 81;
   ip_proceso.p_cod_producto     := 160;
   L_ENDOSO                      := 0;
   begin
      select DISTINCT T.COD_SECC INTO L_COD_SECC
      from A2000030 t
      where t.num_secu_pol=:OLD.NUM_SECU_POL;
   exception
     when others then
       L_COD_SECC := null;
   end;   
   sim_proc_log('AEEM_CT_CONVERSION','TRIGGER :NEW.MCA_AUTORIZA : '||:NEW.MCA_AUTORIZA||
                                     ' L_COD_SECC : '||L_COD_SECC||
                                     ' :new.cod_error : '||:new.cod_error);
   
   if :new.cod_error=266 and :NEW.MCA_AUTORIZA = 'S' AND L_COD_SECC = 81 THEN
      sim_proc_log('AEEM_CT_CONVERSION','PRE EO');
      begin
         INSERT INTO SIM_DECENAL_CONVERSION
         VALUES(:OLD.NUM_SECU_POL,'N',SYSDATE,NULL);
      exception
        when others then
          null;
      end;   
         
  end if;
EXCEPTION
    WHEN OTHERS THEN
        dbms_output.put_line('Error en la linea : ' || dbms_utility.format_error_backtrace || '. Posible causa: ' || SQLERRM);
        sim_proc_log('AEEM_CT_CONVERSION','Error en la linea : ' || dbms_utility.format_error_backtrace || '. Posible causa: ' || SQLERRM);
END;
/
