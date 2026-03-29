CREATE OR REPLACE TRIGGER TRG_CAMBIOS_A2000030
  AFTER INSERT OR UPDATE OR DELETE ON A2000030 
  REFERENCING NEW AS NEW OLD AS OLD
  FOR EACH ROW
DECLARE
  cambio          BOOLEAN := FALSE;
  mca_procesado   VARCHAR2(1);
  l_datos_fe      sim_typ_polizas_borradas_fe;
  l_resultado     number(1);
  l_datos_factura sim_typ_factura_mvtos;
  /******************************************************************************
    NAME:    Michel Tachack
    PURPOSE: Resgistrar modificaciones de poliza o polizas nuevas para
             pasar datos a TERCEROS
    Hecho 07/12/2006
    Modifico 29/01/2007  Deleting new por old
    --***************************************************************************
    --Fecha: 11-08-2020
    --Autor: Sheila Uhia
    --Modificado: Se le agrega al trigger una funcionalidad
    --            para guardar los datos de la póliza cuando se borre.
    --            También se contempla la emisión de un endoso para analizar
    --            si hay cambio de tomador
    --Proyecto: Facturación Electrónica
  ******************************************************************************/
BEGIN
  IF INSERTING THEN
    IF NVL(:NEW.num_pol1, 0) != 0 AND NVL(:NEW.mca_provisorio, 'N') != 'S' THEN
      cambio        := TRUE;
      mca_procesado := NULL;
    END IF;
    --******************************************
    --Inicio cambio para Facturación Electrónica - Cambio de Tomador
    if cambio = TRUE and :new.num_end > 0 then
    
      l_datos_factura                      := new sim_typ_factura_mvtos();
      l_datos_factura.cod_cia              := :new.cod_cia;
      l_datos_factura.cod_secc             := :new.cod_secc;
      l_datos_factura.cod_ramo             := :new.cod_ramo;
      l_datos_factura.num_pol1             := :new.num_pol1;
      l_datos_factura.num_end              := :new.num_end;
      l_datos_factura.num_secu_pol         := :new.num_secu_pol;
      l_datos_factura.cod_situacion        := null;
      l_datos_factura.fecha_factura        := trunc(sysdate);
      l_datos_factura.fecha_equipo         := :new.fecha_equipo;
      l_datos_factura.cod_mon              := :new.cod_mon;
      l_datos_factura.cod_mon_imptos       := null;
      l_datos_factura.imp_prima            := 0;
      l_datos_factura.imp_imptos_mon_local := 0;
      l_datos_factura.fec_vcto             := null;
      l_datos_factura.num_factura          := null;
      l_datos_factura.tc                   := :new.tc;
      l_datos_factura.usuario_creacion     := user;
      l_datos_factura.mca_origen           := 'CT';
      l_datos_factura.tipo_mvto            := 'I';
      l_datos_factura.tdoc_tercero_ant     := null;
      l_datos_factura.nro_documto_ant      := null;
      l_datos_factura.tdoc_tercero_nvo     := :new.tdoc_tercero;
      l_datos_factura.nro_documto_nvo      := :new.nro_documto;
      l_datos_factura.estado               := 'CT';
    
      sim_pck_factura_electronica.prc_insertar_mvtos_fac(l_datos_factura,
                                                         'TRG',
                                                         l_resultado);
    
    end if;
  
    --Fin cambio para Facturación Electrónica - Cambio de Tomador
    --***************************************    
  
  ELSIF UPDATING THEN
    IF (NVL(:NEW.num_pol1, 0) != 0 AND NVL(:OLD.num_pol1, 0) = 0) OR
       (NVL(:OLD.mca_provisorio, 'N') != NVL(:NEW.mca_provisorio, 'N')) THEN
      cambio        := TRUE;
      mca_procesado := NULL;
    END IF;
  ELSIF DELETING THEN
    IF (NVL(:OLD.num_pol1, 0) != 0) AND
       (NVL(:OLD.mca_provisorio, 'N') != 'S') THEN
      cambio        := TRUE;
      mca_procesado := 'B';
    END IF;
    --*************************************************
    --Inicio Facturación Electrónica - Borrado de pólizas
  
    if :old.num_pol1 is not null and nvl(:old.mca_provisorio, 'N') = 'N' then
      begin
        l_datos_fe := new sim_typ_polizas_borradas_fe();
      
        l_datos_fe.cod_cia          := :old.cod_cia;
        l_datos_fe.cod_secc         := :old.cod_secc;
        l_datos_fe.cod_ramo         := :old.cod_ramo;
        l_datos_fe.sim_subproducto  := :old.sim_subproducto;
        l_datos_fe.num_pol1         := :old.num_pol1;
        l_datos_fe.num_secu_pol     := :old.num_secu_pol;
        l_datos_fe.num_end          := :old.num_end;
        l_datos_fe.tdoc_tercero     := :old.tdoc_tercero;
        l_datos_fe.nro_documto      := :old.nro_documto;
        l_datos_fe.sec_tercero      := :old.sec_tercero;
        l_datos_fe.cod_end          := :old.cod_end;
        l_datos_fe.sub_cod_end      := :old.sub_cod_end;
        l_datos_fe.tipo_end         := :old.tipo_end;
        l_datos_fe.fecha_emi        := :old.fecha_emi;
        l_datos_fe.fecha_emi_end    := :old.fecha_emi_end;
        l_datos_fe.cod_mon          := :old.cod_mon;
        l_datos_fe.tc               := :old.tc;
        l_datos_fe.periodo_fact     := :old.periodo_fact;
        l_datos_fe.usuario_creacion := USER;
      
        sim_pck_factura_electronica.prc_insertar_polizas_borradas(l_datos_fe,
                                                                  'TRG',
                                                                  l_resultado);
      exception
        when others then
          null;
      end;
    end if;
  
    --Fin Facturación Electrónica - Borrado de pólizas
    --*************************************************
  
  END IF;
  IF cambio = TRUE THEN
    IF DELETING THEN
      PRC_REGISTRO_CAMBIOS(:OLD.num_Secu_pol, :OLD.num_end, mca_procesado);
    ELSE
      PRC_REGISTRO_CAMBIOS(:NEW.num_Secu_pol, :NEW.num_end, mca_procesado);
    END IF;
  END IF;
END;
/
