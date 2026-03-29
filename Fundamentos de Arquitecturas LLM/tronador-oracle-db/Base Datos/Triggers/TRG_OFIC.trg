CREATE OR REPLACE TRIGGER trg_ofic
before insert on  a5021600
for each row
begin
   declare x number(5) := 0;
begin
  if :new.cod_ofic_contab is not null then
begin
   select 1 into x
   from a1000702
   where cod_agencia = :new.cod_ofic_contab
   ;
   exception
   when no_data_found then
	raise_application_error
	(-20010,'< agencia contab<'||:new.cod_ofic_contab||'>  no existe en tabla a1000702' );
end;
  end if;
  if :new.cod_ofic_imput is not null then
begin
   select 1 into x
   from a1000702
   where cod_agencia = :new.cod_ofic_imput
   ;
   exception
   when no_data_found then
	raise_application_error
	(-20011,'agencia imput <'||:new.cod_ofic_imput||'> no existe en tabla a1000702' );
end;
  end if;
  if :new.cod_ofic_cial is not null then
begin
   select 1 into x
   from a1000702
   where cod_agencia = :new.cod_ofic_cial
   ;
   exception
   when no_data_found then
	raise_application_error
	(-20012,'agencia cial<'||:new.cod_ofic_cial||'> no existe en tabla a1000702' );
end;
  end if;
end;
end;
/
