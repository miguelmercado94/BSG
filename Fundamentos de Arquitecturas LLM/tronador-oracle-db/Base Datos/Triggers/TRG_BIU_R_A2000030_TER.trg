CREATE OR REPLACE TRIGGER TRG_BIU_R_A2000030_TER
  BEFORE INSERT OR UPDATE OF NRO_DOCUMTO, TDOC_TERCERO, SEC_TERCERO ON A2000030 
  REFERENCING NEW AS NEW OLD AS OLD
  FOR EACH ROW
DECLARE
  V_PRIMERA       NATURALES.PRIMER_APELLIDO%TYPE;
  V_SEGUNDOA      NATURALES.SEGUNDO_APELLIDO%TYPE;
  V_PRIMERN       NATURALES.PRIMER_NOMBRE%TYPE;
  V_SEGUNDON      NATURALES.SEGUNDO_NOMBRE%TYPE;
  V_RAZON_SOCIAL  JURIDICOS.RAZON_SOCIAL%TYPE;
  V_TIPO          VARCHAR2(1);
  V_DESCTIPO      VARCHAR2(200);
  V_CODERR        C1991300.COD_ERROR%TYPE;
  V_MSGERR        C1991300.MSG_ERROR%TYPE;
  L_Secuencia     NUMBER := :new.Sec_Tercero;
  L_DATOS_FACTURA SIM_TYP_FACTURA_MVTOS;
  L_RESULTADO     NUMBER(1);
  --**************************************************
  --Fecha: 10-08-2020
  --Autor: Sheila Uhia
  --Modificado: Se le agrega al trigger una funcionalidad
  --            para notificar cuando haya cambio de Tomador
  --            para generarle una factura electrónica al nuevo tomador
  --            y una nota crédito electrónica al anterior tomador
  --Proyecto: Facturación Electrónica
