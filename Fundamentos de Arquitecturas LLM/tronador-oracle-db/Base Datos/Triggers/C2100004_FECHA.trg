CREATE OR REPLACE TRIGGER c2100004_fecha
  before insert
  on C2100004
  for each row
declare
  -- local variables here
begin
  UPDATE C2100004 set fecha_baja = :NEW.FECHA_VIG - 1
  WHERE fecha_baja IS NULL
  AND COD_RAMO     = :NEW.COD_RAMO
  AND OPCION       = :NEW.OPCION
  AND ALTERNATIVA  = :NEW.ALTERNATIVA
  AND PROCESO      = :NEW.PROCESO
  AND SUB_PRODUCTO = :NEW.SUB_PRODUCTO
  AND PERIODO_FACT = :NEW.PERIODO_FACT
  AND COD_COB      = :NEW.COD_COB;
end c2100004_fecha;
/
