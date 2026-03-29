CREATE OR REPLACE TRIGGER TRG_AU_FACTURA_E_G9999010
  after update of estado_precobro on G9999010 --HU 1283 10/05/2024
  referencing new as new old as old
  for each row
declare
  /*--------------------------------------------------------
  Fecha de creacion: 31/07/2023
  Autor: Nelson Rodriguez
  Objetivo: Trigger para insertar los movimientos
  de las precobros en la tabla SIM_FACTURA_MVTOS
  para generar la factura electronica
  Proyecto: FACTURACION ELECTRONICA
  --------------------------------------------------------*/
  l_datos_factura   sim_typ_factura_mvtos;
  l_resultado       number(1);
  l_log_fact_e      sim_typ_log_factura_e;
  l_cod_cia         a2000030.cod_cia%type;
  l_cod_secc        a2000030.cod_secc%type;
  l_cod_ramo        a2000030.cod_ramo%type;
  l_num_pol1        a2000030.num_pol1%type;
  l_cod_mon         a2000030.cod_mon%type;
  l_tc              a2000030.tc%type;
  --l_mca_procesar    varchar2(1);
  l_datos_fe        sim_typ_polizas_borradas_fe;
  l_resultado_b     number(1);
  l_mca_provisorio  a2000030.mca_provisorio%type;
  l_num_end         a2000030.num_end%type;
  l_sub_cod_end     a2000030.sub_cod_end%type;
  l_sim_subproducto a2000030.sim_subproducto%type;
  l_num_pol_cotiz   a2000030.num_pol_cotiz%type;
  l_fecha_equipo    a2000030.fecha_equipo%type;
  l_sim_estrategia  a2000030.sim_estrategias%type;
  l_valor_prima     a2000163.imp_prima%type;
