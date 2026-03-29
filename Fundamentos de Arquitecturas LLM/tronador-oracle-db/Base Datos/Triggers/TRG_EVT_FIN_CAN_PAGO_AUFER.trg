CREATE OR REPLACE TRIGGER trg_evt_fin_can_pago_aufer
    after update of mca_termok on c2000406
    for each row
WHEN (old.mca_termok is null and new.mca_termok = 'S')
begin
    trevsebd.pkg_evt_fin_can_pago.newrows(trevsebd.pkg_evt_fin_can_pago.newrows.count + 1) := :new.rowid;
exception
    when others then
        null;
end;
/
