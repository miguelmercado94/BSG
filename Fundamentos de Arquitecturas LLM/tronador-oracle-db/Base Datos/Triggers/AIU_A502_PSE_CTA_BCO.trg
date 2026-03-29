CREATE OR REPLACE TRIGGER AIU_A502_PSE_CTA_BCO
-- Este trigger valida al insertar o actualizar la tabla
-- de parametros de las cuentas bancarias inscritas por compania
-- y producto para el sistema PSE

BEFORE INSERT OR UPDATE
ON A502_PSE_CTA_BCO
REFERENCING OLD AS OLD NEW AS NEW
FOR EACH ROW
DECLARE

   merror                     varchar2(500) := null;
   no_cia_                    number(2)     := null;
   nro_cuenta_                varchar2(15)  := null;
   existe_cuenta_             varchar2(1)   := null;

   CURSOR nro_cuenta ( cia_  VARCHAR2,    ct_  VARCHAR2 ) IS
     SELECT *
       FROM A5022600
      WHERE cod_cia      = cia_
        AND nro_cuenta   = ct_
        AND mca_caja_bco = 'B';
        --AND nro_cuenta  is not null;

BEGIN
   no_cia_        := :NEW.cod_cia;
   nro_cuenta_    := :NEW.nro_cuenta;
   existe_cuenta_ := 'N';
   For r in nro_cuenta (no_cia_,nro_cuenta_) loop
       existe_cuenta_ := 'S';
   end loop;
   If existe_cuenta_ = 'N' then
      merror := 'La cuenta bancaria ' ||:NEW.NRO_CUENTA|| ' no existe o no es bancaria en A5022600  para la cia '||:new.cod_cia;
      RAISE_APPLICATION_ERROR( -20008, merror );
   end if;
END;
/
