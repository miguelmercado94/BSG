CREATE OR REPLACE TRIGGER trg_baja_convenio
  after update of fecha_baja on sim_convenio_seguros
  for each row
declare
  -- local variables here
begin
  update sim_convenio_ptosvta set  fecha_baja = :new.fecha_baja
  where convenio = :new.convenio;
  update sim_usuarios_convenios set  fecha_baja = :new.fecha_baja,
                                     causal = 9
  where convenio = :new.convenio;
end trg_baja_convenio;
/
