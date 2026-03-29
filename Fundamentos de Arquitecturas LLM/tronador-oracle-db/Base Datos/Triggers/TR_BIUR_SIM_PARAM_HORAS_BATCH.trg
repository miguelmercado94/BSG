CREATE OR REPLACE TRIGGER tr_biur_sim_param_horas_batch 
  before insert or update of fecha_desde,fecha_hasta 
  on sim_param_horas_batch_banca 
  for each row
declare
  pragma          autonomous_transaction;
  l_conteo        number := 0;
  l_fecha_desde   date   := :new.fecha_desde;
  l_fecha_hasta   date   := :new.fecha_hasta;
  l_msg_error     varchar2(2000);
begin
  if INSERTING then
    select count(1)
      into l_conteo
      from sim_param_horas_batch_banca
     where ( (l_fecha_desde between fecha_desde and fecha_hasta)
           or (l_fecha_hasta between fecha_desde and fecha_hasta) );
  elsif UPDATING then
    select count(1)
      into l_conteo
      from sim_param_horas_batch_banca
     where rowid != :old.rowid
       and ( (l_fecha_desde between fecha_desde and fecha_hasta)
            or (l_fecha_hasta between fecha_desde and fecha_hasta) );
  end if;
  --
  if l_conteo > 0 then 
    l_msg_error := 'Ya existe un rango que contiene alguna de las fechas especificadas, por favor verifique.';
    raise_application_error(-20099, l_msg_error);
  end if;
end tr_biur_sim_param_horas_batch;
/
