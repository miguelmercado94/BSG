CREATE OR REPLACE TRIGGER TR_AIUDR_sim_procesos_aut_jn
  AFTER
  INSERT OR
  UPDATE OR
  DELETE ON sim_procesos_automaticos for each row
Declare
  rec sim_procesos_automaticos_jn%ROWTYPE;
  blank sim_procesos_automaticos_jn%ROWTYPE;
  BEGIN
    rec := blank;
    rec.JN_DATETIME := SYSDATE;
    rec.JN_ORACLE_USER := SYS_CONTEXT ('USERENV', 'SESSION_USER');
    rec.JN_APPLN := SYS_CONTEXT ('USERENV', 'MODULE');
    rec.JN_SESSION := SYS_CONTEXT ('USERENV', 'SESSIONID');
    IF INSERTING OR UPDATING Then
       rec.id_secuencia := :new.id_Secuencia;
       rec.cod_cia := :new.cod_cia     ;
       rec.cod_secc := :new.cod_secc   ;
       rec.cod_ramo := :new.cod_ramo   ;
       rec.sub_ramo := :new.sub_ramo   ;
       rec.cod_prog  := :new.cod_prog  ;
       rec.programa_real := :new.programa_real;
       rec.activa_proceso:= :new.activa_proceso;
       rec.aplica_debito := :new.aplica_debito;
       rec.aplica_libranza := :new.aplica_libranza;
       rec.aplica_CC      := :new.aplica_CC;
       rec.aplica_neg_banca   := :new.aplica_neg_banca;
	     rec.aplica_neg_bolivar := :new.aplica_neg_bolivar;
       rec.Fecha_creacion := :new.fecha_creacion;
       rec.usuario_creacion := :new.usuario_creacion;
       rec.Fecha_modificacion := :new.fecha_modificacion;
       rec.usuario_modificacion := :new.usuario_modificacion;
       IF INSERTING THEN
          rec.JN_OPERATION := 'INS';
       ELSIF UPDATING THEN
          rec.JN_OPERATION := 'UPD';
       END IF;
    ELSIF DELETING Then
       rec.id_secuencia := :old.id_secuencia;
       rec.cod_cia := :old.cod_cia     ;
       rec.cod_secc := :old.cod_secc   ;
       rec.cod_ramo := :old.cod_ramo   ;
       rec.sub_ramo := :old.sub_ramo   ;
       rec.cod_prog  := :old.cod_prog  ;
       rec.programa_real := :old.programa_real;
       rec.activa_proceso:= :old.activa_proceso;
       rec.aplica_debito := :old.aplica_debito;
       rec.aplica_libranza := :old.aplica_libranza;
       rec.aplica_CC      := :old.aplica_CC;
       rec.aplica_neg_banca   := :old.aplica_neg_banca;
	     rec.aplica_neg_bolivar := :old.aplica_neg_bolivar;
       rec.Fecha_creacion := :old.fecha_creacion;
       rec.usuario_creacion := :old.usuario_creacion;
       rec.Fecha_modificacion := :old.fecha_modificacion;
       rec.usuario_modificacion := :old.usuario_modificacion;
       rec.JN_OPERATION := 'DEL';
    END IF;
    INSERT into sim_procesos_automaticos_jn VALUES rec;
  Exception When Others Then Null;
  END;
/
