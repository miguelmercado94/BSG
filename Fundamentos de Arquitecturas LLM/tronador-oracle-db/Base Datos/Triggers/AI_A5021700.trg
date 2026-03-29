CREATE OR REPLACE TRIGGER AI_A5021700
-- Autor JMF Jul-Ago 2007 Req IAS
-- Este trigger se encarga de que al
-- insertar una cia en la A5021700
-- inserte en la ias719, ias700, ias721, ias713 , ias716
-- usando los valores que tiene la cia uno
-- Inserte en ias708 e ias712 usando los datos de la 2
-- Se arme la informacion de la ias170 con base en el ejercicio que llega
--
AFTER INSERT
ON A5021700
REFERENCING OLD AS OLD NEW AS NEW
FOR EACH ROW
DECLARE

   merror                     varchar2(500) := null;
   cod_cia_                   number(2)     := null;
   ejercicio_nue              number(4)     := null;
   usuario                    varchar2(10)  := null;
   prog                       varchar2(30)  :='Trig AI_A5021700 ';

   Cursor cia_1 is
   Select IAS719_LRENUME,IAS719_LRENUM2
     from ias719
    where IAS719_CEMPRES=1
      and ias719_cejerci=ejercicio_nue;

   Cursor ias700_cia1 is
   Select *
     from ias700
    where ias700_CEMPRES=1
      and ias700_cejerci=ejercicio_nue;

BEGIN

   cod_cia_            := :new.cod_cia;
   ejercicio_nue       := to_number(to_char(:new.fec_asiento,'YYYY'));

  -- Evalua si lo que se esta haciendo es insertando

   If inserting then

      If substr (user,4,1) = '$' then
          usuario := substr (user,5);
      else
          usuario := user;
      end if;

      /* Se pobla con base en a5021700 */
      Insert into ias170(
      ias170_cempres, ias170_cejerci, ias170_meses, ias170_dapertu,
      ias170_dcierre, ias170_lprorra,ias170_ngravad,ias170_ntotale,
      ias170_lregula,ias170_casireg,ias170_casicie,ias170_lcierre,
      ias170_fcrea, ias170_fmodi, ias170_usucrea, ias170_usumodi)
      Select cod_cia_,ejercicio_nue, 12, to_date('01/01'||ejercicio_nue,'dd/mm/yyyy'),
       to_date('31/12'||ejercicio_nue,'dd/mm/yyyy'),'N',0,0,
       null, null, null, null,
       sysdate, sysdate, usuario, usuario
       from dual;

      /* Se pobla con lo informacion que tiene la cia 1 */
      For r in cia_1 loop
          insert into ias719
          (ias719_cempres   ,ias719_cejerci,ias719_lrenume,
           ias719_lrenum2   ,ias719_fcrea  ,ias719_usucrea,
           ias719_fmodi     ,ias719_usumodi) values
           (cod_cia_        ,ejercicio_nue ,r.ias719_lrenume,
            r.ias719_lrenum2,sysdate       ,usuario         ,
            sysdate         ,usuario);
      end loop;
      For r in ias700_cia1 loop
          insert into IAS700
          (IAS700_CEMPRES,IAS700_CEJERCI,IAS700_LPAR1,
           IAS700_LPAR2  ,IAS700_LPAR3  ,IAS700_LPAR4,
           IAS700_LPAR5  ,IAS700_LPAR6  ,IAS700_LPAR7,
           IAS700_LPAR8  ,IAS700_LPAR9  ,IAS700_LPAR10,
           IAS700_LPAR11 ,IAS700_LPAR12 ,IAS700_LPAR13,
           IAS700_LPAR14 ,IAS700_LPAR15 ,IAS700_LPAR16,
           IAS700_LPAR17 ,IAS700_LPAR18 ,IAS700_LPAR19,
           IAS700_LPAR20 ,IAS700_LPAR21 ,IAS700_LPAR22,
           IAS700_FCREA  ,IAS700_USUCREA,IAS700_FMODI,
           IAS700_USUMODI,IAS700_LPAR23) values
          (cod_cia_      ,ejercicio_nue     ,r.IAS700_LPAR1,
           r.IAS700_LPAR2  ,r.IAS700_LPAR3  ,r.IAS700_LPAR4,
           r.IAS700_LPAR5  ,r.IAS700_LPAR6  ,r.IAS700_LPAR7,
           r.IAS700_LPAR8  ,r.IAS700_LPAR9  ,r.IAS700_LPAR10,
           r.IAS700_LPAR11 ,r.IAS700_LPAR12 ,r.IAS700_LPAR13,
           r.IAS700_LPAR14 ,r.IAS700_LPAR15 ,r.IAS700_LPAR16,
           r.IAS700_LPAR17 ,r.IAS700_LPAR18 ,r.IAS700_LPAR19,
           r.IAS700_LPAR20 ,r.IAS700_LPAR21 ,r.IAS700_LPAR22,
           sysdate         ,usuario         ,sysdate,
           usuario         ,r.IAS700_LPAR23);
      end loop;

      Insert into ias721
       Select
       Cod_cia_,EJERCICIO_NUE,IAS721_NAPUNTE,IAS721_NASIENTO,Sysdate,Usuario,Sysdate,Usuario
       from ias721
       where ias721_cejerci = ejercicio_nue
       and  ias721_cempres = 1;

      Insert into ias713
      Select
      Cod_cia_,EJERCICIO_NUE,IAS713_CCODIHO,IAS713_CCODISO,Sysdate,Sysdate,Usuario,Usuario
      from ias713
      where ias713_cejerci = ejercicio_nue
        and ias713_cempres = 1;

      Insert into ias708
      Select
      Cod_cia_,ejercicio_nue,IAS708_CCUENTA,IAS708_CCUENTB,Sysdate,Sysdate,Usuario,Usuario
      from ias708
      where ias708_cejerci = ejercicio_nue
        and ias708_cempres = 2;

      Insert into ias712
      Select
      Cod_cia_,ejercicio_nue,IAS712_CCUENTA,Sysdate,Sysdate,Usuario,Usuario
      from ias712
      where ias712_cejerci = ejercicio_nue
        and ias712_cempres = 2;

      Insert into ias716
      Select
      Cod_cia_,ejercicio_nue,IAS716_CSUCURS,IAS716_CASIENT,IAS716_CPERIOD,Sysdate,Sysdate,usuario,usuario,IAS716_XDESCRI
      from  ias716
      where ias716_cejerci = ejercicio_nue
      and   ias716_cempres=1;

   end if;

EXCEPTION
WHEN OTHERS THEN
   merror := prog||sqlerrm;
   raise_application_error(-20008, merror);
END;
/
