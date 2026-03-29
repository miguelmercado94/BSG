CREATE OR REPLACE TRIGGER AU_A5021700
/*
Este trigger inserta en de las tablas  :
IAS120, IAS121, IAS700, IAS708, IAS719, IAS712, IAS170, IAS713, IAS721,IAS716 y S06_ACNT  
por cada cia en la que el ejercicio se actualice en la tabla de tesoreria a5021700.
El cambio se vera el primer dia habil de enero 2008 donde
debera insertar informacion para el 2008.
*/
AFTER UPDATE
ON A5021700
REFERENCING OLD AS OLD NEW AS NEW
FOR EACH ROW
DECLARE
   merror                     varchar2(500) := null;   
   ejercicio_ant              number(4)     := null;
   ejercicio_nue              number(4)     := null;   
   ejercicio_ini_cambio       number(4)     := null; 
   usuario                    varchar2(10)  := null;   
   prog                       varchar2(30)  :='Trig AU_A5021700 ';
   Cursor datos_ias120 is
   Select *
     from ias120
    where ias120_cejerci = ejercicio_ant;
BEGIN
   ejercicio_ant:= to_number(to_char(:OLD.fec_asiento,'YYYY'));
   ejercicio_nue:= to_number(to_char(:NEW.fec_asiento,'YYYY'));     
   If (ejercicio_ant < ejercicio_nue)  then
      If substr (user,4,1) = '$' then
         usuario := substr (user,5);
      else
         usuario := user;
      end if;       
      insert into ias120 
      Select                        
      ias120_cempres,ejercicio_nue,ias120_cagrup,ias120_xagrup,sysdate,
      sysdate,usuario, usuario
      from ias120
      where ias120_cejerci = ejercicio_ant       
       and  ias120_cempres = :new.cod_cia; 
      Insert into ias121                             
      Select
      ias121_cempres,ejercicio_nue,ias121_cagrup,ias121_cconcep,ias121_xconcep,
      ias121_ldh,sysdate, usuario, sysdate, usuario
      from ias121
      where ias121_cejerci = ejercicio_ant
        and ias121_cempres = :new.cod_cia;
      Insert into ias700        
      Select      
      IAS700_CEMPRES,EJERCICIO_NUE,IAS700_LPAR1,IAS700_LPAR2,IAS700_LPAR3,
      IAS700_LPAR4,IAS700_LPAR5,IAS700_LPAR6,IAS700_LPAR7,IAS700_LPAR8,
      IAS700_LPAR9,IAS700_LPAR10,IAS700_LPAR11,IAS700_LPAR12,IAS700_LPAR13,
      IAS700_LPAR14,IAS700_LPAR15,IAS700_LPAR16,IAS700_LPAR17,IAS700_LPAR18,
      IAS700_LPAR19,IAS700_LPAR20,IAS700_LPAR21,IAS700_LPAR22,SYSDATE,
      USUARIO,SYSDATE,USUARIO,IAS700_LPAR23
      from ias700
      where ias700_cejerci= ejercicio_ant
        and ias700_cempres = :new.cod_cia;   
      Insert into ias708
      Select
      IAS708_CEMPRES,EJERCICIO_NUE,IAS708_CCUENTA,IAS708_CCUENTB,
      Sysdate,Sysdate,USUARIO,USUARIO
      from ias708
      where ias708_cejerci = ejercicio_ant
        and ias708_cempres = :new.cod_cia;   
      Insert into ias719
      Select
      IAS719_CEMPRES,EJERCICIO_NUE,IAS719_LRENUME,IAS719_LRENUM2,         
      Sysdate,USUARIO,Sysdate,USUARIO
      from ias719
      where ias719_cejerci = ejercicio_ant
        and ias719_cempres = :new.cod_cia;   
      Insert into ias712
      Select
      IAS712_CEMPRES,EJERCICIO_NUE,IAS712_CCUENTA,Sysdate,Sysdate,         
      USUARIO,USUARIO
      from ias712
      where ias712_cejerci = ejercicio_ant
        and ias712_cempres = :new.cod_cia;   
      Insert into ias170
      Select 
      IAS170_CEMPRES,ejercicio_nue,IAS170_MESES,to_date ('01/01/'||ejercicio_nue,'dd/mm/yyyy'),         
      to_date ('31/12/'||ejercicio_nue,'dd/mm/yyyy'),IAS170_LPRORRA,IAS170_NGRAVAD,IAS170_NTOTALE,         
      IAS170_LREGULA,IAS170_CASIREG,IAS170_CASICIE,IAS170_LCIERRE,         
      Sysdate,Sysdate,USUARIO,USUARIO
      from ias170
      where ias170_cejerci = ejercicio_ant
        and ias170_cempres = :new.cod_cia;   
      Insert into ias713
      Select 
      IAS713_CEMPRES,EJERCICIO_NUE,IAS713_CCODIHO,IAS713_CCODISO,Sysdate,Sysdate,Usuario,Usuario
      from ias713
      where ias713_cejerci = ejercicio_ant
        and ias713_cempres = :new.cod_cia;   
      Insert into ias721
      Select
      IAS721_CEMPRES,EJERCICIO_NUE,IAS721_NAPUNTE,IAS721_NASIENTO,Sysdate,Usuario,Sysdate,Usuario
      from ias721
      where ias721_cejerci = ejercicio_ant
        and ias721_cempres = :new.cod_cia;    
      --Pobla la tabla de cuentas davivienda
      Insert into s06_acnt
          Select 
          IAS110_CEMPRES,ejercicio_nue,IAS110_CCUENTA,IAS110_XCUENTA,         
          IAS110_CCLASIF,IAS110_CDIGITO,IAS110_CDIGDES,IAS110_CCONVER,         
          IAS110_NNIVEL,IAS110_LCTACOL,IAS110_CCLAIVA,IAS110_CDIVISA,         
          IAS110_LAJUINF,IAS110_NAPERTU,IAS110_LDEBHAB,IAS110_CCTAAGR,         
          Sysdate,Sysdate,USUARIO,USUARIO,IAS110_CNIVELC,IAS110_CNIVELA         
          from s06_acnt
          where ias110_cejerci=ejercicio_ant
          and   ias110_cempres= :new.cod_cia; --Condicion incluida 2 Enero 2008 para no repetir las cuentas davivienda x cada cia abierta 
      /* 09 Agosto 2007 La actualizacion de ias110_backup no se puede hacer
         desde este  trigger porque la tabla esta mutando por lo que se dejo en la forma
         AP502001            
         -- Como en la tabla ias110_backup ya hay informacion del 2007,
         -- solo cuando se pase al 2009 es que se saca 
         -- backup de la informacion del a?o anterior . 
         -- Debe haber un proceso que actualice ias110_backup porque
         -- en el momento que se lance ias pueden haber cambios que no 
         -- queden en ias110_backup  
      */         
      -- Pobla la tabla ias716      
      Insert into ias716
      Select 
      ias716_cempres,ejercicio_nue,IAS716_CSUCURS,IAS716_CASIENT,IAS716_CPERIOD,Sysdate,Sysdate,usuario,usuario,IAS716_XDESCRI         
      from  ias716
      where ias716_cejerci = ejercicio_ant
      and   ias716_cempres = :new.cod_cia;      
   end if;                        
EXCEPTION
WHEN OTHERS THEN
   merror := prog||sqlerrm;
   dbms_output.put_line(merror);
   raise_application_error(-20008, merror);    
END;
/
