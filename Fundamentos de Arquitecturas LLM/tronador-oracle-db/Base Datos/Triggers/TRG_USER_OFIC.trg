CREATE OR REPLACE TRIGGER trg_user_ofic
before insert or update on  a5021600
for each row
begin
   declare x number(5) := 0;
begin
  if :new.cod_ofic_contab is not null
      and :new.cod_user is not null
	  and :new.tipo_actu = 'PV'
	  and :new.ind_dato_variable <> 'NN'
	  then
begin
   select 1 into x
   from g1002700
   where cod_agencia = :new.cod_ofic_contab
   and cod_user_cia = :new.cod_user
   and cod_cia = :new.cod_cia
   ;
exception
   when no_data_found then
   begin
	 select 1 into x
	 from a5021107
	 where recibo = :new.recibo;
   exception
	 when no_data_found then
	raise_application_error
	(-20010,'agencia cont no corresp a este usuario:'
	|| :new.cod_user || '*'
	|| to_char(:new.cod_ofic_contab)
	);
   end;
end;
  end if;
end;
end;
/
