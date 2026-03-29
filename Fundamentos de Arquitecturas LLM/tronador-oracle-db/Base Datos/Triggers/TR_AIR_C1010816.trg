CREATE OR REPLACE TRIGGER TR_AIR_C1010816
/*
    Modifico : Rolphy Quintero - Asesoftware - German Mu?oz
    fecha :  Febrero 11 de 2016 - Mantis 42926 - Proyecto Castigo de Cartera
    Desc : Creacion del trigger para auditar tabla C1010816.
*/
  AFTER INSERT ON C1010816 FOR EACH ROW
Declare
  vl_Tipo_Operacion  SIM_HISTORIAL_C1010816.Tipo_Operacion%type;
Begin
  If Inserting Then
    vl_Tipo_Operacion := 'C'; -- Creacion
    INSERT INTO SIM_HISTORIAL_C1010816 (SECUENCIA, ROWID_C1010816, FECHA_CREACION_REGISTRO, TIPO_OPERACION,
    COD_SECC, COD_RAMO, COD_PROD, FECHA_CREACION, USUARIO_CREACION)
    VALUES (SEQ_HISTORIAL_C1010816.NEXTVAL, :NEW.ROWID, SYSDATE, vl_Tipo_Operacion,
    :NEW.COD_SECC, :NEW.COD_RAMO, :NEW.COD_PROD, :NEW.FECHA_CREACION, :NEW.USUARIO_CREACION);
  End If;
End TR_AIR_C1010816;
/
