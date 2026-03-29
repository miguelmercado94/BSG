CREATE OR REPLACE TRIGGER AU_A5021101
-- Este trigger evalua si el concepto
-- actualizado en la tabla A5021101 existe en IAS121,
-- y si es asi la actualiza tambien en ias121

AFTER UPDATE
ON A5021101
REFERENCING OLD AS OLD NEW AS NEW
FOR EACH ROW
DECLARE

   merror                     varchar2(500) := null;
   existe                     varchar2(1)   := 'N';
   cpto                       varchar2(3)   := null;
   usuario                    varchar2(10)  := null;
   descrip                    varchar2(30)  := null;
   prog                       varchar2(30)  :='Trig AU_A5021101';

   CURSOR existet (agr  VARCHAR2 ) IS
     SELECT *
       FROM IAS121
      WHERE ias121_cconcep   = agr
        AND rownum = 1;

BEGIN

   cpto           := :NEW.COD_CPTO_COB_PAG;
   descrip        := :NEW.DESCRIPCION;

   -- Evalua si existe ya el registro en ias121
   For e in existet (cpto) loop
       existe:= 'S';
   end loop;

   If updating then
      If existe = 'S' then
         If substr (user,4,1) = '$' then
            usuario := substr (user,5);
         else
            usuario := user;
         end if;
         Update ias121 set
           IAS121_XCONCEP = descrip,
           IAS121_FMODI  = sysdate,
           IAS121_USUMODI = usuario
         where IAS121_CCONCEP =cpto;
      end if;
   end if;



EXCEPTION
WHEN OTHERS THEN
   merror := prog||sqlerrm;
   raise_application_error(-20008, merror);
END;
/
