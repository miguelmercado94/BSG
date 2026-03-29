CREATE OR REPLACE TRIGGER trg_evt_fin_can_pago_au
    after update of mca_termok on c2000406
begin
    pkg_eventos_tron.pbd_evt_fin_can_pago;
exception
    when others then
        null;
end;
/
