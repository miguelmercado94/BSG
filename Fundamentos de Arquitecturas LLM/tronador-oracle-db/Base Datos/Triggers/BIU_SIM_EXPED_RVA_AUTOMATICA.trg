CREATE OR REPLACE TRIGGER BIU_SIM_EXPED_RVA_AUTOMATICA
BEFORE INSERT OR UPDATE ON SIM_EXPED_RVA_AUTOMATICA
REFERENCING OLD AS OLD NEW AS NEW
FOR EACH ROW
/*
   MODIFICADO: Rolphy Quintero - Asesoftware
   FECHA : Octubre 23 de 2014 - Mantis 29758
   Desc  : Se crea el trigger para validar dos cosas: la primera, causa-consecuencia- cobertura,
           la segunda, causa, cobertura, tipo de expediente y concepto de reserva.
*/
BEGIN
  SIM_PCK_EXPED_RVA_AUTOMATICA.Proc_Valida_Reserva_Automatica(:NEW.COD_CIA, :NEW.COD_SECC, :NEW.TIPO_EXPED,
  :NEW.COD_CONCEP_RVA, :NEW.COD_COB, :NEW.COD_CAUSA, :NEW.COD_CONS, :NEW.TIPO_CAUSA, :NEW.COD_PRODUCTO);
END BIU_SIM_EXPED_RVA_AUTOMATICA;
/
