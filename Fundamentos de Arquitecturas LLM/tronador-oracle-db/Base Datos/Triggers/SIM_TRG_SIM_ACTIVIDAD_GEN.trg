CREATE OR REPLACE TRIGGER SIM_TRG_SIM_ACTIVIDAD_GEN
  before update on SIM_ACTIVIDAD_GEN
  for each row
begin

    UPDATE SIM_ACTIVIDAD
    SET DESCRIPCION = :new.descripcion
    WHERE COD_ACTIVIDAD = :new.cod_actividad;   

end SIM_TRG_SIM_ACTIVIDAD_GEN;
/
