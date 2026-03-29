CREATE OR REPLACE TRIGGER TRG_BI_R_A7000100
  BEFORE INSERT ON A7000100
  FOR EACH ROW
/*
   CREADO : Carlos Becerra Quiroga
   FECHA  : Diciembre 29 de 2016 - Mantis 50152
   Desc   : Se crea el trigger para asignar la secuencia al nuevo campo ID_A7000100
            que se definio como PRIMARY KEY.
*/
BEGIN
   :NEW.ID_A7000100   :=  SEQ_A7000100.NEXTVAL;
End TRG_BI_R_A7000100;
/
