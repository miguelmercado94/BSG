CREATE OR REPLACE TRIGGER trg_aiud_factura_e
  after insert or delete or update of cod_cia, cod_secc, cod_ramo, num_pol1, num_end, num_secu_pol, cod_situacion, fecha_creacion, fecha_equipo, cod_mon, cod_mon_imptos, imp_prima, imp_imptos_mon_local, fec_vcto, num_factura, tc on a2990700
  referencing new as new old as old
  for each row
declare
  /*--------------------------------------------------------
  Fecha de creación: 17/07/2020
  Autor: Sheila Uhia
  Objetivo: Trigger para insertar los movimientos
  de las facturas en la tabla SIM_FACTURA_MVTOS
  para generar la factura electrónica
  Proyecto: FACTURACIÓN ELECTRÓNICA
  --------------------------------------------------------*/
  l_datos_factura sim_typ_factura_mvtos;
  l_resultado     number(1);
  l_log_fact_e    sim_typ_log_factura_e;
  l_cod_secc      a2990700.cod_secc%type;
  l_mca_ahorro    varchar2(1) := 'N';
  l_mca_estado    varchar2(1) := 'N';
  l_fecha_factura date := :new.fecha_creacion;

begin
  l_log_fact_e := new sim_typ_log_factura_e();

  if inserting or updating then
  
    --Se consultan las secciones que no se van a procesar con la tabla a2990700 sino con la a2000160
    begin

      select d.Cod_Secc
        into l_cod_secc
        from c9999909 d
       where d.cod_tab = 'FACTURACION_ELEC'
         and d.dat_car2 = 'PRODUCTOS_PROC_INDP'
         and d.fecha_act is not null
         and d.fecha_baja is null
         and d.cod_cia = :new.cod_cia
         and d.cod_secc = :new.cod_secc;
    exception
      when no_data_found then
        l_cod_secc  := null;
    end;
  
    if (l_cod_secc is not null) then
        begin
          --Se valida si al ramo se le debe generar la factura 
          --cuando el cliente haya pagado
          select d.cod_secc
            into l_cod_secc
            from C9999909 d
           where d.cod_tab = 'FACTURACION_ELEC'
             and d.dat_car2 = 'RAMO_PAGO_CLIENTE'
             and d.fecha_act is not null
             and d.fecha_baja is null
             and d.cod_cia = :new.cod_cia
             and d.cod_secc = :new.cod_secc;
        exception
          when no_data_found then
            l_cod_secc := null;
        end;
    
        -- ESTNOCORE-433-- Nov. 2024
        -- Se adiciona el control de duplicidad en Secc 70(ARL) y 50
        IF :new.cod_situacion IN ('EP', 'CT') THEN
            BEGIN
                -- Valida que el movimiento no haya sido insertado, para evitar duplicados.
                -- Tanto en secc 39 como en Secc: 70 y 50
                --   ESTCORE-7194 MICHAEL ESPINOSA MAYO 2023
                SELECT 'N'
                INTO l_mca_estado
                FROM SIM_FACTURA_MVTOS M
                WHERE M.NUM_SECU_POL = :new.num_secu_pol
                  AND M.num_end = :new.num_end
                  AND M.num_factura = :new.num_factura
                  AND M.COD_SITUACION = :new.cod_situacion
                  AND M.MCA_ORIGEN = 'FA'
                  AND M.TIPO_MVTO = 'I'
                  AND M.IMP_PRIMA = :new.imp_prima
                  AND M.IMP_IMPTOS_MON_LOCAL = :new.imp_imptos_mon_local;
            EXCEPTION
                WHEN NO_DATA_FOUND THEN
                    -- SECC 39 Inserta por 'EP'
                    IF (l_cod_secc IS NULL AND :new.cod_situacion = 'EP') THEN
                        l_mca_estado := 'S';
                        l_fecha_factura := :new.fecha_creacion;
                    -- SECC 70 y 50 Inserta por 'CT'    
                    ELSIF (l_cod_secc IS NOT NULL AND :new.cod_situacion = 'CT') THEN
                        l_mca_estado := 'S';
                        l_fecha_factura := :new.fec_situ;
                    END IF;
            END;
        END IF;
    
      --Se valida que el registro no sea de Ahorro para las pólizas de Liberty
      if (:new.cod_secc = 50 and :new.tipo_emision = 'AH') then
        l_mca_ahorro := 'S';
      end if;
    
      --Se validan los estados de la factura
      if l_mca_estado = 'S' and :new.num_end is not null and
         l_mca_ahorro = 'N' then
      
        l_datos_factura                      := new sim_typ_factura_mvtos();
        l_datos_factura.cod_cia              := :new.cod_cia;
        l_datos_factura.cod_secc             := :new.cod_secc;
        l_datos_factura.cod_ramo             := :new.cod_ramo;
        l_datos_factura.num_pol1             := :new.num_pol1;
        l_datos_factura.num_end              := :new.num_end;
        l_datos_factura.num_secu_pol         := :new.num_secu_pol;
        l_datos_factura.cod_situacion        := :new.cod_situacion;
        l_datos_factura.fecha_factura        := l_fecha_factura;
        l_datos_factura.fecha_equipo         := :new.fecha_equipo;
        l_datos_factura.cod_mon              := :new.cod_mon;
        l_datos_factura.cod_mon_imptos       := :new.cod_mon_imptos;
        l_datos_factura.imp_prima            := :new.imp_prima;
        l_datos_factura.imp_imptos_mon_local := :new.imp_imptos_mon_local;
        l_datos_factura.fec_vcto             := :new.fec_vcto;
        l_datos_factura.num_factura          := :new.num_factura;
        l_datos_factura.tc                   := :new.tc;
        l_datos_factura.mca_origen           := 'FA';
        l_datos_factura.tipo_mvto            := 'I';
        l_datos_factura.estado               := 'PE';
        if inserting then
          l_datos_factura.usuario_creacion := USER;
        elsif updating then
          l_datos_factura.usuario_modificacion := USER;
        end if;
      
        sim_pck_factura_electronica.prc_insertar_mvtos_fac(l_datos_factura,
                                                           'TRG',
                                                           l_resultado);
      end if;
    end if;
  end if;

  if deleting then
  
    --Se consultan las secciones que no se van a procesar con la tabla a2990700 sino con la a2000160
    begin
    
      select d.Cod_Secc
        into l_cod_secc
        from c9999909 d
       where d.cod_tab = 'FACTURACION_ELEC'
         and d.dat_car2 = 'PRODUCTOS_PROC_INDP'
         and d.fecha_act is not null
         and d.fecha_baja is null
         and d.cod_cia = :old.cod_cia
         and d.cod_secc = :old.cod_secc;
    exception
      when no_data_found then
        l_cod_secc := null;
    end;
  
    if (l_cod_secc is not null) then
    
      --Se valida que el registro no sea de Ahorro para las pólizas de Liberty
      if (:old.cod_secc = 50 and :old.tipo_emision = 'AH') then
        l_mca_ahorro := 'S';
      end if;
    
      --Se validan los estados de la factura
      if :old.num_end is not null and l_mca_ahorro = 'N' then
      
        l_datos_factura                      := new sim_typ_factura_mvtos();
        l_datos_factura.cod_cia              := :old.cod_cia;
        l_datos_factura.cod_secc             := :old.cod_secc;
        l_datos_factura.cod_ramo             := :old.cod_ramo;
        l_datos_factura.num_pol1             := :old.num_pol1;
        l_datos_factura.num_end              := :old.num_end;
        l_datos_factura.num_secu_pol         := :old.num_secu_pol;
        l_datos_factura.cod_situacion        := :old.cod_situacion;
        l_datos_factura.fecha_factura        := :old.fecha_creacion;
        l_datos_factura.fecha_equipo         := :old.fecha_equipo;
        l_datos_factura.cod_mon              := :old.cod_mon;
        l_datos_factura.cod_mon_imptos       := :old.cod_mon_imptos;
        l_datos_factura.imp_prima            := :old.imp_prima;
        l_datos_factura.imp_imptos_mon_local := :old.imp_imptos_mon_local;
        l_datos_factura.fec_vcto             := :old.fec_vcto;
        l_datos_factura.num_factura          := :old.num_factura;
        l_datos_factura.tc                   := :old.tc;
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
  
  end if;
exception
  when others then
    l_log_fact_e.CODIGO            := SQLCODE;
    l_log_fact_e.DESCRIPCION       := SUBSTR('Error general en el trigger ' ||
                                             SQLERRM,
                                             0,
                                             999);
    l_log_fact_e.PROGRAMA          := '1-TRG_BIUD_FACTURA_E';
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
  
end trg_aiud_factura_e;
/
