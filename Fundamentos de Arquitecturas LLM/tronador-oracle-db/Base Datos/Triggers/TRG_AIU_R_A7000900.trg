CREATE OR REPLACE TRIGGER TRG_AIU_R_A7000900
  after insert or update ON A7000900   for each row
DISABLE
WHEN (
new.cod_secc = 1
      )
declare
-------------------------------------------------------------------------------
-- Objetivo : insertar en tabla interfaz SIGLA C7000715 creacion de siniestros
-- Autor    : Intasi31
-- Fecha    : 24/12/2008
-- 20/05/2013 Modificación Carlos Mayorga, se encuentran varios usuarios
-- donde la regla establecida para buscar el número de documento no se cumple
-- de manera que se maneja la excepción others
-------------------------------------------------------------------------------
v_LocErr varchar2(300);
v_TextoError varchar(300);
v_Movimiento number := 0;
tp type_strosigla := type_strosigla(null,null,null,null,null,null,null,null,null,null,
null,null,null,null,null,null,null,null,null,null,null,null,null,null,null);
BEGIN
   v_locerr := 'TRG_AIU_R_A700900';
   v_textoerror := 'LLama procedimiento PCK701_STROAUTOS_SIGLA - siniestro :'
   ||:new.num_sini||' ord '||:new.nro_orden_sini||' NSS '||:new.num_secu_sini;
     IF INSERTING THEN
     --   IF nvl(:new.mca_transit,'N') = 'N' THEN  -- Si no queda en C.T.
          V_Movimiento := 1;    -- Inserta - Creacion siniestro
       --   else
       -- no se va el siniestro por estar en control tecnico, graba error.
       --    insert into c9999908 (cod_usr,num_reg,cadena,fecha_equipo)
       --    values('SISTEMA_SIGLA_ERRORES',:new.num_sini,'SINIESTRO ESTA EN CONTROL TECNICO..'||:new.num_sini,sysdate);
       -- END IF;
     --ELSIF UPDATING THEN -- autorizacion control tecnico
       --  IF :old.mca_transit = 'S' and nvl(:new.mca_transit,'N') ='N' THEN
         --    V_Movimiento := 2; -- Actualiza x C.T. - Creacion siniestro
         --END IF;
     END IF;  --  inserting or updating
--*************************
/*
insert into c9999908 (cod_usr,num_reg,cadena,fecha_equipo)
values('SISTEMA_SIGLA_ERRORES',:new.num_sini,'dentro del trgigger tabla mov:'||v_movimiento,sysdate);
*/
     IF V_Movimiento in (1,2) then

       tp.COD_SUCURSAL        := substr(:new.num_sini,1,4);
       tp.NUM_SINI            := :new.num_sini;
       tp.NUM_POL1            := :new.num_pol1;
       tp.NUM_SECU_POL        := :new.num_secu_pol;
       tp.NUM_END             := nvl(:new.num_end,0);
       TP.COD_RIES            := :new.cod_ries;
       tp.COD_SECC            := :new.cod_secc;
       tp.COD_RAMO            := :new.cod_ramo;
       tp.COD_CIA             := :new.cod_cia;
       tp.NUM_SECU_SINI       := :new.num_secu_sini;
       tp.NRO_ORDEN_SINI      := :new.nro_orden_sini;
       tp.COD_CAUSA_SINI      := :new.cod_causa_sini;
       tp.FECHA_SINI          := TO_CHAR(:new.fecha_sini,'DDMMYYYY');
       tp.FEC_DENU_SINI       := TO_CHAR(:new.fec_denu_sini,'DDMMYYYY');
       tp.TDOC_TERCERO_ASEG   := :new.tdoc_tercero_aseg;
       tp.COD_ASEG            := :new.cod_aseg;
       tp.APE_ASEG            := :new.ape_aseg;
       tp.NOM_ASEG            := :new.nom_aseg;
       tp.COD_USER            := :new.cod_user;
       tp.TDOC_TERCERO_TOM    := :new.tdoc_tercero_tom;
       tp.NRO_DOCUMTO         := :new.nro_documto;
       tp.APE_TOMADOR         := :new.ape_tomador;
       tp.NOM_TOMADOR         := :new.nom_tomador;
       tp.MOVIMIENTO          := v_movimiento;
       begin
         select substr(nom_user,1,instr(nom_user,' '))
         into tp.NRO_DOC_USUARIO
         from g1002700
        where cod_user_cia = :new.cod_user and cod_cia = :new.cod_cia;
        exception
           when OTHERS then tp.NRO_DOC_USUARIO:=0;
       end;
/*
insert into c9999908 (cod_usr,num_reg,cadena,fecha_equipo)
values('SISTEMA_SIGLA_ERRORES',:new.num_sini,'LLAMA A CARGADATOS mov:'||v_movimiento,sysdate);
*/
       BEGIN
        PCK701_STROAUTOS_SIGLA.prc_CARGADATOS(tp);
         EXCEPTION
         WHEN OTHERS THEN
           v_textoerror := v_locerr||' '||sqlcode||' '||v_TextoError;
           insert into c9999908 (cod_usr,num_reg,cadena,fecha_equipo)
           values('SISTEMA_SIGLA_ERRORES',:new.num_sini,v_textoerror,sysdate);
       END;
     END IF;
 end TRG_AIU_R_A7000900;
/
