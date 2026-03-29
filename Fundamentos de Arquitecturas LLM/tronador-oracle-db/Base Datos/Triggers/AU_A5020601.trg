CREATE OR REPLACE TRIGGER AU_A5020601
-- Este trigger evalua si el tipo de actuacion
-- actualizada en la tabla A5020601 existe en IAS120,
-- y si es asi la actualiza tambien en ias120

AFTER UPDATE
ON A5020601
REFERENCING OLD AS OLD NEW AS NEW
FOR EACH ROW
DECLARE

   merror                     varchar2(500) := null;
   existe                     varchar2(1)   := 'N';
   tipo_act                   varchar2(2)   := null;
   usuario                    varchar2(10)  := null;
   descrip                    varchar2(30)  := null;
   prog                       varchar2(30)  :='Trig AU_A5020601 ';

   CURSOR existet (agr  VARCHAR2 ) IS
     SELECT *
       FROM IAS120
      WHERE ias120_cagrup   = agr
        AND rownum = 1;

BEGIN

   tipo_act       := :NEW.tipo_actu;
   descrip        := substr(:NEW.desc_actu,1,30);

   -- Evalua si existe ya el registro en ias120
   For e in existet (tipo_act) loop
       existe:= 'S';
   end loop;

   If updating then
      If existe = 'S' then
         If substr (user,4,1) = '$' then
            usuario := substr (user,5);
         else
            usuario := user;
         end if;
         Update ias120 set
           IAS120_XAGRUP = descrip,
           IAS120_FMODI  = sysdate,
           IAS120_USUMODI = usuario
         where IAS120_CAGRUP =tipo_act;
      end if;
   end if;

EXCEPTION
WHEN OTHERS THEN
   merror := prog||sqlerrm;
   raise_application_error(-20008, merror);
END;
/
