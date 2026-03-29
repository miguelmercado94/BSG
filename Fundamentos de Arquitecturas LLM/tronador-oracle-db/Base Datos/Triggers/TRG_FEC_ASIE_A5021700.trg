CREATE OR REPLACE TRIGGER trg_fec_asie_A5021700
BEFORE UPDATE OF fec_asiento ON A5021700 
FOR EACH ROW
DECLARE
V_fec_asiento_old	OPS$PUMA.A5021700.fec_asiento%type;
BEGIN
	V_fec_asiento_old := :old.fec_asiento;
	OPS$PUMA.PCK_CONSISTENCIA_TESORERIA.prc_Valida_a5021700(:New.COD_CIA,:New.fec_asiento,V_fec_asiento_old);
	
  EXCEPTION
   WHEN OTHERS THEN
    null;
END;
/
