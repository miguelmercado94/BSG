CREATE OR REPLACE TRIGGER TR_UPD_ESTADO_G9999010
  before insert OR update on G9999010
  for each row
declare
  l_Old varchar2(2);
  l_New varchar2(2);
Begin
  IF UPDATING THEN
    IF :new.estado_precobro != :old.estado_precobro then
      :new.usr_modifica_ESTADO:= user;
      :new.fecha_modifica_ESTADO:= sysdate;
      select SIM_PCK_PRECOBROS.Fun_EstadoPrecobro(:old.estado_precobro) into l_Old from dual;
      select SIM_PCK_PRECOBROS.Fun_EstadoPrecobro(:new.estado_precobro) into l_New from dual;
      :new.observaciones := 'Cambio Estado Precobro, Anterior:'||l_Old||' Nuevo:'||l_New;
    END IF;
  END IF;
End TR_UPD_ESTADO_G9999010;
/
