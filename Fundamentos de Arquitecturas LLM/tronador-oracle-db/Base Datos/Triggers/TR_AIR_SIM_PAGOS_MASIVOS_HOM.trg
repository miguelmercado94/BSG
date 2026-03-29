CREATE OR REPLACE TRIGGER "TR_AIR_SIM_PAGOS_MASIVOS_HOM"
 
  AFTER
  INSERT ON SIM_PAGOS_MASIVOS_HOM FOR EACH ROW
DECLARE vl_Tipo_Operacion SIM_HISTORIAL_PAGOS_MASIVOS.Tipo_Operacion%type;
  vl_ip_equipo_maquina SIM_HISTORIAL_PAGOS_MASIVOS.IP_EQUIPO_MAQUINA%TYPE;
BEGIN
  IF Inserting THEN
    vl_Tipo_Operacion    := 'C'; -- Creación
    vl_ip_equipo_maquina := 'IP: '||sys_context
    (
      'USERENV','ip_address'
    )
    ||', Host: '||sys_context
    (
      'USERENV','host'
    )
    ;
    INSERT
    INTO SIM_HISTORIAL_PAGOS_MASIVOS
      (
        SECUENCIA_HISTORIAL,
        TIPO_OPERACION,
        ROWID_PAGOS_MASIVOS,
        COD_CIA,
        COD_SECC,
        NUM_POL1,
        NUM_FACTURA,
        PAGO_TOTAL_PARCIAL,
        VALOR_PRIMA,
        FECHA_CREACION,
        USUARIO_CREACION,
        FECHA_MODIFICACION,
        USUARIO_MODIFICACION,
        SECUENCIA_PAGOS,
        ESTADO,
        TIPO_CARGUE,
        MENSAJE_ERROR,
        USUARIO_OPERACION,
        IP_EQUIPO_MAQUINA,
        FECHA_CARGUE,
        NUMERO_RECIBO
      )
      VALUES
      (
        SEQ_HISTORIAL_PAGOS_MASIVOS.NEXTVAL,
        vl_Tipo_Operacion,
        :NEW.ROWID,
        :NEW.COD_CIA,
        :NEW.COD_SECC,
        :NEW.NUM_POL1,
        :NEW.NUM_FACTURA,
        :NEW.PAGO_TOTAL_PARCIAL,
        :NEW.VALOR_PRIMA,
        :NEW.FECHA_CREACION,
        :NEW.USUARIO_CREACION,
        :NEW.FECHA_MODIFICACION,
        :NEW.USUARIO_MODIFICACION,
        :NEW.SECUENCIA_PAGOS,
        :NEW.ESTADO,
        :NEW.TIPO_CARGUE,
        :NEW.MENSAJE_ERROR,
        :NEW.USUARIO_CREACION,
        vl_ip_equipo_maquina,
        :NEW.FECHA_CARGUE,
        :NEW.NUMERO_RECIBO
      );
  END IF;
END TR_AIR_SIM_PAGOS_MASIVOS_HOM;
/
