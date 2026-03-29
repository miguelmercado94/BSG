CREATE OR REPLACE TRIGGER TRG_PAG_T_PAGO_AGRUPADO_REF 
BEFORE INSERT OR DELETE OR UPDATE ON T_PAGO_AGRUPADO_REF 
REFERENCING OLD AS OLD NEW AS NEW 
FOR EACH ROW
DECLARE  


BEGIN

 IF UPDATING OR DELETING THEN

 
 INSERT INTO T_PAGO_AGRUPADO_REF_HIST
 (
COD_CIA,                                                                                                                                                                                                           
REFERENCIA,                                                                                                                                                                                                      
NUM_POL1,                                                                                                                                                                                                                  
NUM_FACTURA,                                                                                                                                                                                                                 
VALOR_FACTURA,                                                                                                                                                                                                               
FECHA_CREACION,                                                                                                                                                                                                          
COD_AGENTE,                                                                                                                                                                                                           
MCA_ESTADO,                                                                                                                                                                                                                
FECHA_ESTADO,
FECHA_CREACION_HIST,
VALOR_CHEQUE,
VALOR_CASH,
PAGO_MODO,
NUMERO_CHEQUE)  
VALUES
(
:OLD.COD_CIA,                                                                                                                                                                                                           
:OLD.REFERENCIA,                                                                                                                                                                                                      
:OLD.NUM_POL1,                                                                                                                                                                                                                  
:OLD.NUM_FACTURA,                                                                                                                                                                                                                 
:OLD.VALOR_FACTURA,                                                                                                                                                                                                               
:OLD.FECHA_CREACION,                                                                                                                                                                                                          
:OLD.COD_AGENTE,                                                                                                                                                                                                           
:OLD.MCA_ESTADO,                                                                                                                                                                                                                
:OLD.FECHA_ESTADO, 
SYSDATE,
:OLD.VALOR_CHEQUE,
:OLD.VALOR_CASH,
:OLD.PAGO_MODO,
:OLD.NUMERO_CHEQUE
);

 ELSIF INSERTING THEN

 
 BEGIN
 INSERT INTO T_PAGO_AGRUPADO_REF_HIST
 (
COD_CIA,                                                                                                                                                                                                           
REFERENCIA,                                                                                                                                                                                                      
NUM_POL1,                                                                                                                                                                                                                  
NUM_FACTURA,                                                                                                                                                                                                                 
VALOR_FACTURA,                                                                                                                                                                                                               
FECHA_CREACION,                                                                                                                                                                                                          
COD_AGENTE,                                                                                                                                                                                                           
MCA_ESTADO,                                                                                                                                                                                                                
FECHA_ESTADO,                                                                                                                                                                                                                     
FECHA_CREACION_HIST,
VALOR_CHEQUE,
VALOR_CASH,
PAGO_MODO,
NUMERO_CHEQUE)  
VALUES
(
:NEW.COD_CIA,                                                                                                                                                                                                           
:NEW.REFERENCIA,                                                                                                                                                                                                      
:NEW.NUM_POL1,                                                                                                                                                                                                                  
:NEW.NUM_FACTURA,                                                                                                                                                                                                                 
:NEW.VALOR_FACTURA,                                                                                                                                                                                                               
:NEW.FECHA_CREACION,                                                                                                                                                                                                          
:NEW.COD_AGENTE,                                                                                                                                                                                                           
:NEW.MCA_ESTADO,                                                                                                                                                                                                                
:NEW.FECHA_ESTADO,                                                                                                                                                                                                                    
SYSDATE,
:NEW.VALOR_CHEQUE,
:NEW.VALOR_CASH,
:NEW.PAGO_MODO,
:NEW.NUMERO_CHEQUE
);

 END;
 
 
 END IF;

END;
/
