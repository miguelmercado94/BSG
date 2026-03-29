CREATE OR REPLACE TRIGGER trg_a7000025_cesvi
  AFTER INSERT ON a7000025
  FOR EACH ROW
DECLARE
  v_contar NUMBER(2);
BEGIN
  SELECT COUNT(*)
    INTO v_contar
    FROM a7000900
   WHERE nro_orden_sini = :new.nro_orden_sini
     AND num_secu_sini = :new.num_secu_sini
     AND cod_secc = 1
     AND cod_cia = 3
     AND cod_ramo = 250;
  IF v_contar > 0 THEN
    IF (inserting AND :new.cod_campo = 'BIEN_AFECTADO' AND :new.cod_nivel = 3 AND :new.valor_campo = 'V') THEN
      sim_pck_acceso_sini2.proc_siniestro_cesv(NULL, :new.num_secu_sini, NULL, NULL, :new.nro_orden_sini, NULL, NULL, NULL, NULL, NULL, NULL, :new.cod_grupo, NULL, 'AFCTZTRCRO' || :new.cod_nivel, NULL);
    END IF;
  END IF;
EXCEPTION
  WHEN OTHERS THEN
    NULL;
END trg_a7000025_cesvi;
/
