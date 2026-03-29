CREATE OR REPLACE TRIGGER trg_aid_factura_e_a2000160
  after insert or delete on a2000160
  referencing new as new old as old
  for each row
declare
  /*--------------------------------------------------------
  Fecha de creación: 19/09/2020
  Autor: Sheila Uhia
  Objetivo: Trigger para insertar los movimientos
  de las facturas en la tabla SIM_FACTURA_MVTOS
  para generar la factura electrónica
  Guardar los datos de los premios borrados
  para uso de Facturación Electrónica
  Proyecto: FACTURACIÓN ELECTRÓNICA
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
  l_mca_procesar    varchar2(1);
  l_procesa_decenal varchar2(1);
  l_datos_fe        sim_typ_polizas_borradas_fe;
  l_resultado_b     number(1);
  l_mca_provisorio  a2000030.mca_provisorio%type;
  l_cod_end         a2000030.cod_end%type;
  l_sub_cod_end     a2000030.sub_cod_end%type;
  l_sim_subproducto a2000030.sim_subproducto%type;
  l_num_pol_cotiz   a2000030.num_pol_cotiz%type;
  l_fecha_equipo    a2000030.fecha_equipo%type;
  l_sim_estrategia  a2000030.sim_estrategias%type;
begin
  l_log_fact_e := new sim_typ_log_factura_e();

  if inserting then
    if :new.tipo_reg = 'T' then
      --Se consultan los datos de la póliza
      begin
        select p.cod_cia,
               p.cod_secc,
               p.cod_ramo,
               nvl(p.num_pol1, 0),
               p.cod_mon,
               p.tc,
               nvl(p.mca_provisorio, 'N'),
               p.cod_end,
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
               l_cod_end,
               l_sub_cod_end,
               l_sim_subproducto,
               l_num_pol_cotiz,
               l_fecha_equipo,
               l_sim_estrategia
          from a2000030 p
         where p.num_secu_pol = :new.num_secu_pol
           and p.num_end = :new.num_end;
      exception
        when no_data_found then
          l_num_pol1 := null;
        when others then
          l_num_pol1 := null;
      end;
    
      if (l_num_pol1 is not null) then
      
        --Se consultan las secciones que no se van a procesar con la tabla a2990700 sino con la a2000160
        begin
          select 'S'
            into l_mca_procesar
            from c9999909 d
           where d.cod_tab = 'FACTURACION_ELEC'
             and d.dat_car2 = 'PRODUCTOS_PROC_INDP'
             and d.fecha_act is not null
             and d.fecha_baja is null
             and d.cod_cia = l_cod_cia
             and d.cod_secc = l_cod_secc;
        exception
          when no_data_found then
            l_mca_procesar := 'N';
          when others then
            l_mca_procesar := 'N';
        end;
      
        --Para la sección 923 solo se enví­a la factura 4 cuando la oferta este parametrizada en distribución factura
        if (l_mca_procesar = 'N' and l_cod_secc = 923) then
          begin
            select 'S'
              into l_mca_procesar 
              from fact_especial a
             where a.cod_tab = 'FACTSECC_DISTRIB'
               and a.cod_secc = l_cod_secc -- cod_secc de la a2000030
               and a.cod_ramo = l_cod_ramo -- Cod_ramo a2000030
               and a.dat_num = l_sim_estrategia -- SIm_estrategia de la a2000030
               and dat_car = 'S';
          exception
            when no_data_found then
              l_mca_procesar := 'N';
            when others then
              l_mca_procesar := 'N';
          end;
        end if;
      
        if (l_mca_procesar = 'N') then
        
          if (l_num_pol_cotiz > 0) and (l_num_pol1 = 0) then
            begin
              --Se valida si se deben registrar las cotizaciones del producto
              select 'S'
                into l_mca_procesar
                from c9999909 d
               where d.cod_tab = 'FACTURACION_ELEC'
                 and d.dat_car2 = 'PRODUCTOS_COTIZACION'
                 and d.fecha_act is not null
                 and d.fecha_baja is null
                 and d.cod_cia = l_cod_cia
                 and d.cod_secc = l_cod_secc
                 and d.cod_ramo = l_cod_ramo
                 and nvl(d.codigo, -1) = nvl(l_sim_subproducto, -1);
            exception
              when no_data_found then
                l_mca_procesar := 'N';
              when others then
                l_mca_procesar := 'N';
              
            end;
          else
            l_mca_procesar := 'S';
          end if;
        
          if (l_mca_procesar = 'S') then
          
            --Se valida si el tipo de endoso se debe notificar al cliente        
            begin
            
              select 'S'
                into l_mca_procesar
                from c9999909 d
               where d.cod_tab = 'FACTURACION_ELEC'
                 and d.dat_car2 = 'TIPOS_ENDOSOS_NO_ENVIAR'
                 and d.fecha_act is not null
                 and d.fecha_baja is null
                 and d.rango1 = nvl(l_cod_end, -1)
                 and d.rango2 = nvl(l_sub_cod_end, -1);
            exception
              when no_data_found then
                l_mca_procesar := 'N';
              when others then
                l_mca_procesar := 'N';
            end;

            --GD517-740 Se valida si se debe facturar o no en caso de pertenecer a decenal.
            if (l_mca_procesar = 'N' and l_cod_cia = 3 and l_cod_secc = 81 and
               l_cod_ramo = 160) then
              l_procesa_decenal := ops$puma.SIM_FUN_DECENAL_ESPE(l_cod_cia,
                                                                 l_cod_secc,
                                                                 l_cod_ramo,
                                                                 :new.num_secu_pol);
              if (l_procesa_decenal = '-1' or l_procesa_decenal = 'S') then
                l_mca_procesar := 'S';
              else
                l_mca_procesar := 'N';
              end if;
            end if;

             --GD426-863 se excluye si la seccion y el ramo estan configurados para precobro
            IF (l_mca_procesar = 'N') THEN
							BEGIN
								SELECT CASE 
                  WHEN SUM(DECODE(d.cod_campo, 'PRODUCTOS_HABILITADOS', 1, 0)) > 0
                        AND NOT (:new.num_end = 0 AND SUM(DECODE(d.cod_campo, 'FACTURA_EXCLUIDA_PROCESO', 1, 0)) > 0) 
                  THEN 'S'
                  ELSE 'N'
                  END 
                INTO   l_mca_procesar
                    FROM   C9999909 d
                    WHERE  d.cod_tab = 'DOMINIOS_PRECOBROS'
                    AND d.cod_campo IN ('PRODUCTOS_HABILITADOS', 'FACTURA_EXCLUIDA_PROCESO')
                    AND d.cod_secc = l_cod_secc
                    AND d.cod_ramo = l_cod_ramo;
							EXCEPTION
								WHEN no_data_found THEN
									l_mca_procesar := 'N';
								WHEN OTHERS THEN
									l_mca_procesar := 'N';
							END;
						END IF;

            -- OFEVALN3-49 se omite el envio de cancelacion automatica de póliza exfinanciadas 
						IF (l_mca_procesar = 'N') THEN
							BEGIN
								SELECT 'S'
								INTO   l_mca_procesar
								FROM   c2000406 c
								WHERE  c.cod_secc = l_cod_secc
									   AND c.cod_cia = l_cod_cia
									   AND c.num_pol1 = l_num_pol1
									   AND c.fecha_batch = trunc(SYSDATE);
							EXCEPTION
								WHEN no_data_found THEN
									l_mca_procesar := 'N';
								WHEN OTHERS THEN
									l_mca_procesar := 'N';
							END;
						END IF;
          
            if (l_mca_procesar = 'N') then
            
              l_datos_factura                      := new
                                                      sim_typ_factura_mvtos();
              l_datos_factura.cod_cia              := l_cod_cia;
              l_datos_factura.cod_secc             := l_cod_secc;
              l_datos_factura.cod_ramo             := l_cod_ramo;
              l_datos_factura.num_pol1             := l_num_pol1;
              l_datos_factura.num_end              := :new.num_end;
              l_datos_factura.num_secu_pol         := :new.num_secu_pol;
              l_datos_factura.cod_situacion        := null;
              l_datos_factura.fecha_factura        := sysdate;
              l_datos_factura.fecha_equipo         := l_fecha_equipo;
              l_datos_factura.cod_mon              := l_cod_mon;
              l_datos_factura.cod_mon_imptos       := l_cod_mon;
              l_datos_factura.imp_prima            := nvl(:new.imp_prima_end,
                                                          0) +
                                                      nvl(:new.imp_der_emi_en,
                                                          0);
              l_datos_factura.imp_imptos_mon_local := 0;
              l_datos_factura.fec_vcto             := null;
              l_datos_factura.num_factura          := null;
              l_datos_factura.tc                   := l_tc;
              l_datos_factura.mca_origen           := 'FA';
              l_datos_factura.tipo_mvto            := 'I';
              l_datos_factura.estado               := 'PE';
              l_datos_factura.usuario_creacion     := USER;
            
              sim_pck_factura_electronica.prc_insertar_mvtos_fac(l_datos_factura,
                                                                 'TRG',
                                                                 l_resultado);
            end if;
          end if;
        end if;
      end if;
    end if;
  end if;

  if deleting then
    if :old.tipo_reg = 'T' then
      --Se validan los estados de la factura
      if :old.num_end is not null then
      
        --Se consultan los datos de la póliza
        begin
          select p.cod_cia,
                 p.cod_secc,
                 p.cod_ramo,
                 p.num_pol1,
                 p.cod_mon,
                 p.tc
            into l_cod_cia,
                 l_cod_secc,
                 l_cod_ramo,
                 l_num_pol1,
                 l_cod_mon,
                 l_tc
            from sim_factura_mvtos p
           where p.num_secu_pol = :old.num_secu_pol
             and p.num_end = :old.num_end
             and p.id_fact_mvto =
                 (select max(p2.id_fact_mvto)
                    from sim_factura_mvtos p2
                   where p2.num_secu_pol = p.num_secu_pol
                     and p2.num_end = p.num_end);
        exception
          when no_data_found then
            l_num_pol1 := null;
          when others then
            l_num_pol1 := null;
        end;
      
        if (l_num_pol1 is not null) then
        
          --Se consultan las secciones que no se van a procesar con la tabla a2990700 sino con la a2000160
          begin
          
            select 'S'
              into l_mca_procesar
              from c9999909 d
             where d.cod_tab = 'FACTURACION_ELEC'
               and d.dat_car2 = 'PRODUCTOS_PROC_INDP'
               and d.fecha_act is not null
               and d.fecha_baja is null
               and d.cod_cia = l_cod_cia
               and d.cod_secc = l_cod_secc;
          exception
            when no_data_found then
              l_mca_procesar := 'N';
            when others then
              l_mca_procesar := 'N';
          end;
        
          if (l_mca_procesar = 'N') then
          
            l_datos_factura                      := new
                                                    sim_typ_factura_mvtos();
            l_datos_factura.cod_cia              := l_cod_cia;
            l_datos_factura.cod_secc             := l_cod_secc;
            l_datos_factura.cod_ramo             := l_cod_ramo;
            l_datos_factura.num_pol1             := l_num_pol1;
            l_datos_factura.num_end              := :old.num_end;
            l_datos_factura.num_secu_pol         := :old.num_secu_pol;
            l_datos_factura.cod_situacion        := null;
            l_datos_factura.fecha_factura        := sysdate;
            l_datos_factura.fecha_equipo         := null;
            l_datos_factura.cod_mon              := l_cod_mon;
            l_datos_factura.cod_mon_imptos       := l_cod_mon;
            l_datos_factura.imp_prima            := nvl(:old.imp_prima_end,
                                                        0) +
                                                    nvl(:old.imp_der_emi_en,
                                                        0);
            l_datos_factura.imp_imptos_mon_local := 0;
            l_datos_factura.fec_vcto             := null;
            l_datos_factura.num_factura          := null;
            l_datos_factura.tc                   := l_tc;
            l_datos_factura.usuario_creacion     := USER;
            l_datos_factura.usuario_modificacion := USER;
            l_datos_factura.tipo_mvto            := 'D';
            l_datos_factura.mca_origen           := 'FA';
            l_datos_factura.estado               := 'PE';
          
            sim_pck_factura_electronica.prc_insertar_mvtos_fac(l_datos_factura,
                                                               'TRG',
                                                               l_resultado);
          
          end if;
        end if;
      
        l_datos_fe                  := new sim_typ_polizas_borradas_fe();
        l_datos_fe.num_secu_pol     := :old.num_secu_pol;
        l_datos_fe.num_end          := :old.num_end;
        l_datos_fe.imp_prima        := :old.imp_prima;
        l_datos_fe.imp_prima_end    := :old.imp_prima_end;
        l_datos_fe.end_prima_anu    := :old.end_prima_anu;
        l_datos_fe.tipo_reg         := :old.tipo_reg;
        l_datos_fe.usuario_creacion := USER;
      
        sim_pck_factura_electronica.prc_insertar_premiost_borrados(l_datos_fe,
                                                                   'TRG',
                                                                   l_resultado_b);
      end if;
    end if;
  end if;
exception
  when others then
    l_log_fact_e.CODIGO            := SQLCODE;
    l_log_fact_e.DESCRIPCION       := SUBSTR('Error general en el trigger ' ||
                                             SQLERRM,
                                             0,
                                             999);
    l_log_fact_e.PROGRAMA          := '1-TRG_AID_FACTURA_E_A2000160';
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
  
end trg_aid_factura_e_a2000160;
/
