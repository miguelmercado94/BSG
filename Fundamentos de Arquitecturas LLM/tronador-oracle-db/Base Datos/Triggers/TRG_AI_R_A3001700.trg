CREATE OR REPLACE TRIGGER TRG_AI_R_A3001700
  AFTER INSERT OR UPDATE ON A3001700
  FOR EACH ROW
  when ((NEW.COD_SECC = 33 AND NEW.COD_CIA = 3) OR
      --inicio marca de modificacion 1
       (NEW.COD_SECC = 18 AND NEW.COD_CIA = 2))
--fin marca de modificacion 1
DECLARE
  -------------------------------------------------------------------------------
  -- Objetivo : Identificar cuando se elabora una liquidación de desempleo para informar
  --            a DAVIVIENDA via Email MANTIS 48348
  -- Autor    : Richard Ibarra - Asesoftware
  -- Fecha    : 17/02/2017
  -- 07/MAR/2019 Modificación: se valida si la orden queda en CT. Si es así no se
  --                           envía email a Davivienda
  /*
   MODIFICADO: Michael Espinosa
   FECHA : Abril 07 de 2022
   Descripción        : Se actualiza para incluir la sección 18 de la compañia 2 en los productos 540 y 541 conservando
                      la misma logica del trigger.
   Marca modificacion : 1
  */
  -------------------------------------------------------------------------------
  vl_cod_ramo number;
BEGIN

  select distinct d.cod_ramo
    into vl_cod_ramo
    from a7000900 d
   where d.cod_cia = :new.cod_cia
     and d.cod_secc = :new.cod_secc
     and d.num_sini = :new.num_sini;

  IF (:new.cod_secc = 33 AND vl_cod_ramo IN (500, 501)) OR
    --inicio marca de modificacion 1
     (:new.cod_secc = 18 AND vl_cod_ramo IN (540, 541)) THEN
    --fin marca de modificacion 1
    IF INSERTING AND NVL(:new.mca_transit, 'N') = 'N' THEN
      SIM_PCK_PROCESO_LIQUIDACION.Proc_Liq_desempleo_email(IP_COD_CIA         => :NEW.COD_CIA,
                                                           IP_COD_SECC        => :NEW.COD_SECC,
                                                           IP_NUM_SINI        => :NEW.NUM_SINI,
                                                           IP_TOTAL_BRUTO_LIQ => NVL(:NEW.TOTAL_BRUTO_LIQ,
                                                                                     :OLD.TOTAL_BRUTO_LIQ),
                                                           IP_NRO_CUOTA       => :NEW.OBSERVACION,
                                                           IP_NUM_SECU_LIQ    => :NEW.NUM_SECU_LIQ,
                                                           IP_COD_BENEF       => :NEW.COD_BENEF);
    
    ELSIF UPDATING THEN
      UPDATE sim_msj_liq_desempleo
         SET VALOR_GIRADO = :NEW.TOTAL_BRUTO_LIQ
       WHERE NUM_SECU_LIQ = :OLD.NUM_SECU_LIQ;
      IF (:old.mca_transit = 'S' and NVL(:new.mca_transit, 'N') = 'N') THEN
        -- Se levanta control
        SIM_PCK_PROCESO_LIQUIDACION.Proc_Liq_desempleo_email(IP_COD_CIA         => :NEW.COD_CIA,
                                                             IP_COD_SECC        => :NEW.COD_SECC,
                                                             IP_NUM_SINI        => :NEW.NUM_SINI,
                                                             IP_TOTAL_BRUTO_LIQ => NVL(:NEW.TOTAL_BRUTO_LIQ,
                                                                                       :OLD.TOTAL_BRUTO_LIQ),
                                                             IP_NRO_CUOTA       => :NEW.OBSERVACION,
                                                             IP_NUM_SECU_LIQ    => :NEW.NUM_SECU_LIQ,
                                                             IP_COD_BENEF       => :NEW.COD_BENEF);
      END IF;
    END IF;
  END IF;

EXCEPTION
  WHEN OTHERS THEN
    NULL;
END TRG_AI_R_A3001700;
/
