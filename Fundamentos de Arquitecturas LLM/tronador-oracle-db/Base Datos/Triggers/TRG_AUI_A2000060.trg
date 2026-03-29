CREATE OR REPLACE TRIGGER TRG_AUI_A2000060
before INSERT OR UPDATE ON A2000060 
FOR EACH ROW
BEGIN
  IF (INSERTING and NVL(:NEW.COD_IDENTIF,0) <> 0 ) or
     (updating  and NVL(:NEW.COD_IDENTIF,0) <>  NVL(:OLD.COD_IDENTIF,0))  THEN
    BEGIN
	 IF NVL(:NEW.COD_IDENTIF,0) <> 0 THEN
	   :new.tipdoc_ctahabiente := PCK_DEBITO_AUTOMATICO.FCO_RETORNA_DOCUMENTO(:new.cod_identif
	                                     ,:new.secter_ctahabiente);
	 END IF;
	END;
  END IF;
  exception when others then null;
END;
/
