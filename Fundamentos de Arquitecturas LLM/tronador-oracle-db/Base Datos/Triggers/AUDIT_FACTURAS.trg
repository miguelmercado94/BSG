CREATE OR REPLACE TRIGGER audit_facturas
  BEFORE DELETE ON A2000163 
  FOR EACH ROW
BEGIN
  DECLARE
    codprod     number(5);
    agencia     number(5);
    poliza      number(13);
    forcobro    varchar2(2);
    l_datos_fe  sim_typ_polizas_borradas_fe;
    l_resultado number(1);
    --***************************************************************************
    --Fecha: 11-08-2020
    --Autor: Sheila Uhia
    --Modificado: Se le agrega al trigger una funcionalidad
    --            para guardar los datos de los premios cuando se borre
    --Proyecto: Facturación Electrónica
    --***************************************************************************  
  BEGIN
    select cod_prod, num_pol1, cod_cobro
      into codprod, poliza, forcobro
      from a2990700
     where num_secu_pol = :old.num_secu_pol
       and num_factura = :old.num_factura
     group by cod_prod, num_pol1, cod_cobro;
    /* goter
    select cod_agencia into agencia from (a1001301)
    where cod_prod = codprod and
          fecha_equipo = (select max(fecha_equipo) from (a1001301)
                          where cod_prod = codprod);*/
    Begin
      agencia := PCK999_TERCEROS.FUN_DATOS_AGENTE1(codprod, 1);
    exception
      when others then
        null;
    end;
    insert into audit_facturas
    values
      (agencia,
       codprod,
       :old.num_Secu_pol,
       poliza,
       :old.num_factura,
       :old.num_end_ref,
       :old.cod_agrup_cont,
       :old.imp_prima,
       user,
       sysdate,
       :old.fecha_equipo,
       :old.fecha_emi,
       forcobro,
       :old.cod_ciacoa,
       :old.tipo_reg);
  
    if :old.tipo_reg = 'T' and :old.cod_agrup_cont = 'GENERICOS' then
    
      l_datos_fe := new sim_typ_polizas_borradas_fe();
    
      l_datos_fe.num_secu_pol     := :old.num_secu_pol;
      l_datos_fe.num_end          := :old.num_end;
      l_datos_fe.num_factura      := :old.num_factura;
      l_datos_fe.num_end_ref      := :old.num_end_ref;
      l_datos_fe.imp_prima        := :old.imp_prima;
      l_datos_fe.fecha_vig_fact   := :old.fecha_vig_fact;
      l_datos_fe.fecha_vto_fact   := :old.fecha_vto_fact;
      l_datos_fe.cod_agrup_cont   := :old.cod_agrup_cont;
      l_datos_fe.tipo_reg         := :old.tipo_reg;
      l_datos_fe.usuario_creacion := 'PROC_AUTOMATICO';
    
      sim_pck_factura_electronica.prc_insertar_premios_borrados(l_datos_fe,
                                                                'TRG',
                                                                l_resultado);
    
    end if;
  
  exception
    when no_data_found then
      null;
  end;

EXCEPTION
  WHEN no_data_found THEN
    NULL;
END;
/
