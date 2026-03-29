CREATE OR REPLACE TRIGGER VERIFICA_MCA_EXCLUSIVO
  BEFORE INSERT OR UPDATE OR DELETE ON A2000030
  FOR EACH ROW
  WHEN (new.MCA_EXCLUSIVO = new.MCA_EXCLUSIVO) --'N')
DECLARE
  l_existe   NUMBER;
  l_habilita VARCHAR2(1);
  l_fecha    DATE;
BEGIN

  BEGIN
    SELECT b.dat_obs, b.fecha_act
      INTO l_habilita, l_fecha
      FROM c9999909 b
     WHERE b.cod_tab = 'ENABLE_MCA_EXCLUSIVO';
  EXCEPTION
    WHEN no_data_found THEN
      l_habilita := 'N';
    WHEN OTHERS THEN
      l_habilita := 'N';
  END;

  IF l_habilita = 'S' AND :new.Fecha_Emi >= l_fecha THEN
    SELECT COUNT(*)
      INTO l_existe
      FROM c2000250_detalle a
     WHERE a.num_secu_pol = :new.num_secu_pol
       AND a.num_end = :new.Num_End;
  
    IF l_existe = 0 THEN
      SIM_PCK_AGRUP_COMISIONES.PRC_COMISIONES(:new.num_secu_pol,
                                              :new.num_end,
                                              :new.Tipo_End,
                                              :new.Cod_Cia,
                                              :new.Cod_Secc,
                                              :new.Cod_Ramo,
                                              :new.Cod_Mon,
                                              :new.Num_Pol1);
    END IF;
  END IF;
END;
/