begin
  l_log_fact_e := new sim_typ_log_factura_e();
  l_valor_prima := 0;

  if updating then
    if SIM_PCK_PRECOBROS.Fun_EstadoPrecobro(:new.estado_precobro) = 'A'  --aprobado
      and SIM_PCK_PRECOBROS.Fun_EstadoPrecobro(:old.estado_precobro) <> 'A'  then  --HU 1283 10/05/2024
      --Se consultan los datos de la p??liza
      if SIM_PCK_PRECOBROS.Fun_TipoProducto(:new.cod_cia,:new.cod_secc,:new.cod_ramo)='V' then
        begin
          select p.cod_cia,
               p.cod_secc,
               p.cod_ramo,
               nvl(p.num_pol1, 0),
               p.cod_mon,
               p.tc,
               nvl(p.mca_provisorio, 'N'),
               p.num_end,
               p.sub_cod_end,
               p.sim_subproducto,
               nvl(p.num_pol_cotiz, 0),
               p.fecha_equipo,
               p.sim_estrategias
          into l_cod_cia,
               l_cod_secc,
               l_cod_ramo,
               l_num_pol1,
               l_cod_mon,
               l_tc,
               l_mca_provisorio,
               l_num_end,
               l_sub_cod_end,
               l_sim_subproducto,
               l_num_pol_cotiz,
               l_fecha_equipo,
               l_sim_estrategia
          from a2000030 p
         where p.num_secu_pol = :new.num_secu_pol
           and p.num_end =  (select max(x.num_end)
                              from a2000030 x
                             where x.num_secu_pol=p.num_secu_pol);
        exception
          when no_data_found then
            l_num_pol1 := null;
          when others then
            l_num_pol1 := null;
        end;
          --GD426-1293 20/05/2024 l_valor_prima  := nvl(:new.imp_prima_prorrata,0);
          l_valor_prima  := nvl(:new.imp_prima,0); --GD426-1293 20/05/2024 
      else
        if SIM_PCK_PRECOBROS.Fun_TipoProducto(:new.cod_cia,:new.cod_secc,:new.cod_ramo)='S' THEN
          begin
            select p.cod_cia,
                   p.cod_secc,
                   p.cod_ramo,
                   nvl(p.num_pol1, 0),
                   1, --cod_mon
                   1, --tc
                   nvl(p.mca_provisorio, 'N'),
                   p.num_end,
                   p.sub_cod_end,
                   --p.sim_subproducto,
                   p.fecha_equipo
              into l_cod_cia,
                   l_cod_secc,
                   l_cod_ramo,
                   l_num_pol1,
                   l_cod_mon,
                   l_tc,
                   l_mca_provisorio,
                   l_num_end,
                   l_sub_cod_end,
                   --l_sim_subproducto,
                   l_fecha_equipo
              from a2010030 p
             where p.num_secu_pol = :new.num_secu_pol
               and p.num_end =  (select max(x.num_end)
                                  from a2010030 x
                                 where x.num_secu_pol=p.num_secu_pol);
          exception
            when no_data_found then
              l_num_pol1 := null;
            when others then
              l_num_pol1 := null;
          end;
          l_valor_prima  := nvl(:new.imp_prima,0);
        end if;  --cod_ramo)='S'

      end if;  --cod_ramo='V'

      if (l_num_pol1 is not null) then

          l_datos_factura                      := new
                                                  sim_typ_factura_mvtos();
          l_datos_factura.cod_cia              := l_cod_cia;
          l_datos_factura.cod_secc             := l_cod_secc;
          l_datos_factura.cod_ramo             := l_cod_ramo;
          l_datos_factura.num_pol1             := l_num_pol1;
          --l_datos_factura.num_end              := null;
          l_datos_factura.num_secu_pol         := :new.num_secu_pol;
          l_datos_factura.cod_situacion        := null;
          l_datos_factura.fecha_factura        := sysdate;
          l_datos_factura.fecha_equipo         := l_fecha_equipo;
          l_datos_factura.cod_mon              := l_cod_mon;
          l_datos_factura.cod_mon_imptos       := l_cod_mon;
          l_datos_factura.imp_prima            := l_valor_prima +
                                                  nvl(:new.imp_der_emi,
                                                      0);
          --l_datos_factura.imp_imptos_mon_local := nvl(:new.imp_imptos,0);
          --intasi31 20240710 GD426-1402
          l_datos_factura.imp_imptos_mon_local := nvl(:new.imp_imptos_calculado,0);
          l_datos_factura.fec_vcto             := null;
          l_datos_factura.num_factura          := null;  --
          l_datos_factura.tc                   := l_tc;
          l_datos_factura.mca_origen           := 'FA';
          l_datos_factura.tipo_mvto            := 'I';
          l_datos_factura.estado               := 'PE';
          l_datos_factura.usuario_creacion     := USER;
          l_datos_factura.PRIMA_PROV           := nvl(:new.PRIMA_PROV,l_valor_prima);
          l_datos_factura.TASA_IMPUESTO        := :new.TASA_IMPUESTO;
          l_datos_factura.NUM_END              := nvl(l_num_end,0);
          l_datos_factura.id_precobro          := :NEW.id_transaccion; --GD426-1144 20240214


          sim_pck_factura_electronica.prc_insertar_mvtos_fac(l_datos_factura,
                                                             'TRG',
                                                             l_resultado);
      end if;  --l_num_pol1 is not null
    end if;  --estado_precobro Aprobado)
  end if; --updating

exception
  when others then
    l_log_fact_e.CODIGO            := SQLCODE;
    l_log_fact_e.DESCRIPCION       := SUBSTR('Error general en el trigger ' ||
                                             SQLERRM,
                                             0,
                                             999);
    l_log_fact_e.PROGRAMA          := 'TRG_AU_FACTURA_E_G9999010';
    l_log_fact_e.FECHA             := SYSDATE;
    l_log_fact_e.USUARIO           := USER;
    l_log_fact_e.NUM_SECU_POL      := l_datos_factura.num_secu_pol;
    l_log_fact_e.DATOS_ADICIONALES := 'Cia: ' || l_datos_factura.cod_cia ||
                                      ' - Seccion: ' ||
                                      l_datos_factura.cod_secc ||
                                      ' - Nro Pol: ' ||
                                      l_datos_factura.num_pol1 ||
                                      ' - Endoso: ' ||
                                      l_datos_factura.num_end ||
                                      ' - Fact: ' ||
                                      l_datos_factura.num_factura ||
                                      ' - Tipo Mvto: ' ||
                                      l_datos_factura.TIPO_MVTO;
    sim_pck_factura_electronica.prc_insertar_log(l_log_fact_e,
                                                 'TRG',
                                                 l_resultado);

end TRG_AU_FACTURA_E_G9999010;
/
