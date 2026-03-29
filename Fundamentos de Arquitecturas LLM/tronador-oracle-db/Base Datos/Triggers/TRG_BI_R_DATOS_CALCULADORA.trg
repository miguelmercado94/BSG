CREATE OR REPLACE TRIGGER TRG_BI_R_DATOS_CALCULADORA
/*
   CREADO : Regner Leonardo Bernal Garnica
   FECHA  : 20-08-2021 - TI-693
   Desc   : Se crea el trigger para asignar la secuencia al campo iddatoscalculadora
            que se definio como PRIMARY KEY.
*/
  BEFORE INSERT ON SIM_DATOS_CALCULADORA_SINI
  FOR EACH ROW
BEGIN
   :NEW.IDDATOSCALCULADORA   :=  SEQ_DATOS_CALCULADORA.NEXTVAL;
End TRG_BI_R_DATOS_CALCULADORA;
/
