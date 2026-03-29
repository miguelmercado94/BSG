CREATE OR REPLACE TRIGGER a2000040_COB_RCC_RUNT
AFTER INSERT  ON A2000040
FOR EACH ROW
WHEN ((NEW.COD_COB = 365 OR NEW.COD_COB = 427) AND (NEW.TIPO_REG = 'T'))
DECLARE
 /*
  PROPOSITO:
  VERSION  FECHA     RESPONSABLE      DESCRIPCION
  ------- ---------- ------------     ----------------------
    1     31/10/2022 Carlos Mayorga   Modificacion para no enviar datos de pólizas subproducto 370 GD549-115
                                      Marca modificacion 1
  */
  LV_COD_SECC       NUMBER(3)     := NULL;
  LV_EXISTE         VARCHAR2(1)   := NULL;
  L_ERROR           VARCHAR2(200) := NULL;
  LV_COD_END        NUMBER(3)     := NULL;
  LV_SUB_COD_END    NUMBER(3)     := NULL;
  LV_VALOR_S        VARCHAR2(1)   := 'S';
  LV_VALOR_999      NUMBER(3)     := 999;
-- Inicio marca modificacion 1
  LV_SUBPRODUCTO    NUMBER(3)     := NULL;
-- Fin marca modificacion 1
  BEGIN
    BEGIN
      SELECT COD_SECC
      INTO   LV_COD_SECC
      FROM   C9999909
      WHERE  COD_TAB = 'COBERTURAS_RUNT'
        AND  CODIGO  = :NEW.COD_COB;
      --Se determina si la cobertura es de autos
      BEGIN
        SELECT P.COD_END
              ,P.SUB_COD_END
-- Inicio marca modificacion 1
              ,P.SIM_SUBPRODUCTO
-- Fin marca modificacion 1
        INTO   LV_COD_END
              ,LV_SUB_COD_END
-- Inicio marca modificacion 1
              ,LV_SUBPRODUCTO
-- Fin marca modificacion 1
        FROM   A2000030 P
        WHERE  P.NUM_SECU_POL  = :NEW.NUM_SECU_POL
          AND  P.NUM_END       = :NEW.NUM_END
          AND  P.COD_SECC      = LV_COD_SECC;
-- Inicio marca modificacion 1 
-- En la adicion y exclusion de riesgos aun no se tiene el subproducto
        IF LV_SUBPRODUCTO IS NULL THEN
          BEGIN
            LV_SUBPRODUCTO := Fun_RESCATA_X2000020 ('PRODUCTOS', :NEW.NUM_SECU_POL, null);
          EXCEPTION
            WHEN OTHERS THEN
              LV_SUBPRODUCTO := NULL;
          END;
        END IF;
-- Inicio marca modificacion 1 
        --se debe validar si ya se creo el registro en la tabla
        --Se valida el codigo de endoso (solo emision, incluison o exclusion)
        IF (LV_COD_END IS NULL OR LV_COD_END = 730 OR LV_COD_END = 731 OR LV_COD_END = 100)
-- Inicio marca modificacion 1
          AND NVL(LV_SUBPRODUCTO,0) <> 370
-- Fin marca modificacion 1
        THEN 
          BEGIN
            SELECT 'S'
            INTO   LV_EXISTE
            FROM   SIM_TRANSMITIR_RUNT
            WHERE  NUM_SECU_POL                  = :NEW.NUM_SECU_POL
              AND  NUM_END                       = :NEW.NUM_END
              AND  COD_RIES                      = :NEW.COD_RIES
              AND  NVL(COD_END,LV_VALOR_999)     = NVL(LV_COD_END,LV_VALOR_999)
              AND  NVL(SUB_COD_END,LV_VALOR_999) = NVL(LV_SUB_COD_END,LV_VALOR_999);
          EXCEPTION
            WHEN NO_DATA_FOUND THEN
              BEGIN
                INSERT INTO SIM_TRANSMITIR_RUNT
                (
                 NUM_SECU_POL
                ,NUM_END
                ,COD_RIES
                ,FECHA_CREACION
                ,MCA_PROCESADO
                ,COD_END
                ,SUB_COD_END
                )
                VALUES
                (
                 :NEW.NUM_SECU_POL
                ,:NEW.NUM_END
                ,:NEW.COD_RIES
                ,TRUNC(SYSDATE)
                ,'P'
                ,LV_COD_END
                ,LV_SUB_COD_END
                );
                COMMIT;
              EXCEPTION
                WHEN OTHERS THEN
                     L_ERROR := SQLERRM;
                     SIM_PROC_LOG('TRANSMISION RUNT','Error Insert SIM_TRANSMITIR_RUNT para: '||
                                  'Secuencia: '||:NEW.NUM_SECU_POL ||' Endoso: '||:NEW.NUM_END|| ' Tipo Reg: '||
                                  :NEW.TIPO_REG||' Cobertura: '||:NEW.COD_COB|| ' Error: '||L_ERROR);
              END;
            WHEN OTHERS THEN
                 L_ERROR := SQLERRM;
                 SIM_PROC_LOG('TRANSMISION RUNT','Error Select SIM_TRANSMITIR_RUNT para: '||
                              'Secuencia: '||:NEW.NUM_SECU_POL ||' Endoso: '||:NEW.NUM_END|| ' Tipo Reg: '||
                              :NEW.TIPO_REG||' Cobertura: '||:NEW.COD_COB|| ' Error: '||L_ERROR);
          END;
        END IF;
      EXCEPTION
        WHEN OTHERS THEN
           SIM_PROC_LOG('TRANSMISION RUNT','Marca No Valida para: '||
                        'Secuencia: '||:NEW.NUM_SECU_POL ||' Endoso: '||:NEW.NUM_END|| ' Tipo Reg: '||
                        :NEW.TIPO_REG||' Cobertura: '||:NEW.COD_COB||' Error: '|| sqlerrm);
      END;
    EXCEPTION
      WHEN OTHERS THEN
           SIM_PROC_LOG('TRANSMISION RUNT','Fallo No Encontro Seccion en parametricas para: '||
                        'Secuencia: '||:NEW.NUM_SECU_POL ||' Endoso: '||:NEW.NUM_END|| ' Tipo Reg: '||
                        :NEW.TIPO_REG||' Cobertura: '||:NEW.COD_COB);
    END;
  END a2000040_COB_RCC_RUNT;
/
