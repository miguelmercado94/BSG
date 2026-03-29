CREATE OR REPLACE TRIGGER AIU_A5010011
-- Este trigger valida al insertar o actualizar la tabla
-- de delegacion de autorizantes no se realice autolegacion


BEFORE INSERT OR UPDATE
ON A5010011
REFERENCING OLD AS OLD NEW AS NEW
FOR EACH ROW
DECLARE

   merror                     varchar2(500) := null;
   delegado                   varchar2(8)   := null;
   autorizante                varchar2(8)   := null;
BEGIN
   autorizante        := :NEW.autorizante;
   delegado           := :NEW.delegado;

   If autorizante = delegado then
      merror := 'El delegado no puede ser el mismo autorizante ' ||:NEW.autorizante;
      RAISE_APPLICATION_ERROR( -20008, merror );
   end if;
END;
/
