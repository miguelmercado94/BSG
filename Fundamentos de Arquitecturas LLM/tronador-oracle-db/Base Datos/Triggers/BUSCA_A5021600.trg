CREATE OR REPLACE TRIGGER busca_a5021600
before
 update on  a5021600
for each row
declare
cantidad number :=0;
begin
IF :old.cod_benef <> :new.cod_benef then
              insert into control_1600
(cod_cia,     fecha,  cod_benef_ant,cod_benef_new,usuario)
           values
(:old.cod_cia,sysdate,:old.cod_benef,:new.cod_benef ,user);
  end if;
  end;
/
