CREATE OR REPLACE TRIGGER actualiza_c9999909_sarlaft
after insert on c1990000
for each row
declare
BEGIN
  --se actualiza dato del monto minimo en pesos para el vr Asegurado sarlaft circular 027
  Begin
    update c9999909 set DAT_OBS = codigo1 * :new.minimo_mes
                       ,DAT_CAR = codigo1 * :new.minimo_mes
    where  cod_tab = 'MIN_VRASEG_SARLAFT';
  exception
     when others then
       RAISE;
  end;
  --se actualiza dato del monto minimo en pesos para el vr PRIMA sarlaft circular 027
  Begin
    update c9999909 set DAT_OBS = codigo1 * :new.minimo_mes
                       ,DAT_CAR = codigo1 * :new.minimo_mes
    where  cod_tab = 'MIN_VRPRIMA_SARLAFT';
  exception
     when others then
       RAISE;
  end;
End actualiza_c9999909_sarlaft;
/
