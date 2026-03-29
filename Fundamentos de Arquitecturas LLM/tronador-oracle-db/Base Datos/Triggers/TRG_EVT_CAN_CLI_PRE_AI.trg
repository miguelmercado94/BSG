CREATE OR REPLACE TRIGGER trg_evt_can_cli_pre_ai
    after update of mca_term_ok on a2000030
    for each row
WHEN (new.mca_term_ok = 'S' and new.tipo_end = 'AT' and
         new.cod_end != 900 and new.sub_cod_end != 89)
begin
    pkg_eventos_tron.pbd_cancelacion_preferencial(:new.cod_prod,
                                                  :new.num_secu_pol,
                                                  :new.num_end,
                                                  :new.cod_cia,
                                                  :new.cod_ramo,
                                                  :new.cod_secc,
                                                  :new.num_pol1,
                                                  :new.fecha_vig_pol,
                                                  :new.fecha_venc_pol,
                                                  :new.fecha_vig_end,
                                                  :new.tipo_end,
                                                  :new.mca_anu_pol,
                                                  :new.nro_documto);
exception
    when others then
        null;
end;
/
