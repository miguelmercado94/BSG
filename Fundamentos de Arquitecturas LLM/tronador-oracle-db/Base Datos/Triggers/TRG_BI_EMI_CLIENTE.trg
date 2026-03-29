CREATE OR REPLACE TRIGGER TRG_BI_EMI_CLIENTE
BEFORE INSERT
ON EMI_CLIENTE REFERENCING NEW AS NEW OLD AS OLD
FOR EACH ROW
DECLARE
  t_sol      Pkg_Emi_Cliente.t_solicitud  ;
  t_newcli   Pkg_Emi_Cliente.t_cliente     ;
  mensaje    VARCHAR2(255);
BEGIN

 --dbms_session.modify_package_state(dbms_session.reinitialize);
 
        mensaje := 'Before Insert de Emi Cliente ' ;
        INSERT INTO EMI_MUTATING(num_rowid,table_name,mensaje, numero_solicitud , codigo_riesgo)
        VALUES(:NEW.ROWID,'EMI_CLIENTE_INSERT',mensaje, :NEW.numero_solicitud , :NEW.codigo_riesgo);


EXCEPTION WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('ERROR EN TRG_BI_EMI_CLIENTE=>'||SQLCODE);
        DBMS_OUTPUT.PUT_LINE('MENSAJE=>'||SQLERRM);
        RAISE_APPLICATION_ERROR (-20524,'TRG_BI_EMI_CLIENTE  '||SQLCODE ||' Fallo'||SQLERRM);

END;
/
