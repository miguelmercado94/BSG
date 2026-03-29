CREATE OR REPLACE TRIGGER ACTUALIZA_TIPO_COMISION
  before insert on a2000250
  for each row
WHEN (new.for_actuacion = 'PR')
begin
if :new.for_actuacion = 'PR' then
   :new.tipo_comision := 'P';
end if;
end ACTUALIZA_TIPO_COMISION;
/
