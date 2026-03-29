CREATE OR REPLACE TRIGGER trg_sim_deuda_poliza
  BEFORE INSERT ON sim_deuda_poliza
  FOR EACH ROW
BEGIN
  --20180222 Creado por Alvaro Bohorquez y Sheila Uhia para que cuando haya separación de riesgo y ahorro 
  --o programación de ahorro extraordinario para VPA, se separe en deudas diferentes el riesgo y el ahorro normal
  --y ahorro extraordinario
  if :new.num_pol1 = :new.num_pol_pse then
    --Cuando sea el riesgo, se marca que sólo es riesgo (no hay ahorro)
    IF :new.valor_fpu = 0 AND :new.valor_fap = -102 THEN
      :new.mca_vida_ahorro := 'S';
      --Cuando sea el ahorro, se marca que tiene Ahorro y se le quita la anualidad a la póliza y se envía
      --en el campo valor_riesgo para que luego Pagos Electrónicos pueda enviar el número completo de la póliza.
      --También se deja el num_pol_pse sin la anualidad
    ELSIF (:new.valor_fpu > 0 AND :new.valor_fap = -102) THEN
      --Separación Ahorro
      :new.valor_riesgo    := '1' || substr(:new.num_pol1, 12);
      :new.num_pol1        := substr(:new.num_pol1, 1, 11);
      :new.num_pol_pse     := :new.num_pol1;
      :new.mca_vida_ahorro := 'A';
      --Cuando es ahorro extraordinario, se marca que tiene Ahorro y se le quita la anualidad a la póliza y se envía 
      --en el campo valor_fap para que luego Pagos Electrónicos pueda enviar el número completo de la póliza.
      --También se deja el num_pol_pse sin la anualidad
    elsif :new.valor_riesgo = -815 then
      :new.valor_fap       := '1' || substr(:new.num_pol1, 12);
      :new.num_pol1        := substr(:new.num_pol1, 1, 11);
      :new.num_pol_pse     := :new.num_pol1;
      :new.mca_vida_ahorro := 'A';
    END IF;
  end if;
END;
/
