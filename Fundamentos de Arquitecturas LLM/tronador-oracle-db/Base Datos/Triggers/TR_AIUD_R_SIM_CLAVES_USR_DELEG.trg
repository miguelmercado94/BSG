CREATE OR REPLACE TRIGGER TR_AIUD_R_SIM_CLAVES_USR_DELEG
  after insert OR update OR delete on SIM_CLAVES_USUARIO_DELEGADO
  for each row
/*
 Modifica: Ricardo Cabrera - Asesoftware
 Fecha   : Diciembre 14 de 2016 
 Desc    : Se crea el trigger para auditar el borrado, inserción y actualización
           de los registros en la tabla SIM_CLAVES_USUARIO_DELEGADO.
*/
Declare
  v_ope  VARCHAR2(3);
Begin
  If (DELETING OR UPDATING) Then
    If DELETING Then
      v_ope := 'DEL';
    Elsif UPDATING Then
      v_ope := 'UPD';
    End If;
    insert 
      into SIM_CLAVES_USUARIO_DELEGADO_JN
           (
            jn_secuencia,
            jn_operation,
            jn_oracle_user,
            jn_datetime,
            id_claves_usuario,
            id_externo_usuario,   
            clave_codigo_usuario,
            estado_clave,
            usr_creacion,
            fecha_creacion,
            usr_modificacion,
            fecha_modificacion
           )
    values
           (
            SEQ_SIM_CLAVES_USUARIO_DELE_JN.NEXTVAL, 
            v_ope, 
            USER, 
            SYSDATE, 
            :OLD.id_claves_usuario,
            :OLD.id_externo_usuario,   
            :OLD.clave_codigo_usuario,
            :OLD.estado_clave,
            :OLD.usr_creacion,
            :OLD.fecha_creacion,
            :OLD.usr_modificacion,
            :OLD.fecha_modificacion
           );
  Elsif INSERTING Then
    v_ope := 'INS';
      insert 
      into SIM_CLAVES_USUARIO_DELEGADO_JN
           (
            jn_secuencia,
            jn_operation,
            jn_oracle_user,
            jn_datetime,
            id_claves_usuario,
            id_externo_usuario,   
            clave_codigo_usuario,
            estado_clave,
            usr_creacion,
            fecha_creacion,
            usr_modificacion,
            fecha_modificacion
           )
    values
           (
            SEQ_SIM_CLAVES_USUARIO_DELE_JN.NEXTVAL, 
            v_ope,
            USER,
            SYSDATE,
            :NEW.id_claves_usuario,
            :NEW.id_externo_usuario,   
            :NEW.clave_codigo_usuario,
            :NEW.estado_clave,
            :NEW.usr_creacion,
            :NEW.fecha_creacion,
            :NEW.usr_modificacion,
            :NEW.fecha_modificacion
           );
  End IF;
End TR_AIUD_R_SIM_CLAVES_USR_DELEG;
/
