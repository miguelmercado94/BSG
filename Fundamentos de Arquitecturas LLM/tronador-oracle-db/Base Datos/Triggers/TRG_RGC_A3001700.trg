CREATE OR REPLACE TRIGGER trg_rgc_a3001700
  AFTER INSERT OR UPDATE ON a3001700 
  FOR EACH ROW
WHEN (new.cod_secc = 310 AND new.cod_cia = 3 AND new.fecha_pago IS NOT NULL)
DECLARE
  -------------------------------------------------------------------------------
  -- Objetivo : Identificar cuando se elabora una liquidación de Soat para informar
  --            a RGC via servicio el pago efecturado
  -- Autor    : Alvaro Bohorquez - Seguros Bolivar
  -- Fecha    : 24/02/2020
  -------------------------------------------------------------------------------

BEGIN

  sim_pck_NOTIFICAr_LIQRGC.proc_inserta_lirgc(:new.num_ord_pago, :new.total_bruto_liq, :new.fecha_pago, :new.cod_cia, :new.cod_secc, :new.num_sini);

EXCEPTION
  WHEN OTHERS THEN
    NULL;
END trg_ai_r_a3001700;
/
