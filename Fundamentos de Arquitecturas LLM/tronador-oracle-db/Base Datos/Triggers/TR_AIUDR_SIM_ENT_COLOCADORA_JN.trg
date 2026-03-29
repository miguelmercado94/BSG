CREATE OR REPLACE TRIGGER TR_AIUDR_SIM_ENT_COLOCADORA_JN
  AFTER 
  INSERT OR 
  UPDATE OR 
  DELETE ON SIM_ENT_COLOCADORAS for each row
Declare 
  rec SIM_ENT_COLOCADORAS_JN%ROWTYPE; 
  blank SIM_ENT_COLOCADORAS_JN%ROWTYPE; 
  BEGIN 
    rec := blank; 
    IF INSERTING OR UPDATING THEN 
      rec.entidad_colocadora := :NEW.entidad_colocadora; 
      rec.desc_entidad_colocadora := :NEW.desc_entidad_colocadora; 
      rec.numero_documento := :NEW.numero_documento; 
      rec.tipo_documento := :NEW.tipo_documento; 
      rec.usuario_creacion := :NEW.usuario_creacion; 
      rec.fecha_creacion := :NEW.fecha_creacion; 
      rec.estado := :NEW.estado; 
      rec.fecha_alta := :NEW.fecha_alta; 
      rec.usuario_modifica := :NEW.usuario_modifica; 
      rec.fecha_modifica := :NEW.fecha_modifica; 
      rec.JN_DATETIME := SYSDATE; 
      rec.JN_ORACLE_USER := SYS_CONTEXT ('USERENV', 'SESSION_USER'); 
      rec.JN_APPLN := SYS_CONTEXT ('USERENV', 'MODULE'); 
      rec.JN_SESSION := SYS_CONTEXT ('USERENV', 'SESSIONID'); 
      IF INSERTING THEN 
        rec.JN_OPERATION := 'INS'; 
      ELSIF UPDATING THEN 
        rec.JN_OPERATION := 'UPD'; 
      END IF; 
    ELSIF DELETING THEN 
      rec.entidad_colocadora := :OLD.entidad_colocadora; 
      rec.desc_entidad_colocadora := :OLD.desc_entidad_colocadora; 
      rec.numero_documento := :OLD.numero_documento; 
      rec.tipo_documento := :OLD.tipo_documento; 
      rec.usuario_creacion := :OLD.usuario_creacion; 
      rec.fecha_creacion := :OLD.fecha_creacion; 
      rec.estado := :OLD.estado; 
      rec.fecha_alta := :OLD.fecha_alta; 
      rec.usuario_modifica := :OLD.usuario_modifica; 
      rec.fecha_modifica := :OLD.fecha_modifica; 
      rec.JN_DATETIME := SYSDATE; 
      rec.JN_ORACLE_USER := SYS_CONTEXT ('USERENV', 'SESSION_USER'); 
      rec.JN_APPLN := SYS_CONTEXT ('USERENV', 'MODULE'); 
      rec.JN_SESSION := SYS_CONTEXT ('USERENV', 'SESSIONID'); 
      rec.JN_OPERATION := 'DEL'; 
    END IF; 
    INSERT into SIM_ENT_COLOCADORAS_JN VALUES rec; 
  END;
/
