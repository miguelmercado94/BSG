CREATE OR REPLACE TRIGGER AID_A5020600
-- Evalua si el tipo de actualizacion
-- insertada en la tabla A5020600 no existe en IAS120
-- y si es asi, la inserta.
-- Si lo que se hace es borrar en A5020600,
-- y existe en IAS120  entonces lo borra tambien de IAS120

AFTER INSERT OR DELETE
ON A5020600
REFERENCING OLD AS OLD NEW AS NEW
FOR EACH ROW
DECLARE

   merror                     varchar2(500) := null;
   no_cia_                    number(2)     := null;
   ano_ctb                    number(4 )    := null;
   existe                     varchar2(1)   := 'N';
   tipo_act                   varchar2(2)   := null;
   usuario                    varchar2(10)  := null;
   descrip                    varchar2(30)  := null;
   prog                       varchar2(30)  :='Trig AID_A5020600 ';


   CURSOR existet (cia_  NUMBER,   ejer NUMBER,  agr  VARCHAR2 ) IS
     SELECT *
       FROM IAS120
      WHERE ias120_cempres  = cia_
        AND ias120_cejerci  = ejer
        AND ias120_cagrup   = agr;

   CURSOR ano_contable (cia_ NUMBER ) IS
   Select ejercicio
     from a5021700
    where cod_cia = cia_;

BEGIN

   If inserting then
      no_cia_        := :NEW.cod_cia;
      tipo_act       := :NEW.tipo_actu;
      descrip        := substr(:NEW.desc_actu,1,30);

      -- Busca el ano contable de esa compania
      For a in ano_contable (no_cia_) loop
          ano_ctb := a.ejercicio;
      end loop;

      -- Evalua si existe ya el registro en ias120
      For e in existet (no_cia_,ano_ctb,tipo_act) loop
          existe:= 'S';
      end loop;

      If existe = 'N' then

         If substr (user,4,1) = '$' then
            usuario := substr (user,5);
         else
            usuario := user;
         end if;

         insert into ias120
         (IAS120_CEMPRES, IAS120_CEJERCI, IAS120_CAGRUP,
          IAS120_XAGRUP , IAS120_FCREA  , IAS120_FMODI ,
          IAS120_USUCREA, IAS120_USUMODI) values
         (no_cia_       , ano_ctb       , tipo_act,
          descrip       , sysdate       , sysdate ,
          usuario       , usuario);
      end if;

   elsif deleting then
      no_cia_   := :OLD.cod_cia;
      tipo_act  := :OLD.tipo_actu;

      -- Busca el ano contable de esa compania
      For a in ano_contable (no_cia_) loop
         ano_ctb := a.ejercicio;
      end loop;

      -- Evalua si existe  en ias120
      existe := 'N';
      For e in existet (no_cia_,ano_ctb,tipo_act) loop
          existe:= 'S';
      end loop;
      If existe = 'S' then
         Delete from ias120
         where ias120_cempres = no_cia_
         and   ias120_cejerci = ano_ctb
         and   ias120_cagrup  = tipo_act;
      end if;
   end if;

EXCEPTION
WHEN OTHERS THEN
   merror := prog||sqlerrm;
   raise_application_error(-20008, merror);
END;
/
