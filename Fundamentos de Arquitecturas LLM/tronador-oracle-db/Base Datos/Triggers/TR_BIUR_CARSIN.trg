CREATE OR REPLACE TRIGGER TR_BIUR_CARSIN
   /*
      <Creacion>
      <Autor>Carlos Eduardo Mayorga</Autor>
      <Fecha>14/09/2016</Fecha>
      <Objetivo>Llenar los campos de auditoría, y almacenar la tabla de auditoría</Objetivo>
     </Creacion>
    */
   BEFORE INSERT OR UPDATE
   ON SIM_CARGA_SINIESTROS
   FOR EACH ROW
BEGIN
   IF INSERTING
   THEN
      :new.USUARIO_CREACION := USER;
      :new.FECHA_CREACION := SYSDATE;
   ELSIF UPDATING
   THEN
      :new.USUARIO_MODIFICACION := USER;
      :new.FECHA_MODIFICACION := SYSDATE;
   END IF;
END TR_BIUR_CARSIN;
/
