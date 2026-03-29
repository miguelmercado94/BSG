CREATE OR REPLACE TRIGGER AUDI_1600
AFTER INSERT OR DELETE OR UPDATE ON a5021600
FOR EACH ROW
BEGIN
  IF  DELETING THEN
    BEGIN
         DECLARE batch varchar2(2);
                 estado varchar2(1);
         BEGIN
            SELECT mca_batch, mca_estado
		      INTO batch, estado
              FROM a5021700
             WHERE cod_cia = :OLD.cod_cia;
            IF estado <> 'C' THEN
--              DELETE a502_audi
--			   WHERE cod_cia_audi          = :OLD.cod_cia
--				 AND  fec_asiento_audi      = :OLD.fec_asiento
--				 AND  num_asiento_audi      = :OLD.num_asiento
--				 AND  num_recibo_audi       = :OLD.recibo;
              DELETE a502_audi
				 WHERE cod_cia_audi           = :OLD.cod_cia
				 AND  fec_asiento_audi      = :OLD.fec_asiento
				 AND  num_asiento_audi      = :OLD.num_asiento
				 AND  num_oper_asiento_audi = :OLD.num_oper_asiento
				 ;
            END IF;
         END;
    END;
  ELSIF UPDATING OR INSERTING THEN
        BEGIN
          IF ((:NEW.TIPO_ACTU        = 'CB'  AND
               :NEW.MCA_DEBE_HABER   = 'D'   AND
	           :NEW.MCA_CAJA_BCO     = 'C' ) OR
              (:NEW.TIPO_ACTU        = 'TT'  AND
		       :NEW.MCA_DEBE_HABER   = 'D'   AND
               :NEW.MCA_CAJA_BCO     = 'B')  OR
              (:NEW.TIPO_ACTU        = 'TT'  AND
		       :NEW.MCA_DEBE_HABER   = 'H'   AND
               :NEW.COD_PAGO         =  2    AND
		       :NEW.MCA_CAJA_BCO     = 'B')  OR
              (:NEW.TIPO_ACTU        = 'TT'  AND
		       :NEW.MCA_DEBE_HABER   in  ('H','D')   AND
               :NEW.COD_PAGO         =  2    AND
		       :NEW.MCA_CAJA_BCO     = 'C')  OR
              (:NEW.TIPO_ACTU        = 'TT'  AND
		       :NEW.MCA_DEBE_HABER   = 'D'   AND
		       :NEW.COD_PAGO         in(1,5) AND
               :NEW.MCA_CAJA_BCO     = 'C' ) OR
			   (:NEW.TIPO_ACTU       = 'CB'  AND
			   :NEW.MCA_DEBE_HABER   = 'D'   AND
			   :NEW.MCA_CAJA_BCO     = 'B')  OR
              (:NEW.TIPO_ACTU        = 'CB'  AND
               :NEW.MCA_DEBE_HABER   = 'D'   AND
		       :NEW.COD_PAGO         IN(4,6) AND
		       :NEW.MCA_CAJA_BCO     = 'G')) THEN
            BEGIN
              UPDATE a502_audi
				 SET COD_CIA_AUDI              = :NEW.COD_CIA,
                     FEC_ASIENTO_AUDI          = :NEW.FEC_ASIENTO,
                     COD_OFIC_CONTAB_AUDI      = :NEW.COD_OFIC_CONTAB,
                     COD_OFIC_CIAL_AUDI        = :NEW.COD_OFIC_CIAL,
                     NUM_ASIENTO_AUDI          = :NEW.NUM_ASIENTO,
                     NUM_OPER_ASIENTO_AUDI     = :NEW.NUM_OPER_ASIENTO,
                     TIPO_ACTU_AUDI            = :NEW.TIPO_ACTU,
                     COD_USER_AUDI             = :NEW.COD_USER,
                     COD_CTA_CTABLE_AUDI       = :NEW.COD_CTA_CTABLE,
                     TIPO_CTA_AUX1_AUDI        = :NEW.TIPO_CTA_AUX1,
                     NUM_IDENTIF_AUX1_AUDI     = :NEW.NUM_IDENTIF_AUX1,
                     FECHA_VALOR_AUDI          = :NEW.FECHA_VALOR,
                     FECHA_VCTO_AUDI           = :NEW.FECHA_VCTO,
                     DESC_MOVIM_AUDI           = :NEW.DESC_MOVIM,
                     IMP_MON_PAIS_AUDI         = :NEW.IMP_MON_PAIS,
                     MCA_DEBE_HABER_AUDI       = :NEW.MCA_DEBE_HABER,
                     COD_PAGO_AUDI             = :NEW.COD_PAGO,
                     NOMBRE_ENTIDAD_TALON_AUDI = :NEW.NOMBRE_ENTIDAD_TALON,
                     MCA_CAJA_BCO_AUDI         = :NEW.MCA_CAJA_BCO,
                     COD_USER_REC_AUDI         = :NEW.COD_USER_REC,
                     COD_CTA_SIMPLIF_AUDI      = :NEW.COD_CTA_SIMPLIF,
                     COD_BANCO_AUDI            = :NEW.COD_BANCO,
                     NUM_RECIBO_AUDI           = :NEW.RECIBO,
                     COD_TARJETA_AUDI          = :NEW.COD_TARJETA
               WHERE COD_CIA_AUDI              = :OLD.COD_CIA
		 AND NUM_ASIENTO_AUDI          = :OLD.NUM_ASIENTO
		 AND NUM_OPER_ASIENTO_AUDI     = :OLD.NUM_OPER_ASIENTO
		 AND FEC_ASIENTO_AUDI          = :OLD.FEC_ASIENTO;
              IF SQL%NOTFOUND THEN
                 INSERT INTO a502_audi (
                             COD_CIA_AUDI,
                             FEC_ASIENTO_AUDI,
                             COD_OFIC_CONTAB_AUDI,
				             COD_OFIC_CIAL_AUDI,
                             NUM_ASIENTO_AUDI,
                             NUM_OPER_ASIENTO_AUDI,
                             TIPO_ACTU_AUDI,
                             COD_USER_AUDI,
                             COD_CTA_CTABLE_AUDI,
                             TIPO_CTA_AUX1_AUDI,      /*consignacion 'CO'*/
                             NUM_IDENTIF_AUX1_AUDI,   /*numero de consignacion*/
                             FECHA_VALOR_AUDI,
                             FECHA_VCTO_AUDI,
                             DESC_MOVIM_AUDI,
                             IMP_MON_PAIS_AUDI,
                             MCA_DEBE_HABER_AUDI,
                             COD_PAGO_AUDI,
                             NOMBRE_ENTIDAD_TALON_AUDI,
                             MCA_CAJA_BCO_AUDI,
                             COD_USER_REC_AUDI,
                             COD_CTA_SIMPLIF_AUDI,
                             COD_BANCO_AUDI,
                             NUM_RECIBO_AUDI,
                             COD_TARJETA_AUDI,
                             FEC_CONTROL_AUDI )
                    VALUES (:NEW.COD_CIA,
                            :NEW.FEC_ASIENTO,
                            :NEW.COD_OFIC_CONTAB,
			                :NEW.COD_OFIC_CIAL,
                            :NEW.NUM_ASIENTO,
                            :NEW.NUM_OPER_ASIENTO,
                            :NEW.TIPO_ACTU,
                            :NEW.COD_USER,
                            :NEW.COD_CTA_CTABLE,
                            :NEW.TIPO_CTA_AUX1,
                            :NEW.NUM_IDENTIF_AUX1,
                            :NEW.FECHA_VALOR,
                            :NEW.FECHA_VCTO,
                            :NEW.DESC_MOVIM,
                            :NEW.IMP_MON_PAIS,
                            :NEW.MCA_DEBE_HABER,
                            :NEW.COD_PAGO,
                            :NEW.NOMBRE_ENTIDAD_TALON,
                            :NEW.MCA_CAJA_BCO,
                            :NEW.COD_USER_REC,
                            :NEW.COD_CTA_SIMPLIF,
                            :NEW.COD_BANCO,
                            :NEW.RECIBO,
                            :NEW.COD_TARJETA,
                            :NEW.FEC_ASIENTO );
              END IF;
            END;
          END IF;
        END;
     END IF;
END;
/
