CREATE OR REPLACE TRIGGER TR_IU_TAREA_PERFIL
BEFORE INSERT  OR UPDATE
ON TAREA_PERFIL
FOR EACH ROW
BEGIN
  INSERT INTO HISTORICO_TAREA_PERFIL (CODIGO_TAREA
                                     ,CODIGO_PERFIL
                                     ,PERMISO_EJECUTAR
                                     ,PERMISO_IMPRIMIR
                                     ,PERMISO_ACTUALIZACION
                                     ,PERMISO_ADICIONAR
                                     ,PERMISO_BORRAR
                                     ,PERMISO_CONSULTAR
                                     ,FECHA_TRANSACCION
                                     ,USUARIO_TRANSACCION
                                     )
                              VALUES(:NEW.CODIGO_TAREA
                                    ,:NEW.CODIGO_PERFIL
                                    ,:NEW.PERMISO_EJECUTAR
                                    ,:NEW.PERMISO_IMPRIMIR
                                    ,:NEW.PERMISO_ACTUALIZACION
                                    ,:NEW.PERMISO_ADICIONAR
                                    ,:NEW.PERMISO_BORRAR
                                    ,:NEW.PERMISO_CONSULTAR
                                    ,:NEW.FECHA_TRANSACCION
                                    ,:NEW.USUARIO_TRANSACCION
                                    );
                                      EXCEPTION WHEN OTHERS THEN
    RAISE_APPLICATION_ERROR (-20043,'ERROR: Al insertar en HISTORICO_TAREA_PERFIL');
END;
/
