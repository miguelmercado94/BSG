CREATE OR REPLACE TRIGGER TR_AIU_SIMAPI_COBERTURAS_BIEN
  AFTER INSERT OR UPDATE ON SIMAPI_COBERTURAS_BIEN
  FOR EACH ROW
DECLARE

    l_existeCobCia       NUMBER;
    l_existeDVCia        NUMBER;
    l_existeDVCiaRamo    NUMBER;

  BEGIN
    IF nvl(:OLD.COD_COB,0) <> nvl(:NEW.COD_COB,0) THEN
     IF  :NEW.COD_COB IS NOT NULL THEN
     -- Se valida que exista la cobertura para la compañía
     SELECT COUNT(*)
       INTO l_existeCobCia
       FROM a1002100 a
      WHERE a.cod_cob = :NEW.COD_COB
        AND a.cod_cia = :NEW.COD_CIA
        AND a.cod_ramo = DECODE (:NEW.COD_CIA, 2, 922, 923);
      
      IF l_existeCobCia > 0 THEN
         -- Se valida que el dato variable de deducible exista para la compañía
         SELECT COUNT(*)
           INTO l_existeDVCia
           FROM G2000010 g
          WHERE g.cod_campo = 'API_DEDU_'||:NEW.COD_COB
            AND g.cod_cia   =  :NEW.COD_CIA;   
          
          IF l_existeDVCia = 0 THEN
             INSERT INTO G2000010 (COD_CIA, COD_CAMPO, TXT_TITULO, LONG_CAMPO, TIPO_CAMPO, COD_NIVEL_SIST, COD_TIPO_DATO, MCA_SINI, COD_REGLA, COD_USER, MCA_BAJA, NUM_SECU, ACEPTA_NULL, OBLIGATORIO, TABLA_VAL, PGM_HELP, LISTA_VALORES, REG_PRE_FIELD, TEXTO_ERROR, VALOR_DEFECTO, OPERADOR, TXT_HELP, MCA_DENUNCIA, MCA_VALIDA, MCA_PPAL)
                           VALUES (:NEW.COD_CIA,'API_DEDU_'||:NEW.COD_COB, 'DEDUCIBLE', 15, 'N', '2', '1', null, null, substr(USER,1,8), null, null, 'S', 'N', null, null, null, null, null, null, null, null, 'N', null, null);
          END IF; 
          
          --Se valida que exista el Dato variable por compañía y ramo
          SELECT COUNT(*)
            INTO l_existeDVCiaRamo
            FROM G2000020 h
           WHERE h.cod_cia = :NEW.COD_CIA
             AND h.cod_ramo = DECODE (:NEW.COD_CIA, 2, 922, 923)
             AND h.cod_campo = 'API_DEDU_'||:NEW.COD_COB;
             
          IF l_existeDVCiaRamo = 0 THEN
             insert into G2000020 (COD_CIA, COD_RAMO, NUM_SECU, COD_CAMPO, COD_NIVEL, COD_REGLA, MCA_BAJA, MCA_PPTO, ACEPTA_NULL, MCA_VISIBLE, TABLA_VAL, PGM_HELP, LISTA_VALORES, REG_PRE_FIELD, TEXTO_ERROR, VALOR_DEFECTO, OPERADOR, OBLIGATORIO, COD_COB, COD_AGRAVANTE, COD_USR, TXT_HELP, CLAUSULAS, MCA_IMPRE, CLAVE_TARIFICA, HAY_VALIDACION, MCA_VALIDA_CIA, MCA_LISTA, CLAVE_COBERT, TABLA_VALORES, TABLA_VAL_DEFEC, TAB_VAL_DEF_CAMPO, COD_LISTA, MCA_PPAL, MCA_REASEGURO, RAMO_ANEXO, PROD_ANEXO)
                           values (:NEW.COD_CIA, DECODE (:NEW.COD_CIA, 2, 922, 923), 10, 'API_DEDU_'||:NEW.COD_COB, 3, null, null, 'S', 'S', 'S', null, null, null, '922PVV009', null, null, null, 'S', :NEW.COD_COB, null, substr(USER,1,8), null, null, null, null, null, null, null, null, null, null, null, null, 'N', 'N', null, null);
          END IF;     
      ELSE
        raise_application_error(-20100,'Error, No existe la cobertura '||:NEW.COD_COB||' para la compañía '||:NEW.COD_CIA);
      END IF;   
     END IF;   
    END IF;
  END;
/
