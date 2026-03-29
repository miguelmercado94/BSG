CREATE OR REPLACE TRIGGER SIM_TRG_BI_DEDUCIB_PRDCTO
/* <Creacion>
   <Autor>Carlos Eduardo Becerra</Autor>
   <Fecha>02/04/2021</Fecha>
   <Objetivo>Llenar los campos de auditoria</Objetivo>
   /Creacion>
    */
BEFORE INSERT ON SIM_DEDUCIBLES_PRODUCTO 
FOR EACH ROW
BEGIN
  SELECT SEQ_DEDUCIB_PRDCTO.NEXTVAL
  INTO   :NEW.SECUENCIA
  FROM   DUAL;
END;
/
