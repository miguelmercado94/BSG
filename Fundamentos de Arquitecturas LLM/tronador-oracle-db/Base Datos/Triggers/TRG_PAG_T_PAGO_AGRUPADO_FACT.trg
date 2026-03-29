CREATE OR REPLACE TRIGGER TRG_PAG_T_PAGO_AGRUPADO_FACT 
BEFORE INSERT OR DELETE OR UPDATE ON T_PAGO_AGRUPADO_FACT 
REFERENCING OLD AS OLD NEW AS NEW 
FOR EACH ROW
DECLARE  


BEGIN

 IF UPDATING OR DELETING THEN
  
 INSERT INTO T_PAGO_AGRUPADO_FACT_HIST
 (
COD_CIA,                                                                                                                                                                                                                      
NUM_FACTURA,                                                                                                                                                                                                               
VALOR_FACTURA,                                                                                                                                                                                                        
NUM_END,                                                                                                                                                                                                                   
MCA_ESTADO,                                                                                                                                                                                                             
FECHA_ESTADO,                                                                                                                                                                                                                     
FECHA_CREACION,                                                                                                                                                                                                                  
USUARIO_CREADOR,                                                                                                                                                                                                      
FECHA_ATUALIZACION,                                                                                                                                                                                                               
USUARIO_ACTU,                                                                                                                                                                                                          
REFERENCIA,                                                                                                                                                                                                               
FECHA_CREACION_HIST   )  
VALUES
(
:OLD.COD_CIA,                                                                                                                                                                                                                      
:OLD.NUM_FACTURA,                                                                                                                                                                                                               
:OLD.VALOR_FACTURA,                                                                                                                                                                                                        
:OLD.NUM_END,                                                                                                                                                                                                                   
:OLD.MCA_ESTADO,                                                                                                                                                                                                             
:OLD.FECHA_ESTADO,                                                                                                                                                                                                                     
:OLD.FECHA_CREACION,                                                                                                                                                                                                                  
:OLD.USUARIO_CREADOR,                                                                                                                                                                                                      
:OLD.FECHA_ATUALIZACION,                                                                                                                                                                                                               
:OLD.USUARIO_ACTU,                                                                                                                                                                                                          
:OLD.REFERENCIA,                                                                                                                                                                                                                    
SYSDATE
);
 
 ELSIF INSERTING THEN
 
 BEGIN
 INSERT INTO T_PAGO_AGRUPADO_FACT_HIST
 (
COD_CIA,                                                                                                                                                                                                                      
NUM_FACTURA,                                                                                                                                                                                                               
VALOR_FACTURA,                                                                                                                                                                                                        
NUM_END,                                                                                                                                                                                                                   
MCA_ESTADO,                                                                                                                                                                                                             
FECHA_ESTADO,                                                                                                                                                                                                                     
FECHA_CREACION,                                                                                                                                                                                                                  
USUARIO_CREADOR,                                                                                                                                                                                                      
FECHA_ATUALIZACION,                                                                                                                                                                                                               
USUARIO_ACTU,                                                                                                                                                                                                          
REFERENCIA,                                                                                                                                                                                                               
FECHA_CREACION_HIST )  
VALUES
(
:NEW.COD_CIA,                                                                                                                                                                                                                      
:NEW.NUM_FACTURA,                                                                                                                                                                                                               
:NEW.VALOR_FACTURA,                                                                                                                                                                                                        
:NEW.NUM_END,                                                                                                                                                                                                                   
:NEW.MCA_ESTADO,                                                                                                                                                                                                             
:NEW.FECHA_ESTADO,                                                                                                                                                                                                                     
:NEW.FECHA_CREACION,                                                                                                                                                                                                                  
:NEW.USUARIO_CREADOR,                                                                                                                                                                                                      
:NEW.FECHA_ATUALIZACION,                                                                                                                                                                                                               
:NEW.USUARIO_ACTU,                                                                                                                                                                                                          
:NEW.REFERENCIA,                                                                                                                                                                                                                      
SYSDATE
);

 END;
 
 
 END IF;

END;
/
