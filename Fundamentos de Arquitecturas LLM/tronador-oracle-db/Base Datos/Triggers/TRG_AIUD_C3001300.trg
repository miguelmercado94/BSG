CREATE OR REPLACE TRIGGER TRG_AIUD_C3001300
  after insert or update or delete on C3001300
  for each row
DECLARE
v_Accion varchar2(3);
BEGIN
  IF INSERTING THEN v_Accion:='INS'; END IF;
  IF UPDATING  THEN v_Accion:='UPD'; END IF;
  IF DELETING  THEN v_Accion:='DEL'; END IF;
  IF INSERTING OR UPDATING THEN
    insert into C3001300_JNL(
      ID_BENEF_LIQ
      ,TIPO_DOCUMENTO
      ,NUMERO_DOCUMENTO
      ,ID_ENT_COLOCADORA
      ,COD_CIA
      ,COD_SECC
      ,ID_PROCESO_PRODUCTO
      ,MONTO_MAXIMO
      ,ESTADO
      ,FEC_CREACION
      ,USR_CREACION
      ,FEC_ALTA
      ,COD_PRODUCTO
      ,COD_TEXTO
      ,SUB_COD_TEXTO
      ,COD_CONCEP_LIQ
      ,CODIGO_ROL
      ,FEC_MODIFICA
      ,USR_MODIFICA
      ,ACCION)
    values(
      :new.ID_BENEF_LIQ
      ,:new.TIPO_DOCUMENTO
      ,:new.NUMERO_DOCUMENTO
      ,:new.ID_ENT_COLOCADORA
      ,:new.COD_CIA
      ,:new.COD_SECC
      ,:new.ID_PROCESO_PRODUCTO
      ,:new.MONTO_MAXIMO
      ,:new.ESTADO
      ,:new.FEC_CREACION
      ,:new.USR_CREACION
      ,:new.FEC_ALTA
      ,:new.COD_PRODUCTO
      ,:new.COD_TEXTO
      ,:new.SUB_COD_TEXTO
      ,:new.COD_CONCEP_LIQ
      ,:new.CODIGO_ROL
      ,(sysdate)--:new.FEC_MODIFICA
      ,substr(user,5,8)--:new.USR_MODIFICA)
      ,v_Accion);
  END IF;
  IF DELETING THEN
    insert into C3001300_JNL(
      ID_BENEF_LIQ
      ,TIPO_DOCUMENTO
      ,NUMERO_DOCUMENTO
      ,ID_ENT_COLOCADORA
      ,COD_CIA
      ,COD_SECC
      ,ID_PROCESO_PRODUCTO
      ,MONTO_MAXIMO
      ,ESTADO
      ,FEC_CREACION
      ,USR_CREACION
      ,FEC_ALTA
      ,COD_PRODUCTO
      ,COD_TEXTO
      ,SUB_COD_TEXTO
      ,COD_CONCEP_LIQ
      ,CODIGO_ROL
      ,FEC_MODIFICA
      ,USR_MODIFICA
      ,ACCION)
    values(
      :old.ID_BENEF_LIQ
      ,:old.TIPO_DOCUMENTO
      ,:old.NUMERO_DOCUMENTO
      ,:old.ID_ENT_COLOCADORA
      ,:old.COD_CIA
      ,:old.COD_SECC
      ,:old.ID_PROCESO_PRODUCTO
      ,:old.MONTO_MAXIMO
      ,:old.ESTADO
      ,:old.FEC_CREACION
      ,:old.USR_CREACION
      ,:old.FEC_ALTA
      ,:old.COD_PRODUCTO
      ,:old.COD_TEXTO
      ,:old.SUB_COD_TEXTO
      ,:old.COD_CONCEP_LIQ
      ,:old.CODIGO_ROL
      ,(sysdate)--:new.FEC_MODIFICA
      ,substr(user,5,8)--:new.USR_MODIFICA
      ,v_Accion);
  END IF;
  EXCEPTION
  WHEN OTHERS THEN
  raise_application_error(-20101,'Error TRG_C3001300_JNL ' ||SQLERRM);

END TRG_AIUD_C3001300;
/
