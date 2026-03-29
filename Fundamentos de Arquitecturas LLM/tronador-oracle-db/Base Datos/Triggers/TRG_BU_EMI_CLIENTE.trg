CREATE OR REPLACE TRIGGER TRG_BU_EMI_CLIENTE
BEFORE UPDATE
ON EMI_CLIENTE FOR EACH ROW
DECLARE
  t_sol      Pkg_Emi_Cliente.t_solicitud  ;
  t_newcli   Pkg_Emi_Cliente.t_cliente     ;
  mensaje    VARCHAR2(255);
BEGIN
        
       -- dbms_session.modify_package_state(dbms_session.reinitialize);
        
        mensaje := 'Before Update de Emi Cliente' ;

        DBMS_OUTPUT.PUT_LINE(' TRG_BU_EMI_CLIENTE :NEW.numero_solicitud=>'||:NEW.numero_solicitud);
        DBMS_OUTPUT.PUT_LINE(' TRG_BU_EMI_CLIENTE :NEW.codigo_riesgo=>'||:NEW.codigo_riesgo);


        INSERT INTO EMI_MUTATING(num_rowid,table_name,mensaje, numero_solicitud , codigo_riesgo)
        VALUES(:NEW.ROWID,'EMI_CLIENTE_UPDATE',mensaje, :NEW.numero_solicitud , :NEW.codigo_riesgo);

        :new.DESC_ROL  := Pkg_Emi_Cliente.fun_describe_rol(:new.rol);


EXCEPTION WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('ERROR EN TRG_BU_EMI_CLIENTE=>'||SQLCODE);
        DBMS_OUTPUT.PUT_LINE('MENSAJE=>'||SQLERRM);
        RAISE_APPLICATION_ERROR (-20524,'TRG_BU_EMI_CLIENTE  '||SQLCODE ||' Fallo'||SQLERRM);

END;
/
