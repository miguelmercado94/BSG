CREATE OR REPLACE TRIGGER TR_AIUD_R_SIM_EXTERNO_USUARIO
  after insert OR update OR delete on SIM_EXTERNO_USUARIO
  for each row
/*
 Modifica: Ricardo Cabrera - Asesoftware
 Fecha   : Diciembre 14 de 2016 
 Desc    : Se crea el trigger para auditar el borrado, inserción y actualización
           de los registros en la tabla SIM_EXTERNO_USUARIO.
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
      into SIM_EXTERNO_USUARIO_JN
           (
            JN_SECUENCIA, 
            JN_OPERATION, 
            JN_ORACLE_USER, 
            JN_DATETIME, 
            id_externo_usuario,
            tipo_doc_usuario,
            num_doc_usuario,
            tipo_usuario,
            estado_usuario,
            tipo_doc_entidad,
            num_doc_entidad,
            usuario_creacion,
            fecha_creacion,
            usuario_modificacion,
            fecha_modificacion,
            nombre_usuario,
            codigo_perfil,
            codigo_empleado,
            codigo_localidad,
            cod_secc,
            cod_cia,
            cod_cia_name,
            fecha_activacion,
            fecha_vencimiento,
            id_entidad
           )
    values
           (
            SEQ_SIM_EXTERNO_USUARIO_JN.NEXTVAL, 
            v_ope, 
            USER, 
            SYSDATE, 
            :OLD.id_externo_usuario,
            :OLD.tipo_doc_usuario,
            :OLD.num_doc_usuario,
            :OLD.tipo_usuario,
            :OLD.estado_usuario,
            :OLD.tipo_doc_entidad,
            :OLD.num_doc_entidad,
            :OLD.usuario_creacion,
            :OLD.fecha_creacion,
            :OLD.usuario_modificacion,
            :OLD.fecha_modificacion,
            :OLD.nombre_usuario,
            :OLD.codigo_perfil,
            :OLD.codigo_empleado,
            :OLD.codigo_localidad,
            :OLD.cod_secc,
            :OLD.cod_cia,
            :OLD.cod_cia_name,
            :OLD.fecha_activacion,
            :OLD.fecha_vencimiento,
            :OLD.id_entidad
           );
  Elsif INSERTING Then
    v_ope := 'INS';
      insert 
      into SIM_EXTERNO_USUARIO_JN
           (
            JN_SECUENCIA, 
            JN_OPERATION, 
            JN_ORACLE_USER, 
            JN_DATETIME, 
            id_externo_usuario,
            tipo_doc_usuario,
            num_doc_usuario,
            tipo_usuario,
            estado_usuario,
            tipo_doc_entidad,
            num_doc_entidad,
            usuario_creacion,
            fecha_creacion,
            usuario_modificacion,
            fecha_modificacion,
            nombre_usuario,
            codigo_perfil,
            codigo_empleado,
            codigo_localidad,
            cod_secc,
            cod_cia,
            cod_cia_name,
            fecha_activacion,
            fecha_vencimiento,
            id_entidad
           )
    values
           (
            SEQ_SIM_EXTERNO_USUARIO_JN.NEXTVAL, 
            v_ope, 
            USER, 
            SYSDATE, 
            :NEW.id_externo_usuario,
            :NEW.tipo_doc_usuario,
            :NEW.num_doc_usuario,
            :NEW.tipo_usuario,
            :NEW.estado_usuario,
            :NEW.tipo_doc_entidad,
            :NEW.num_doc_entidad,
            :NEW.usuario_creacion,
            :NEW.fecha_creacion,
            :NEW.usuario_modificacion,
            :NEW.fecha_modificacion,
            :NEW.nombre_usuario,
            :NEW.codigo_perfil,
            :NEW.codigo_empleado,
            :NEW.codigo_localidad,
            :NEW.cod_secc,
            :NEW.cod_cia,
            :NEW.cod_cia_name,
            :NEW.fecha_activacion,
            :NEW.fecha_vencimiento,
            :NEW.id_entidad
           );
  End IF;
End TR_AIUD_R_SIM_EXTERNO_USUARIO;
/
