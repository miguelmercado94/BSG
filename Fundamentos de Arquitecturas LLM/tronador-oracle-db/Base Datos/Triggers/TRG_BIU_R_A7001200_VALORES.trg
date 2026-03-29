CREATE OR REPLACE TRIGGER TRG_BIU_R_A7001200_VALORES BEFORE INSERT OR UPDATE OF VALOR_ACTUAL, TOTAL_LIQ ON A7001200
FOR EACH ROW
DISABLE
BEGIN
  -- Autor       : Carlos Eduardo Mayorga
  -- Fecha       : 15/04/2015
  -- Descripcion : Trigger a nivel de registro que almacena en la variable de tipo tabla
  --               la lista de expedientes modificados para calcular el estado de reservas
  --               expediente y siniestro Mantis 30035
  -- Version     : 1.0
  -- Incrementa el contador de elementos en la tabla.
  -- Inserta en el ultimo elemento de la tabla el numero de expediente
  SIM_PKG_EST_SINI.VG_CONSECUTIVO := SIM_PKG_EST_SINI.VG_CONSECUTIVO + 1;
  SIM_PKG_EST_SINI.VG_TRESERVAS(SIM_PKG_EST_SINI.VG_CONSECUTIVO) := :NEW.NUM_SECU_EXPED;
END;
/
