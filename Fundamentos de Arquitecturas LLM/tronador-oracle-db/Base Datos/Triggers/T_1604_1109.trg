CREATE OR REPLACE TRIGGER t_1604_1109
before
insert on a5021604
for each row
declare
cantidad number :=0;
begin
   if :new.sub_tipo_ord is not null then
   begin
	  select 1 into cantidad
	  from a5021109
	  where sub_tipo_ord = :new.sub_tipo_ord;
	  exception
	  when no_data_found then
   raise_application_error(
-20500,'Subtipo orden no existe en tabla a5021109,rectifique');
	  when too_many_rows then
		null;
      when others then
	  null;
   end;
  end if;
end;
/
