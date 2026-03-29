CREATE OR REPLACE TRIGGER TRG_AU_SIM_ANTICIPOS_DEC
-- Este trigger evalua si se actualizan los campos de recaudo
-- si se actualiza se procede a generar el prestamo de la comision al agente

AFTER UPDATE ON SIM_ANTICIPOS_DEC 
FOR EACH ROW
  WHEN (NEW.FECHA_RECAUDO IS NOT NULL AND OLD.FECHA_RECAUDO IS NULL)
DECLARE
   merror                     varchar2(500) := null;
   prog                       varchar2(30)  := 'TRIGGER AU_SIM_ANTICIPOS_DEC';
   ip_proceso sim_typ_proceso;
   op_arrerrores sim_typ_array_error;
BEGIN
   
    Begin
       sim_pck_decenal.proc_crear_prestamo(:old.num_secu_pol_tc,:old.num_end_tc);
    Exception
       When others then sim_proc_log('Falla TRG_AU_SIM_ANTICIPOS_dEC',sqlerrm);
    End;

EXCEPTION
WHEN OTHERS THEN
   merror := prog||sqlerrm;
   raise_application_error(-20008, merror);
END;
/