BEGIN
  IF INSERTING THEN
    :new.Sec_Tercero := NULL;
    IF :NEW.NRO_DOCUMTO IS NOT NULL AND :NEW.TDOC_TERCERO IS NOT NULL THEN
      BEGIN
        --  :NEW.Sec_Tercero   := NULL;
        -- <Control>Mantis 48171</Control>
        -- <Date>31/08/2016</Date>
        -- <M.Author>Intasi28</M.Author>
        -- <Summary>
        --   Se comentarea Condición  If :New.Sec_Tercero Is Null Then para que 
        --   valide la secuenca del tercero siempre
        -- </Summary>
        -- If :New.Sec_Tercero Is Null Then
      
        PCK999_TERCEROS.PRC_DATOSD_TERCERO(:NEW.NRO_DOCUMTO,
                                           :NEW.TDOC_TERCERO,
                                           :NEW.SEC_TERCERO,
                                           V_PRIMERA,
                                           V_SEGUNDOA,
                                           V_PRIMERN,
                                           V_SEGUNDON,
                                           V_RAZON_SOCIAL,
                                           V_TIPO,
                                           V_DESCTIPO);
        -- End If; --si la secuencia tiene valor no se hace nada
      EXCEPTION
        WHEN OTHERS THEN
          BEGIN
            :new.Sec_Tercero := l_secuencia;
            V_CODERR         := SQLCODE;
            V_MSGERR         := SQLERRM;
          EXCEPTION
            WHEN DUP_VAL_ON_INDEX THEN
              NULL;
          END;
      END;
    ELSE
      IF :NEW.TDOC_TERCERO IS NULL OR :NEW.SEC_TERCERO IS NULL THEN
        BEGIN
          :NEW.SEC_TERCERO := NULL;
          PCK999_TERCEROS.PRC_DATOSD_TERCERO(:NEW.NRO_DOCUMTO,
                                             :NEW.TDOC_TERCERO,
                                             :NEW.SEC_TERCERO,
                                             V_PRIMERA,
                                             V_SEGUNDOA,
                                             V_PRIMERN,
                                             V_SEGUNDON,
                                             V_RAZON_SOCIAL,
                                             V_TIPO,
                                             V_DESCTIPO);
        EXCEPTION
          WHEN OTHERS THEN
            BEGIN
              :new.Sec_Tercero := l_secuencia;
              V_CODERR         := SQLCODE;
              V_MSGERR         := SQLERRM;
            EXCEPTION
              WHEN DUP_VAL_ON_INDEX THEN
                NULL;
            END;
        END;
      END IF;
    END IF;
  ELSE
    DECLARE
      VTIPO VARCHAR2(3) := NVL(:NEW.TDOC_TERCERO, :OLD.TDOC_TERCERO);
      VNRO  NUMBER(16) := NVL(:NEW.NRO_DOCUMTO, :OLD.NRO_DOCUMTO);
      VSEC  NUMBER(13) := NVL(:NEW.SEC_TERCERO, :OLD.SEC_TERCERO);
    BEGIN
      VSEC := NULL;
      PCK999_TERCEROS.PRC_DATOSD_TERCERO(VNRO,
                                         VTIPO,
                                         VSEC,
                                         V_PRIMERA,
                                         V_SEGUNDOA,
                                         V_PRIMERN,
                                         V_SEGUNDON,
                                         V_RAZON_SOCIAL,
                                         V_TIPO,
                                         V_DESCTIPO);
      :NEW.NRO_DOCUMTO  := VNRO;
      :NEW.TDOC_TERCERO := VTIPO;
      :NEW.SEC_TERCERO  := VSEC;
    EXCEPTION
      WHEN OTHERS THEN
        BEGIN
          :new.Sec_Tercero := l_secuencia;
          V_CODERR         := SQLCODE;
          V_MSGERR         := SQLERRM;
        EXCEPTION
          WHEN DUP_VAL_ON_INDEX THEN
            NULL;
        END;
    END;
  
    --******************************************
    --Inicio cambio para Facturación Electrónica
    BEGIN
      if :new.num_pol1 is not null and nvl(:new.mca_provisorio, 'N') = 'N' then
        IF (:OLD.NRO_DOCUMTO <> :NEW.NRO_DOCUMTO) THEN
        
          L_DATOS_FACTURA                      := NEW
                                                  SIM_TYP_FACTURA_MVTOS();
          L_DATOS_FACTURA.COD_CIA              := :NEW.COD_CIA;
          L_DATOS_FACTURA.COD_SECC             := :NEW.COD_SECC;
          L_DATOS_FACTURA.COD_RAMO             := :NEW.COD_RAMO;
          L_DATOS_FACTURA.NUM_POL1             := :NEW.NUM_POL1;
          L_DATOS_FACTURA.NUM_END              := :NEW.NUM_END;
          L_DATOS_FACTURA.NUM_SECU_POL         := :NEW.NUM_SECU_POL;
          L_DATOS_FACTURA.COD_SITUACION        := NULL;
          L_DATOS_FACTURA.FECHA_FACTURA        := TRUNC(SYSDATE);
          L_DATOS_FACTURA.FECHA_EQUIPO         := :new.Fecha_Equipo;
          L_DATOS_FACTURA.COD_MON              := :NEW.COD_MON;
          L_DATOS_FACTURA.COD_MON_IMPTOS       := NULL;
          L_DATOS_FACTURA.IMP_PRIMA            := 0;
          L_DATOS_FACTURA.IMP_IMPTOS_MON_LOCAL := 0;
          L_DATOS_FACTURA.FEC_VCTO             := NULL;
          L_DATOS_FACTURA.NUM_FACTURA          := NULL;
          L_DATOS_FACTURA.TC                   := :NEW.TC;
          L_DATOS_FACTURA.USUARIO_CREACION     := USER;
          L_DATOS_FACTURA.MCA_ORIGEN           := 'CT';
          L_DATOS_FACTURA.TIPO_MVTO            := 'I';
          L_DATOS_FACTURA.TDOC_TERCERO_ANT     := :OLD.TDOC_TERCERO;
          L_DATOS_FACTURA.NRO_DOCUMTO_ANT      := :OLD.NRO_DOCUMTO;
          L_DATOS_FACTURA.TDOC_TERCERO_NVO     := :NEW.TDOC_TERCERO;
          L_DATOS_FACTURA.NRO_DOCUMTO_NVO      := :NEW.NRO_DOCUMTO;
          L_DATOS_FACTURA.ESTADO               := 'CT';
        
          SIM_PCK_FACTURA_ELECTRONICA.PRC_INSERTAR_MVTOS_FAC(L_DATOS_FACTURA,
                                                             'TRG',
                                                             L_RESULTADO);
        END IF;
      end if;
    END;
    --Fin cambio para Facturación Electrónica
    --***************************************
  
  END IF;

EXCEPTION
  WHEN OTHERS THEN
    :new.Sec_Tercero := l_secuencia;
    V_CODERR         := SQLCODE;
    V_MSGERR         := SQLERRM;
END TRG_BIU_R_A2000030_TER;
/
