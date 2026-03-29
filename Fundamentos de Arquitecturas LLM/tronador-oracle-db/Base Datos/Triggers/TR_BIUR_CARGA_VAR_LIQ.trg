CREATE OR REPLACE TRIGGER TR_BIUR_CARGA_VAR_LIQ
      BEFORE INSERT OR UPDATE ON SIM_CARGA_VAR_LIQUIDACIONES
FOR EACH ROW
 /*
   <Creacion>
   <Autor>Carlos Eduardo Mayorga</Autor>
   <Fecha>15/09/2016</Fecha>
   <Objetivo>Llenar los campos de auditoría, y almacenar la tabla de auditoría</Objetivo>
   </Creacion>
 */
BEGIN
  IF inserting THEN
    :new.USUARIO_CREACION := USER;
    :new.FECHA_CREACION := SYSDATE;	
  ELSIF updating THEN
    :new.USUARIO_MODIFICACION := USER;
    :new.FECHA_MODIFICACION := SYSDATE;	
  END IF;
END TR_BIUR_CARGA_VAR_LIQ;
/
