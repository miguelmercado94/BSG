CREATE OR REPLACE TRIGGER TRG_C2700345_HISTORICO
		  BEFORE INSERT OR UPDATE ON C2700345
FOR EACH ROW
begin
 if inserting then
   insert into C2700350
   (nit, num_pol1, dia, hora_inicial_ant, hora_final_ant, hora_inicial_nue, hora_final_nue)
   values
   (:new.nit, :new.num_pol1, :new.dia, null, null, :new.hora_inicial, :new.hora_final);
 elsif updating then
    if (:new.hora_inicial != :old.hora_inicial) or
       (:new.hora_final != :old.hora_final) then
       insert into C2700350
       (nit, num_pol1, dia, hora_inicial_ant, hora_final_ant, hora_inicial_nue, hora_final_nue)
       values
       (:new.nit, :new.num_pol1, :new.dia, :old.hora_inicial, :old.hora_final, :new.hora_inicial, :new.hora_final);
   end if;
 end if;
exception when others then null;
end;
/
