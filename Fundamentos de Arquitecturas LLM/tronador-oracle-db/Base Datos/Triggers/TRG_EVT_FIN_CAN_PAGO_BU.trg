CREATE OR REPLACE TRIGGER trg_evt_fin_can_pago_bu
    before update of mca_termok on c2000406
begin
    trevsebd.pkg_evt_fin_can_pago.newrows := trevsebd.pkg_evt_fin_can_pago.empty;
exception
    when others then
        null;
end trg_evt_fin_can_pago_bu;
/
