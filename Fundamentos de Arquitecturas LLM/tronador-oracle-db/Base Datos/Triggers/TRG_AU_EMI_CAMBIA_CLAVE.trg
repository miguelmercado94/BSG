CREATE OR REPLACE TRIGGER TRG_AU_EMI_CAMBIA_CLAVE
  after update on emi_solicitud_poliza
declare
  var_row     ROWID;
  var_mensaje VARCHAR2(255);
  var_solicitud number;
begin
    BEGIN
    SELECT num_rowid, mensaje, numero_solicitud
      INTO var_row,
           var_mensaje,
           var_solicitud
      FROM EMI_MUTATING
     WHERE table_name = 'EMI_SOLICITUD_CLAVE';

     IF var_mensaje is not null then
       DELETE FROM EMI_COMISIONES EC
        WHERE EC.NUMERO_SOLICITUD = var_solicitud
          AND EC.CLAVE_INTERMEDIARIO = var_mensaje;
     end if;

    EXCEPTION WHEN NO_DATA_FOUND THEN
       NULL;
    END;

end TRG_AU_EMI_CAMBIA_CLAVE;
/
