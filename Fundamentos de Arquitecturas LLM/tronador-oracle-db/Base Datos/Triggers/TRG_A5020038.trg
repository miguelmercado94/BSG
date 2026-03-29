CREATE OR REPLACE TRIGGER trg_a5020038
before delete on a5020038 for each row
begin
  if :old.saldo_actual > 0 then  -- tiene saldo
    raise_application_error(-20015,'Cajero NO se puede borrar tiene saldo');
  end if;
exception
  when no_data_found then
	raise_application_error(-20010,'No existe el cajero');
end trg_a5020038;
/
