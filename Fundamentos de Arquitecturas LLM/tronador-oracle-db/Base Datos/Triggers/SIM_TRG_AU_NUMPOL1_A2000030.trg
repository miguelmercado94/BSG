CREATE OR REPLACE TRIGGER "SIM_TRG_AU_NUMPOL1_A2000030"
  BEFORE UPDATE OF "NUM_POL1" ON A2000030 
  FOR EACH ROW
WHEN (new.cod_cia = 2 AND new.cod_secc IN (26, 34) AND
       new.num_pol1 IS NOT NULL)
BEGIN

  -- Actualizar registros de Tabla de Exclusiones
  UPDATE sim_exclusiones se
     SET se.exc_cotizacion = 'NO'
   WHERE se.exc_num_secu_pol_h = :new.num_secu_pol;

  COMMIT;

EXCEPTION
  WHEN OTHERS THEN
    NULL;
END SIM_TRG_AU_NUMPOL1_A2000030;
/
