CREATE OR REPLACE TRIGGER trg_a502_recaudo_e
  BEFORE INSERT ON a502_recaudo_e
  FOR EACH ROW
BEGIN
  IF :new.no_autorizacion is null THEN
    :new.no_autorizacion := to_char(:new.cod_transaccion);
  END IF;
END trg_a502_recaudo_e;
/
