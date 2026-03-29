CREATE OR REPLACE TRIGGER trg_a7000900_Cesvi
  AFTER INSERT ON A7000900 
  FOR EACH ROW
WHEN (new.cod_secc = 1 AND new.cod_cia = 3 AND new.cod_ramo = 250)
BEGIN
    sim_pck_acceso_sini2.proc_siniestro_cesv(:new.num_sini,
                                           :new.num_secu_sini,
                                           :new.num_pol1,
                                           :new.num_end,
                                           :new.nro_orden_sini,
                                           :new.nro_documto,
                                           :new.tdoc_tercero_aseg,
                                           :new.fecha_sini,
                                           :new.hora_sini,
                                           :new.num_secu_pol,
                                           :new.cod_ries,
                                           :new.cod_aseg,
                                           :new.ape_aseg,
                                           :new.nom_aseg,
                                           :new.fec_denu_sini);
	
    IF :new.nro_orden_sini = 0 THEN
      sim_pck_bienvenida_oportuna.prc_insert_sim_envios_correos(:new.num_secu_sini,
                                                              :new.nro_orden_sini);
                                                              
      sim_pck_bienvenida_oportuna.prc_insert_correos_inter(:new.cod_cia, :new.cod_secc, :new.cod_ramo,
        :new.num_sini, :new.num_secu_sini, :new.nro_orden_sini,
        :new.num_pol1, :new.num_secu_pol, :new.num_end,
        :new.tdoc_tercero_aseg, :new.cod_aseg, :new.nom_aseg,
        :new.ape_aseg, :new.fecha_sini, :new.cod_prod,1);
    END IF;
                              
EXCEPTION
  WHEN OTHERS THEN
    NULL;
END trg_a7000900_cesvi;
/
