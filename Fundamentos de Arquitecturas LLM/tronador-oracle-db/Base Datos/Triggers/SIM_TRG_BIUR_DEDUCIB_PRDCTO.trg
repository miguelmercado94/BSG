CREATE OR REPLACE TRIGGER SIM_TRG_BIUR_DEDUCIB_PRDCTO
   /* <Creacion>
      <Autor>Carlos Eduardo Becerra</Autor>
      <Fecha>02/02/2021</Fecha>
      <Objetivo>Llenar los campos de auditoria</Objetivo>
     </Creacion>
    */
   BEFORE INSERT OR UPDATE
   ON SIM_DEDUCIBLES_PRODUCTO
   FOR EACH ROW
BEGIN
   IF INSERTING
   THEN
      --:new.USUARIO_CREACION := USER;
      :new.FECHA_CREACION := SYSDATE;
	  :new.FECHA_ALTA := SYSDATE;
   ELSIF UPDATING
   THEN
      --:new.USUARIO_MODIFICACION := USER;
      :new.FECHA_MODIFICACION := SYSDATE;
   END IF;
END SIM_TRG_BIUR_DEDUCIB_PRDCTO;
/
