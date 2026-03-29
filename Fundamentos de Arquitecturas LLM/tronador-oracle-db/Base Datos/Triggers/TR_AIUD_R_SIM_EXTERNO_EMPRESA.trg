CREATE OR REPLACE TRIGGER TR_AIUD_R_SIM_EXTERNO_EMPRESA 
  after insert OR update OR delete on SIM_EXTERNO_EMPRESA
  for each row
/*
 Modifica: Ricardo Cabrera - Asesoftware
 Fecha   : Diciembre 14 de 2016 
 Desc    : Se crea el trigger para auditar el borrado, inserción y actualización
           de los registros en la tabla SIM_EXTERNO_EMPRSESA.
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
      into SIM_EXTERNO_EMPRESA_JN
           (
            JN_SECUENCIA, 
            JN_OPERATION, 
            JN_ORACLE_USER, 
            JN_DATETIME, 
            id_entidad,
            tipo_doc_entidad,
            num_doc_entidad,
            nombre_entidad,
            cod_secc,
            tipo_entidad,
            estado_entidad,
            usuario_creacion,
            fecha_creacion,
            usuario_modificacion,
            fecha_modificacion,
            cantidad_maximo_delegados,
            cantidad_maximo_delegadores
           )
    values
           (
            SEQ_SIM_EXTERNO_EMPRESA_JN.NEXTVAL, 
            v_ope, 
            USER, 
            SYSDATE, 
            :OLD.id_entidad,
            :OLD.tipo_doc_entidad,
            :OLD.num_doc_entidad,
            :OLD.nombre_entidad,
            :OLD.cod_secc,
            :OLD.tipo_entidad,
            :OLD.estado_entidad,
            :OLD.usuario_creacion,
            :OLD.fecha_creacion,
            :OLD.usuario_modificacion,
            :OLD.fecha_modificacion,
            :OLD.cantidad_maximo_delegados,
            :OLD.cantidad_maximo_delegadores
           );
  Elsif INSERTING Then
    v_ope := 'INS';
      insert 
      into SIM_EXTERNO_EMPRESA_JN
           (
            JN_SECUENCIA, 
            JN_OPERATION, 
            JN_ORACLE_USER, 
            JN_DATETIME, 
            id_entidad,
            tipo_doc_entidad,
            num_doc_entidad,
            nombre_entidad,
            cod_secc,
            tipo_entidad,
            estado_entidad,
            usuario_creacion,
            fecha_creacion,
            usuario_modificacion,
            fecha_modificacion,
            cantidad_maximo_delegados,
            cantidad_maximo_delegadores
           )
    values
           (
            SEQ_SIM_EXTERNO_EMPRESA_JN.NEXTVAL, 
            v_ope, 
            USER, 
            SYSDATE, 
            :NEW.id_entidad,
            :NEW.tipo_doc_entidad,
            :NEW.num_doc_entidad,
            :NEW.nombre_entidad,
            :NEW.cod_secc,
            :NEW.tipo_entidad,
            :NEW.estado_entidad,
            :NEW.usuario_creacion,
            :NEW.fecha_creacion,
            :NEW.usuario_modificacion,
            :NEW.fecha_modificacion,
            :NEW.cantidad_maximo_delegados,
            :NEW.cantidad_maximo_delegadores
           );
  End IF;
End TR_AIUD_R_SIM_EXTERNO_EMPRESA;
/
