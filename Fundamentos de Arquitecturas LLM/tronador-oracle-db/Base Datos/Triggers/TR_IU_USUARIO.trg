CREATE OR REPLACE TRIGGER TR_IU_USUARIO
AFTER INSERT OR UPDATE
ON USUARIO
FOR EACH ROW
BEGIN
  INSERT INTO HISTORICO_USUARIO (CODIGO_USUARIO
                                ,CODIGO_PERFIL
                                ,CLAVE_USUARIO
                                ,CODIGO_LOCALIDAD
                                ,CONTADOR_ACCESOS
                                ,FECHA_ACTIVACION
                                ,INDICADOR_NIVEL_SUPERVISION
                                ,FECHA_VENCIMIENTO
                                ,ESTADO_USUARIO
                                ,CEDULA_EMPLEADO
                                ,CODIGO_EMPLEADO
                                ,NOMBRE_EMPLEADO
                                ,TELEFONO_EMPLEADO
                                ,FECHA_CREACION
                                ,FECHA_TRANSACCION
                                ,USUARIO_TRANSACCION)
                          VALUES(:NEW.CODIGO_USUARIO
                                ,:NEW.CODIGO_PERFIL
                                ,:NEW.CLAVE_USUARIO
                                ,:NEW.CODIGO_LOCALIDAD
                                ,:NEW.CONTADOR_ACCESOS
                                ,:NEW.FECHA_ACTIVACION
                                ,:NEW.INDICADOR_NIVEL_SUPERVISION
                                ,:NEW.FECHA_VENCIMIENTO
                                ,:NEW.ESTADO_USUARIO
                                ,:NEW.CEDULA_EMPLEADO
                                ,:NEW.CODIGO_EMPLEADO
                                ,:NEW.NOMBRE_EMPLEADO
                                ,:NEW.TELEFONO_EMPLEADO
                                ,:NEW.FECHA_CREACION
                                ,:NEW.FECHA_TRANSACCION
                                ,:NEW.USUARIO_TRANSACCION
                                );
  EXCEPTION WHEN OTHERS THEN
    RAISE_APPLICATION_ERROR (-20044,'ERROR: Al insertar en HISTORICO_USUARIO');
END;
/
