CREATE OR REPLACE TRIGGER C3150007_TRGSEC
  before insert on c3150007  
  for each row
declare
  -- local variables here
  V_secuencia number(17) := 0;  
BEGIN
  BEGIN
    SELECT SEQ_C3150007.NEXTVAL
    INTO V_secuencia
    FROM DUAL;
  END;

  :new.secuencia := V_secuencia;   
   
end C3150007_TRGSEC;
/
