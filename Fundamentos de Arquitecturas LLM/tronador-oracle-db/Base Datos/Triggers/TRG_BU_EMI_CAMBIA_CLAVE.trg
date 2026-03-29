CREATE OR REPLACE TRIGGER TRG_BU_EMI_CAMBIA_CLAVE
  before update of clave_intermediario on emi_solicitud_poliza
  for each row
declare
  var_clave number;
begin
  IF :OLD.CLAVE_INTERMEDIARIO <> :NEW.CLAVE_INTERMEDIARIO AND :NEW.CLAVE_INTERMEDIARIO IS NOT NULL THEN
     SELECT COUNT(*)
       INTO var_clave
       FROM EMI_MUTATING EM
      WHERE TABLE_NAME = 'EMI_ACTUALIZA_CLAVE'
        AND EM.NUMERO_SOLICITUD = :NEW.NUMERO_SOLICITUD
        AND EM.MENSAJE = :NEW.CLAVE_INTERMEDIARIO;

      --Se inserta sólo si el cambio es desde la pantalla de intermediario
      if var_clave = 0 then
        INSERT INTO EMI_MUTATING
          (num_rowid, table_name, mensaje, numero_solicitud, codigo_riesgo)
        VALUES
          (:NEW.ROWID,'EMI_SOLICITUD_CLAVE',:OLD.CLAVE_INTERMEDIARIO,:NEW.numero_solicitud, NULL);
        end if;
  END IF;
end TRG_BU_EMI_CAMBIA_CLAVE;
/
