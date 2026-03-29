CREATE OR REPLACE TRIGGER SIM_TRG_BIU_INSP_AUTOS
  before INSERT OR UPDATE on sim_inspeccion_autos  
  for each row
declare
  -- local variables here
begin
  IF (:NEW.USUARIO_CREACION = '79468066')
    or (:new.usr_modificacion = '79468066') THEN
    RAISE_APPLICATION_ERROR (-20801,'Codigo inválido para usuario creador / actualizador de inspeccion');
  END IF;
end SIM_TRG_BIU_INSP_AUTOS;
/
