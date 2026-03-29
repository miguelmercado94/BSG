CREATE OR REPLACE TRIGGER TR_BUDR_SIM_PAGOS_MASIVOS
/*
    Modifico : Rolphy Quintero - Asesoftware - Germán Muñoz
    fecha :  Agosto 2 de 2017 - Mantis 55555
    Desc :  Se adiciona la información de la IP, máquina y usuario de
            la base de datos que esta realizando la operación.

    Modifico : Rolphy Quintero - Asesoftware - Germán Muñoz
    fecha :  Julio 28 de 2017 - Mantis 55555
    Desc : Se adiciona a la auditoría las columnas: SECUENCIA_PAGOS, ESTADO,
           TIPO_CARGUE y MENSAJE_ERROR. También se adiciona la generación
           de error, cuando se intenta borrar un registro en estado P-Pagado.

    Modifico : Rolphy Quintero - Asesoftware - Germán Muñoz
    fecha :  Julio 24 de 2017 - Mantis 55555
    Desc : Creación del trigger. Auditar tabla SIM_PAGOS_MASIVOS,
           cuando se actualice o elimine un registro.
*/
  BEFORE UPDATE OR DELETE ON SIM_PAGOS_MASIVOS FOR EACH ROW
Declare
  vl_Tipo_Operacion  SIM_HISTORIAL_PAGOS_MASIVOS.Tipo_Operacion%type;
  vl_ip_equipo_maquina  SIM_HISTORIAL_PAGOS_MASIVOS.IP_EQUIPO_MAQUINA%TYPE;
Begin
  vl_ip_equipo_maquina := 'IP: '||sys_context('USERENV','ip_address')||', Host: '||sys_context('USERENV','host');
  If Updating Then
    vl_Tipo_Operacion := 'A'; -- Actualización
    If NVL(:NEW.ESTADO,'0') != 'P' AND NVL(:OLD.ESTADO,'0') = 'P' Then -- Pagado
      raise_application_error(-20001,'No se puede actualizar un registro pagado');
    End If;
    INSERT INTO SIM_HISTORIAL_PAGOS_MASIVOS (SECUENCIA_HISTORIAL, TIPO_OPERACION, ROWID_PAGOS_MASIVOS, 
    COD_CIA, COD_SECC, NUM_POL1, NUM_FACTURA, PAGO_TOTAL_PARCIAL, VALOR_PRIMA, FECHA_CREACION,
    USUARIO_CREACION, FECHA_MODIFICACION, USUARIO_MODIFICACION,
    SECUENCIA_PAGOS, ESTADO, TIPO_CARGUE, MENSAJE_ERROR, USUARIO_OPERACION, IP_EQUIPO_MAQUINA, FECHA_CARGUE,
    NUMERO_RECIBO)
    VALUES (SEQ_HISTORIAL_PAGOS_MASIVOS.NEXTVAL, vl_Tipo_Operacion, :NEW.ROWID,
    :NEW.COD_CIA, :NEW.COD_SECC, :NEW.NUM_POL1, :NEW.NUM_FACTURA, :NEW.PAGO_TOTAL_PARCIAL, :NEW.VALOR_PRIMA, :NEW.FECHA_CREACION,
    :NEW.USUARIO_CREACION, :NEW.FECHA_MODIFICACION, :NEW.USUARIO_MODIFICACION,
    :NEW.SECUENCIA_PAGOS, :NEW.ESTADO, :NEW.TIPO_CARGUE, :NEW.MENSAJE_ERROR, NVL(:NEW.USUARIO_MODIFICACION,USER), vl_ip_equipo_maquina, :NEW.FECHA_CARGUE,
    :NEW.NUMERO_RECIBO);
  Elsif Deleting Then
    vl_Tipo_Operacion := 'B'; -- Borrado
    If :OLD.ESTADO = 'P' Then -- Pagado
      raise_application_error(-20001,'No se puede borrar un registro pagado');
    End If;
    /*INSERT INTO SIM_HISTORIAL_PAGOS_MASIVOS (SECUENCIA_HISTORIAL, TIPO_OPERACION, ROWID_PAGOS_MASIVOS,
    COD_CIA, COD_SECC, NUM_POL1, NUM_FACTURA, PAGO_TOTAL_PARCIAL, VALOR_PRIMA, FECHA_CREACION,
    USUARIO_CREACION, FECHA_MODIFICACION, USUARIO_MODIFICACION,
    SECUENCIA_PAGOS, ESTADO, TIPO_CARGUE, MENSAJE_ERROR, USUARIO_OPERACION, IP_EQUIPO_MAQUINA, FECHA_CARGUE,
    NUMERO_RECIBO)
    VALUES (SEQ_HISTORIAL_PAGOS_MASIVOS.NEXTVAL, vl_Tipo_Operacion, :OLD.ROWID,
    :OLD.COD_CIA, :OLD.COD_SECC, :OLD.NUM_POL1, :OLD.NUM_FACTURA, :OLD.PAGO_TOTAL_PARCIAL, :OLD.VALOR_PRIMA, :OLD.FECHA_CREACION,
    :OLD.USUARIO_CREACION, :OLD.FECHA_MODIFICACION, :OLD.USUARIO_MODIFICACION,
    :OLD.SECUENCIA_PAGOS, :OLD.ESTADO, :OLD.TIPO_CARGUE, :OLD.MENSAJE_ERROR, USER, vl_ip_equipo_maquina, :OLD.FECHA_CARGUE,
    :OLD.NUMERO_RECIBO);*/
  End If;
End TR_BUDR_SIM_PAGOS_MASIVOS;
/
