CREATE OR REPLACE TRIGGER TRG_BIUD_R_A7000100
  AFTER INSERT OR UPDATE OR DELETE ON A7000100
  FOR EACH ROW
/*
   MODIFICADO: Rolphy Quintero - Asesoftware
   FECHA : Octubre 27 de 2014 - Mantis 29758
   Desc  : Se crea el trigger para validar dos cosas: la primera, causa-consecuencia- cobertura,
           la segunda, causa, cobertura, tipo de expediente y concepto de reserva, referente a
           la tabla SIM_PCK_EXPED_RVA_AUTOMATICA.
*/
BEGIN
  If (NVL(:NEW.COD_CIA,-1) != NVL(:OLD.COD_CIA,-1)) OR
     (NVL(:NEW.COD_SECC,-1) != NVL(:OLD.COD_SECC,-1)) OR
     (NVL(:NEW.TIPO_EXPED,'-') != NVL(:OLD.TIPO_EXPED,'-')) OR
     (NVL(:NEW.COD_CONCEP_RVA,-1) != NVL(:OLD.COD_CONCEP_RVA,-1)) OR
     (NVL(:NEW.COD_COB,-1) != NVL(:OLD.COD_COB,-1)) OR
     (NVL(:NEW.COD_CAUSA,-1) != NVL(:OLD.COD_CAUSA,-1)) OR
     (NVL(:NEW.COD_CONS,-1) != NVL(:OLD.COD_CONS,-1)) OR
     (NVL(:NEW.ESTADO,'-') != NVL(:OLD.ESTADO,'-')) Then
    If Inserting Then
      SIM_PCK_EXPED_RVA_AUTOMATICA.Proc_Valida_Conf_A7000100(:NEW.COD_CIA, :NEW.COD_SECC,
      :NEW.TIPO_EXPED, :NEW.COD_CONCEP_RVA, :NEW.COD_COB, :NEW.COD_CAUSA, :NEW.COD_CONS, :NEW.ESTADO, 'I');
    Elsif Updating Then
      SIM_PCK_EXPED_RVA_AUTOMATICA.Proc_Valida_Conf_A7000100(:NEW.COD_CIA, :NEW.COD_SECC,
      :NEW.TIPO_EXPED, :NEW.COD_CONCEP_RVA, :NEW.COD_COB, :NEW.COD_CAUSA, :NEW.COD_CONS, :NEW.ESTADO, 'U');
    Elsif Deleting Then
      SIM_PCK_EXPED_RVA_AUTOMATICA.Proc_Valida_Conf_A7000100(:OLD.COD_CIA, :OLD.COD_SECC,
      :OLD.TIPO_EXPED, :OLD.COD_CONCEP_RVA, :OLD.COD_COB, :OLD.COD_CAUSA, :OLD.COD_CONS, :OLD.ESTADO, 'D');
    End If;
  End If;
End TRG_BIUD_R_A7000100;
/
