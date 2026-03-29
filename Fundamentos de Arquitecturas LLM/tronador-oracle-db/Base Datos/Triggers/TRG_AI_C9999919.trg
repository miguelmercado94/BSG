CREATE OR REPLACE TRIGGER TRG_AI_C9999919
  before insert on c9999919
  for each row
begin
  IF :NEW.Cod_Secuencia IS NULL THEN
    :NEW.Cod_Secuencia := SEQ_C9999919.NEXTVAL;
  END IF;
end TRG_AI_C9999919;
/
