CREATE OR REPLACE TRIGGER AID_A5021100
-- Evalua si el concepto
-- insertado en la tabla A5021100, no existe en IAS121,
-- y si es asi, lo inserta.
-- Si lo que se hace es borrar en A5021100,
-- y existe en IAS121,  entonces lo borra tambien de IAS121.

AFTER INSERT OR DELETE
ON A5021100
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
   cpto                       varchar2(3)   := null;

   CURSOR existet (cia_  NUMBER,   ejer NUMBER,  agr  VARCHAR2, cpt VARCHAR2 ) IS
     SELECT *
       FROM IAS121
      WHERE ias121_cempres  = cia_
        AND ias121_cejerci  = ejer
        AND ias121_cagrup   = agr
        AND ias121_cconcep  = cpt;


   CURSOR ano_contable (cia_ NUMBER ) IS
   Select ejercicio
     from a5021700
    where cod_cia = cia_;

    CURSOR descr (con varchar2) is
    Select descripcion
      from a5021101
     where cod_cpto_cob_pag =  con;



BEGIN

   If inserting then
      no_cia_        := :NEW.cod_cia;
      tipo_act       := :NEW.mca_cob_pag;
      cpto           := :NEW.cod_cpto_cob_pag;


      -- Busca el ano contable de esa compania
      For a in ano_contable (no_cia_) loop
          ano_ctb := a.ejercicio;
      end loop;

      -- Evalua si existe ya el registro en ias121
      For e in existet (no_cia_,ano_ctb,tipo_act,cpto) loop
          existe:= 'S';
      end loop;

      If existe = 'N' then

         If substr (user,4,1) = '$' then
            usuario := substr (user,5);
         else
            usuario := user;
         end if;

         For d in descr (cpto) loop
             descrip := d.descripcion;
         end loop;

         insert into ias121
         (IAS121_CEMPRES , IAS121_CEJERCI , IAS121_CAGRUP,
          IAS121_CCONCEP , IAS121_XCONCEP , IAS121_LDH,
          IAS121_FCREA   , IAS121_USUCREA , IAS121_FMODI,
          IAS121_USUMODI) values
         (no_cia_       , ano_ctb       , tipo_act,
           cpto         , descrip       , null ,
          sysdate       , usuario       , sysdate ,
          usuario);
      end if;

   elsif deleting then
      no_cia_   := :OLD.cod_cia;
      tipo_act  := :OLD.mca_cob_pag;
      cpto      := :OLD.cod_cpto_cob_pag;

      -- Busca el ano contable de esa compania
      For a in ano_contable (no_cia_) loop
         ano_ctb := a.ejercicio;
      end loop;

      -- Evalua si existe  en ias121
      existe := 'N';
      For e in existet (no_cia_,ano_ctb,tipo_act,cpto) loop
          existe:= 'S';
      end loop;
      If existe = 'S' then
         Delete from ias121
          where ias121_cempres = no_cia_
            and ias121_cejerci = ano_ctb
            and ias121_cagrup  = tipo_act
            and ias121_cconcep = cpto;
      end if;
   end if;

EXCEPTION
WHEN OTHERS THEN
   merror := prog||sqlerrm;
   raise_application_error(-20008, merror);
END;
/
