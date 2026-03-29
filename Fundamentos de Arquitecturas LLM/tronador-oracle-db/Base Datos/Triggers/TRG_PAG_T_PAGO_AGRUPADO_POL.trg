CREATE OR REPLACE TRIGGER TRG_PAG_T_PAGO_AGRUPADO_POL 
BEFORE INSERT OR DELETE OR UPDATE ON T_PAGO_AGRUPADO_POL 
REFERENCING OLD AS OLD NEW AS NEW 
FOR EACH ROW
DECLARE  

-- PRAGMA AUTONOMOUS_TRANSACTION;
BEGIN

 IF UPDATING OR DELETING THEN
  --DBMS_OUTPUT.PUT_LINE( '==========INSERT Query Executed IF UPDATING OR DELETING=================' ); 
 
 INSERT INTO T_PAGO_AGRUPADO_POL_HIST
 (
REFERENCIA,                                                                                                                                                                                                                 
COD_CIA,                                                                                                                                                                                                                     
NUM_POL1,                                                                                                                                                                                                                    
NUM_SECU_POL,                                                                                                                                                                                                              
COD_SECC,                                                                                                                                                                                                                    
COD_RAMO,                                                                                                                                                                                                                  
COD_PROD,                                                                                                                                                                                                                 
MCA_ESTADO,                                                                                                                                                                                                   
FECHA_ESTADO,                                                                                                                                                                                                                    
FECHA_CREACION,                                                                                                                                                                                                                   
USUARIO_CREADOR,                                                                                                                                                                                                      
FECHA_ATUALIZACION,                                                                                                                                                                                                               
USUARIO_ACTU,                                                                                                                                                                                                         
VALOR_POLIZA,                                                                                                                                                                                                     
FECHA_CREACION_HIST,
NRO_DOCUMTO,
NOM_TOMADOR,
VALOR_CHEQUE,
VALOR_CASH,
PAGO_MODO,
NUMERO_CHEQUE
)  
VALUES
(
:OLD.REFERENCIA,                                                                                                                                                                                                                 
:OLD.COD_CIA,                                                                                                                                                                                                                      
:OLD.NUM_POL1,                                                                                                                                                                                                                    
:OLD.NUM_SECU_POL,                                                                                                                                                                                                               
:OLD.COD_SECC,                                                                                                                                                                                                                    
:OLD.COD_RAMO,                                                                                                                                                                                                                   
:OLD.COD_PROD,                                                                                                                                                                                                                 
:OLD.MCA_ESTADO,                                                                                                                                                                                                   
:OLD.FECHA_ESTADO,                                                                                                                                                                                                                    
:OLD.FECHA_CREACION,                                                                                                                                                                                                                   
:OLD.USUARIO_CREADOR,                                                                                                                                                                                                      
:OLD.FECHA_ATUALIZACION,                                                                                                                                                                                                               
:OLD.USUARIO_ACTU,                                                                                                                                                                                                         
:OLD.VALOR_POLIZA,                                                                                                                                                                                                                                                                                                                                                                                                                        
SYSDATE,
:OLD.NRO_DOCUMTO,
:OLD.NOM_TOMADOR,
:OLD.VALOR_CHEQUE,
:OLD.VALOR_CASH,
:OLD.PAGO_MODO,
:OLD.NUMERO_CHEQUE
);
 
 ELSIF INSERTING THEN
  -- DBMS_OUTPUT.PUT_LINE( '==========INSERT Query Executed IF  INSERTING=================' ); 
 
 BEGIN
 INSERT INTO T_PAGO_AGRUPADO_POL_HIST
 (
REFERENCIA,                                                                                                                                                                                                                 
COD_CIA,                                                                                                                                                                                                                     
NUM_POL1,                                                                                                                                                                                                                    
NUM_SECU_POL,                                                                                                                                                                                                              
COD_SECC,                                                                                                                                                                                                                    
COD_RAMO,                                                                                                                                                                                                                  
COD_PROD,                                                                                                                                                                                                                 
MCA_ESTADO,                                                                                                                                                                                                   
FECHA_ESTADO,                                                                                                                                                                                                                    
FECHA_CREACION,                                                                                                                                                                                                                   
USUARIO_CREADOR,                                                                                                                                                                                                      
FECHA_ATUALIZACION,                                                                                                                                                                                                               
USUARIO_ACTU,                                                                                                                                                                                                         
VALOR_POLIZA,                                                                                                                                                                                                     
FECHA_CREACION_HIST,
NRO_DOCUMTO,
NOM_TOMADOR,
VALOR_CHEQUE,
VALOR_CASH,
PAGO_MODO,
NUMERO_CHEQUE
)  
VALUES
(
:NEW.REFERENCIA,                                                                                                                                                                                                                 
:NEW.COD_CIA,                                                                                                                                                                                                                      
:NEW.NUM_POL1,                                                                                                                                                                                                                    
:NEW.NUM_SECU_POL,                                                                                                                                                                                                               
:NEW.COD_SECC,                                                                                                                                                                                                                    
:NEW.COD_RAMO,                                                                                                                                                                                                                   
:NEW.COD_PROD,                                                                                                                                                                                                                 
:NEW.MCA_ESTADO,                                                                                                                                                                                                   
:NEW.FECHA_ESTADO,                                                                                                                                                                                                                    
:NEW.FECHA_CREACION,                                                                                                                                                                                                                   
:NEW.USUARIO_CREADOR,                                                                                                                                                                                                      
:NEW.FECHA_ATUALIZACION,                                                                                                                                                                                                               
:NEW.USUARIO_ACTU,                                                                                                                                                                                                         
:NEW.VALOR_POLIZA,                                                                                                                                                                                                                                                                                                                                                                                                                          
SYSDATE,
:NEW.NRO_DOCUMTO,
:NEW.NOM_TOMADOR,
:NEW.VALOR_CHEQUE,
:NEW.VALOR_CASH,
:NEW.PAGO_MODO,
:NEW.NUMERO_CHEQUE
);

 END;
 
 
 END IF;
--COMMIT WRITE BATCH;
END;
/
