CREATE OR REPLACE TRIGGER trg_anular_boletas
  AFTER UPDATE ON a5021700  
  FOR EACH ROW
DECLARE
  -- local variables here
BEGIN
  IF :new.mca_estado = 'C' AND :old.cod_cia = 3 THEN 
     UPDATE t_pago_agrupado_ref a
        SET a.mca_estado ='A'
          , a.fecha_estado = SYSDATE
      WHERE a.mca_estado = 'V'
        AND a.fecha_estado < trunc(SYSDATE -5);
 
     UPDATE t_pago_agrupado_fact a
        SET a.mca_estado ='A'
          , a.fecha_estado = SYSDATE
      WHERE a.mca_estado = 'V'
        AND a.fecha_estado< trunc(SYSDATE -5);
     
     UPDATE t_pago_agrupado_pol a
        SET a.mca_estado ='A'
          , a.fecha_estado = SYSDATE
      WHERE a.mca_estado = 'V'
        AND a.fecha_estado < trunc(SYSDATE -5);
  END IF;
END trg_anular_boletas;
/
