CREATE OR REPLACE TRIGGER AI_A1000702

-- Crear un trigger sobre las a1000702 que cada vez que inserten
-- un registro verifique si existe en ias716, y si no existe,
-- lo inserte con la columna ias716_casient en TES
-- para cada una de las compa?ia que exista en la a5021700

/* Estructura de ias716
IAS716_CEMPRES                  NOT NULL NUMBER(2)
IAS716_CEJERCI                  NOT NULL NUMBER(4)
IAS716_CSUCURS                  NOT NULL NUMBER(3)
IAS716_CASIENT                  NOT NULL VARCHAR2(3)
IAS716_CPERIOD                  NOT NULL VARCHAR2(1)
IAS716_FCREA                    NOT NULL DATE
IAS716_FMODI                    NOT NULL DATE
IAS716_USUCREA                  NOT NULL VARCHAR2(10)
IAS716_USUMODI                  NOT NULL VARCHAR2(10)
IAS716_XDESCRI                           VARCHAR2(20)

Estructura de a1000702
 COD_AGENCIA                     NOT NULL NUMBER(4)
 COD_OFI_COMER                   NOT NULL NUMBER(3)
 COD_DIV_DREG                    NOT NULL NUMBER(2)
 ABREV_AGENCIA                   NOT NULL VARCHAR2(3)
 NOM_AGENCIA                     NOT NULL VARCHAR2(50)
 RSOC_AGENCIA                             VARCHAR2(50)
 DOMI_AGENCIA                    NOT NULL VARCHAR2(50)
 LOC_AGENCIA                     NOT NULL VARCHAR2(50)
 CPOS_AGENCIA                    NOT NULL VARCHAR2(10)
 TEL_AGENCIA                              VARCHAR2(10)
 FAX_AGENCIA                              VARCHAR2(10)
 RESP_AGENCIA                             VARCHAR2(30)
 OBS_AGENCIA                              VARCHAR2(30)
 MARINH_AGENCIA                           VARCHAR2(1)
 FECINH_AGENCIA                           DATE
 FECREH_AGENCIA                           DATE
 COD_USR                                  VARCHAR2(8)
 ES_CONTABLE                              VARCHAR2(1)
 COD_REGION                               NUMBER(2)
 MCA_ESTADO                               VARCHAR2(1)
*/


AFTER INSERT
ON A1000702
REFERENCING OLD AS OLD NEW AS NEW
FOR EACH ROW
DECLARE

   merror                     varchar2(500) := null;
   no_cia_                    number(2)     := null;
   ano_ctb                    number(4 )    := null;
   existe                     varchar2(1)   := 'N';
   ofi_comer                  number(3)     := null;
   usuario                    varchar2(10)  := null;
   descrip                    varchar2(20)  := null;
   prog                       varchar2(30)  :='Trig AI_A1000702 ';


   CURSOR existet (sucur  NUMBER ) IS
    SELECT *
      FROM IAS716
     WHERE ias716_csucurs  = sucur
       AND ias716_cejerci in (Select distinct ejercicio from a5021700);

   CURSOR companias IS
     Select cod_cia, ejercicio
       from a5021700;

BEGIN

   If inserting then

      ofi_comer      := :NEW.cod_ofi_comer;
      descrip        := substr(:NEW.nom_agencia,1,20);

      -- Evalua si existe ya el registro en ias716
      For e in existet (ofi_comer) loop
          existe:= 'S';
      end loop;

      If existe = 'N' then
         If substr (user,4,1) = '$' then
            usuario := substr (user,5);
         else
            usuario := user;
         end if;
         For c in companias loop
            insert into ias716
            (IAS716_CEMPRES, IAS716_CEJERCI, IAS716_CSUCURS,
             IAS716_CASIENT, IAS716_CPERIOD, IAS716_FCREA ,
             IAS716_FMODI  , IAS716_USUCREA, IAS716_USUMODI,
             IAS716_XDESCRI ) values
            (c.cod_cia      , c.ejercicio   , ofi_comer,
             'TES'         , 'L'          , sysdate ,
             sysdate       , usuario       , usuario,
             'TESORERIA');
         end loop;
      end if;

   end if;

EXCEPTION
WHEN OTHERS THEN
   merror := prog||sqlerrm;
   raise_application_error(-20008, merror);
END;
/
