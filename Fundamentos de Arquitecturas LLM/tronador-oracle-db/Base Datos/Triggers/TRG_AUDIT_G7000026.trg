CREATE OR REPLACE TRIGGER TRG_AUDIT_G7000026
AFTER INSERT OR UPDATE ON G7000026
FOR EACH ROW
BEGIN
  INSERT INTO G7000026_JN (
    cod_cia, cod_campo, desc_listval, cod_lista,
    num_secu, fecha_creacion, fecha_actualizacion,
    usuario_creacion, usuario_actualizacion
  ) VALUES (
    :NEW.cod_cia, :NEW.cod_campo, :NEW.desc_listval, :NEW.cod_lista,
    :NEW.num_secu, SYSDATE, SYSDATE,
    :NEW.usuario_creacion, :NEW.usuario_actualizacion
  );
END;
/
