CREATE OR REPLACE TRIGGER sim_trg_au_fondo_mvtos_fe
  after update ON SIM_FONDO_MVTOS 
  for each row
declare
  -- local variables here
  l_datos_factura sim_typ_factura_mvtos;
  l_resultado     number(1);
  l_nro_documto   sim_fondo_cuentas.nro_documto%type;
  l_tdoc_tercero  sim_fondo_cuentas.tdoc_tercero%type;
  l_num_pol1      sim_fondo_cuentas.num_pol1%type;
  l_cod_ramo      sim_fondo_cuentas.cod_ramo%type;
  l_cod_secc      sim_fondo_cuentas.cod_secc%type;
  l_cod_cia       sim_fondo_cuentas.cod_cia%type;
  l_log_fact_e    sim_typ_log_factura_e;
  --**************************************************
  --Fecha: 14-08-2020
  --Autor: Sheila Uhia
  --Modificado: Se le agrega al trigger una funcionalidad
  --            para registrar cuando se le envíe a SIF
  --            la notificación de pago del ahorro
  --            para generar la Factura Electrónica
  --Proyecto: Facturación Electrónica
begin

  --******************************************
  --Inicio cambio para Facturación Electrónica
  if (:new.estado_transaccion = 'ENV') and
     (:new.tipo_transaccion in ('APOORD', 'RECEXT', 'APOEXT')) then
  
    l_log_fact_e := new sim_typ_log_factura_e();
    select nro_documto, tdoc_tercero, num_pol1, cod_ramo, cod_secc, cod_cia
      into l_nro_documto,
           l_tdoc_tercero,
           l_num_pol1,
           l_cod_ramo,
           l_cod_secc,
           l_cod_cia
      from sim_fondo_cuentas fc
     where fc.id_tabla = :new.id_tabla_fondo_cuenta;
  
    l_datos_factura                      := new sim_typ_factura_mvtos();
    l_datos_factura.cod_cia              := l_cod_cia;
    l_datos_factura.cod_secc             := l_cod_secc;
    l_datos_factura.cod_ramo             := l_cod_ramo;
    l_datos_factura.num_pol1             := l_num_pol1;
    l_datos_factura.num_end              := null;
    l_datos_factura.num_secu_pol         := null;
    l_datos_factura.cod_situacion        := null;
    l_datos_factura.fecha_factura        := :new.fecha_transaccion;
    l_datos_factura.fecha_equipo         := null;
    l_datos_factura.cod_mon              := :new.cod_mon;
    l_datos_factura.cod_mon_imptos       := null;
    l_datos_factura.imp_prima            := :new.valor_transaccion;
    l_datos_factura.imp_imptos_mon_local := 0;
    l_datos_factura.fec_vcto             := :new.fecha_transaccion;
    l_datos_factura.num_factura          := :new.num_factura;
    l_datos_factura.tc                   := null;
    l_datos_factura.tdoc_tercero_nvo     := l_tdoc_tercero;
    l_datos_factura.nro_documto_nvo      := l_nro_documto;
    l_datos_factura.usuario_creacion     := user;
    l_datos_factura.mca_origen           := 'FL';
    l_datos_factura.tipo_mvto            := 'I';
    l_datos_factura.estado               := 'PE';
  
    sim_pck_factura_electronica.prc_insertar_mvtos_fac(l_datos_factura,
                                                       'TRG',
                                                       l_resultado);
  
  end if;

  --Fin cambio para Facturación Electrónica
  --***************************************
exception
  when others then
    l_log_fact_e.CODIGO            := SQLCODE;
    l_log_fact_e.DESCRIPCION       := SUBSTR('ERROR TRG FONDOS LIBERTY ' ||
                                             SQLERRM,
                                             0,
                                             999);
    l_log_fact_e.PROGRAMA          := '1-SIM_TRG_AU_FONDO_MVTOS_FE';
    l_log_fact_e.FECHA             := SYSDATE;
    l_log_fact_e.USUARIO           := USER;
    l_log_fact_e.NUM_SECU_POL      := null;
    l_log_fact_e.DATOS_ADICIONALES := 'Cia: ' || l_cod_cia ||
                                      ' - CodSecc: ' || l_cod_secc ||
                                      ' - CodRamo: ' || l_cod_ramo ||
                                      ' - NumPol1: ' || l_num_pol1;
    sim_pck_factura_electronica.prc_insertar_log(l_log_fact_e,
                                                 'TRG',
                                                 l_resultado);
end sim_trg_au_fondo_mvtos_fe;
/
