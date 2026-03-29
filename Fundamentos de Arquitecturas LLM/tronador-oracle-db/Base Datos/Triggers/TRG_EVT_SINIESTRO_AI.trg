CREATE OR REPLACE TRIGGER trg_evt_siniestro_ai
after insert on a7001200 for each row
WHEN (new.valor_movim > 5000000)
begin
    if inserting
    then
        begin
            pkg_eventos_siniestros.buscar_siniestro(:new.num_secu_sini,
                                                    :new.num_secu_exped,
                                                    :new.cod_cob,
                                                    :new.nro_orden_exp,
                                                    :new.valor_movim);
        exception
            when others then
                null;
        end;
    end if;
end trg_evt_siniestro_ai;
/
