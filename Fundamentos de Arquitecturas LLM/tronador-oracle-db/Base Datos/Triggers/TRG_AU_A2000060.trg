CREATE OR REPLACE TRIGGER TRG_AU_A2000060
AFTER UPDATE of MCA_BAJA_CONVENIO
ON A2000060 
FOR EACH ROW
declare
BEGIN
  if :new.CANAL_DESCTO in (1,2,3) then
    IF NVL(:OLD.MCA_BAJA_CONVENIO,'N') = 'N' and NVL(:NEW.MCA_BAJA_CONVENIO,'N') = 'S' THEN
      pkg_eventos_convenios.PCO_CONVENIOS_BLOQUEADOS(:NEW.NUM_SECU_POL,:new.num_end,
	                                                 :new.CAUSAL_BAJA_CONVENIO,:new.CANAL_DESCTO,
													 :new.COD_ENTIDAD,:new.fec_baja_convenio);
    END IF;
  end if;
END;
/
