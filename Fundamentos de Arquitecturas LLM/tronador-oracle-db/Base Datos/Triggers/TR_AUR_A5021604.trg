CREATE OR REPLACE trigger TR_AUR_A5021604
  /*Modifico : Richard Ibarra Negrette
    fecha :  03 de Marzo de 2015
    Desc : Se cambia la lógica del trigger para guardar un valor en la variable v_TICKET_ENVIO la cual
            se almacena en la tabla SIM_SINIESTROS_SMS y nos ayudará a saber que codigo de evento se le
            asigna en el envío de mensajes */
  after update on A5021604
  for each row

when ((new.MCA_EST_PAGO = 'P' OR new.MCA_EST_PAGO IS NULL) AND new.TDOC_TERCERO <> 'NT')
declare
  V_estado          BOOLEAN := TRUE;
  V_num_secu_sini   A7000900.Num_Secu_Sini%TYPE := 0;
  V_num_sini        a3001700.num_sini%TYPE;
  V_cod_secc        a3001700.cod_secc%TYPE;
  v_cod_prod        A7000900.COD_PROD%TYPE DEFAULT NULL;
  v_cod_cia         A7000900.COD_CIA%TYPE DEFAULT NULL;
  v_cod_ramo        A7000900.COD_RAMO%TYPE DEFAULT NULL;
  v_TICKET_ENVIO      SIM_SINIESTROS_SMS.TICKET_ENVIO%TYPE DEFAULT NULL;
  v_NUMDOC          JURIDICOS.NUMERO_DOCUMENTO%TYPE DEFAULT NULL;
  v_TIPDOC          JURIDICOS.TIPDOC_CODIGO%TYPE DEFAULT NULL;
  v_NOMBRES         VARCHAR2(100) DEFAULT NULL;
  v_APELLIDOS       VARCHAR2(100) DEFAULT NULL;


  V_dir_vendedor   VARCHAR2(20);
  V_dir_compania   VARCHAR2(20);
  V_tip_nomina     VARCHAR2(20);
  V_tip_vinculacion VARCHAR2(20);
  V_cla_vinculacion    VARCHAR2(20);
  V_tip_persona    VARCHAR2(20);
  V_num_documento  VARCHAR2(20);
  REC_SIM_SINIESTROS_SMS SIM_SINIESTROS_SMS%ROWTYPE;

BEGIN
 -- IF :NEW.COD_CIA = 3 THEN
  --p_graba_rin('ENTRO AL TRIGGER',SYSDATE);
  IF (:OLD.MCA_EST_PAGO = 'B' AND :NEW.MCA_EST_PAGO IS NULL) OR
     (:OLD.MCA_EST_PAGO = 'B' AND :NEW.MCA_EST_PAGO = 'P') THEN
    --  NVL(:NEW.MCA_EST_PAGO,'X') != NVL(:OLD.MCA_EST_PAGO,'X') AND :NEW.COD_CIA = 2 THEN
    BEGIN
      --p_graba_rin('ENTRO AL IF NVL:NEW.MCA_EST_PAGO,',SYSDATE);
      --EL PRIMER SELECT ES PARA AUTORIZACION VIDA
      SELECT d.num_sini, d.cod_secc, d.cod_cia
        INTO V_num_sini, v_cod_secc, v_cod_cia
        FROM a3001700 d
       WHERE d.num_ord_pago = :NEW.NUM_ORD_PAGO
         AND d.cod_cia = :NEW.COD_CIA
         AND d.cod_cia = 2
         AND d.cod_secc NOT IN (34, 26, 70, 68, 22);
     /* UNION --EL SEGUNDO SELECT ES PARA AUTORIZACION AUTOS
      SELECT X.num_sini, X.cod_secc, X.Cod_Cia
           FROM a3001700 X
       WHERE X.num_ord_pago = :NEW.NUM_ORD_PAGO
         AND X.cod_cia = 3
         AND X.cod_secc = 1;*/
       /*UNION --EL TERCER SELECT ES PARA AUTORIZACION SOAT
        SELECT X.num_sini, X.cod_secc, X.Cod_Cia
        FROM a3001700 X
       WHERE X.num_ord_pago = :NEW.NUM_ORD_PAGO
         AND X.cod_cia = 3
         AND X.cod_secc = 310;   */

    EXCEPTION
      WHEN OTHERS THEN
        V_estado := FALSE;
        DBMS_OUTPUT.put_line('Código del error : ' || SQLCODE ||
                             ' Mensaje de error : ' || SQLERRM);
        -- p_graba_rin('1.Código del error : ' || SQLCODE ||
      --                    ' Mensaje de error : ' || SQLERRM,SYSDATE);
    END;
    IF V_estado THEN
      BEGIN
        --p_graba_rin('ENTRO AL IF V_estado',SYSDATE);
        SELECT d.Num_Secu_Sini, D.COD_PROD, D.COD_RAMO
          INTO V_num_secu_sini, v_cod_prod, v_cod_ramo
          FROM A7000900 d
         WHERE d.num_sini = V_num_sini
           AND d.cod_secc = V_cod_secc
           AND D.COD_CIA = v_cod_cia
           AND d.nro_orden_sini =
               (SELECT MAX(X.NRO_ORDEN_SINI)
                  FROM A7000900 X
                 WHERE X.COD_SECC = D.COD_SECC
                   AND X.NUM_SINI = D.NUM_SINI); -- = 0;
      EXCEPTION
        WHEN OTHERS THEN
          V_num_secu_sini := NULL;
          v_cod_prod := NULL;
          v_cod_ramo := NULL;

      END;
      ---PAGO AUTOS / PAGOS SOAT
/*      IF (v_cod_cia = 3 AND v_cod_ramo = 250 AND v_cod_secc = 1 )\* OR
        (v_cod_cia = 3 AND v_cod_ramo = 315 AND v_cod_secc = 310)*\ THEN
        IF :NEW.FOR_PAGO = 1 THEN
             v_TICKET_ENVIO := 'CL_PA_TRANF';
         ELSE
             v_TICKET_ENVIO := 'CL_PA_CHEQUE';
        END IF;*/
    ---APROBACION MICROSEGUROS
       /*ELS*/
       IF v_cod_cia = 2 and v_cod_secc = 29 and v_cod_ramo = 761 Then
        v_TICKET_ENVIO:='CL_AP_MC';
    ---PAGO VIDA
       ELSIF v_cod_cia = 2 AND v_cod_secc NOT IN (34, 26, 70, 68, 22)  THEN
       v_TICKET_ENVIO := 'CL_PAG_VIDA';
       END IF;
      IF v_TICKET_ENVIO IS NOT NULL THEN
            BEGIN
              REC_SIM_SINIESTROS_SMS := NULL;
          --SE CAPTURAN LOS VALORE PARA REC_SIM_SINIESTROS_SMS BENEFICIARIO
          REC_SIM_SINIESTROS_SMS.SECUN_SMS            := SEQ_SINIESTROS_SMS.Nextval;
          REC_SIM_SINIESTROS_SMS.COD_MENSAJE          := 2;
          REC_SIM_SINIESTROS_SMS.NUM_SECU_SINI        := V_num_secu_sini;
          REC_SIM_SINIESTROS_SMS.TDOC_BENEFICIARIO    := :new.TDOC_TERCERO;
          REC_SIM_SINIESTROS_SMS.NUM_IDEN_BENEF       := :new.COD_BENEF;
          REC_SIM_SINIESTROS_SMS.NOMBRE_BENEFICIARIO  := SUBSTR(:new.NOMBENEF, 1, 100);
          REC_SIM_SINIESTROS_SMS.NUM_CELULAR          := NULL;
          REC_SIM_SINIESTROS_SMS.TICKET_ENVIO         := v_TICKET_ENVIO;
          REC_SIM_SINIESTROS_SMS.FECHA_CREACION       := SYSDATE;
          REC_SIM_SINIESTROS_SMS.FECHA_ENVIO          :=  :new.FECHA_PAGO;
          REC_SIM_SINIESTROS_SMS.ESTADO_ENVIO         := NULL;
          REC_SIM_SINIESTROS_SMS.CAUSAL_RECHAZO       := NULL;
          REC_SIM_SINIESTROS_SMS.USUARIO_CREACION     := USER;
          REC_SIM_SINIESTROS_SMS.USUARIO_MODIFICACION := NULL;
          REC_SIM_SINIESTROS_SMS.NUM_ORD_PAGO         := :NEW.NUM_ORD_PAGO;
          ---SE LLAMA A LA FUNCION PARA QUE INSERTE
          SIM_PCK_MENSAJERIA.PRC_INSERT_SIM_SINIESTROS_SMS(REC_SIM_SINIESTROS_SMS);
        EXCEPTION
          WHEN OTHERS THEN
            NULL;
        END;
      END IF;
       ---------------------------VALIDACION DE INFORMACIÓN DEL AGENTE----MANTIS 34529

   /*   IF v_cod_prod IS NOT NULL AND v_cod_ramo != 761 THEN
       Lfv_pk_int_mpc.Prc_retorna_jefe(v_cod_prod,
                                   V_dir_vendedor,
                                   V_cod_cia,
                                   V_dir_compania,
                                   V_tip_nomina,
                                   V_tip_vinculacion,
                                   V_cla_vinculacion,
                                   V_tip_persona,
                                   V_num_documento);

      IF NVL(V_cod_cia,'0') IN ('2','3') AND NVL(V_tip_nomina,'0') = '4'
        AND NVL(V_tip_vinculacion,'0') IN ('6','7','8') AND NVL(V_cla_vinculacion,'0') IN ('1','2') THEN
          --RIN
    --      IF NVL(:NEW.COD_ESTADO, 'XX') != NVL(:OLD.COD_ESTADO, 'XX') THEN
            REC_SIM_SINIESTROS_SMS := NULL;
            v_TICKET_ENVIO := 'AG_PA';
            BEGIN
          REC_SIM_SINIESTROS_SMS.SECUN_SMS            := SEQ_SINIESTROS_SMS.Nextval;
          REC_SIM_SINIESTROS_SMS.COD_MENSAJE          := 2;
          REC_SIM_SINIESTROS_SMS.NUM_SECU_SINI        := V_num_secu_sini;
          REC_SIM_SINIESTROS_SMS.TDOC_BENEFICIARIO    := v_TIPDOC;
          REC_SIM_SINIESTROS_SMS.NUM_IDEN_BENEF       := v_NUMDOC;
          REC_SIM_SINIESTROS_SMS.NOMBRE_BENEFICIARIO  := v_NOMBRES || ' ' || V_APELLIDOS;
          REC_SIM_SINIESTROS_SMS.NUM_CELULAR          := NULL;
          REC_SIM_SINIESTROS_SMS.TICKET_ENVIO         := v_TICKET_ENVIO;
          REC_SIM_SINIESTROS_SMS.FECHA_CREACION       := SYSDATE;
          REC_SIM_SINIESTROS_SMS.FECHA_ENVIO          :=  SYSDATE;
          REC_SIM_SINIESTROS_SMS.ESTADO_ENVIO         := NULL;
          REC_SIM_SINIESTROS_SMS.CAUSAL_RECHAZO       := NULL;
          REC_SIM_SINIESTROS_SMS.USUARIO_CREACION     := USER;
          REC_SIM_SINIESTROS_SMS.USUARIO_MODIFICACION := NULL;
          REC_SIM_SINIESTROS_SMS.NUM_ORD_PAGO         := :NEW.NUM_ORD_PAGO;
          ---SE LLAMA A LA FUNCION PARA QUE INSERTE
          SIM_PCK_MENSAJERIA.PRC_INSERT_SIM_SINIESTROS_SMS(REC_SIM_SINIESTROS_SMS);
            EXCEPTION
              WHEN OTHERS THEN
            --    p_graba_rin('ENTRO A LA EXCEPTION DEL IF',SYSDATE);
                DBMS_OUTPUT.put_line('ERROR EN LA INSERCION DE LA TABLA SIM_SINIESTROS_SMS: Código del error : ' ||
                                     SQLCODE || ' Mensaje de error : ' ||
                                     SQLERRM);
            END;

         END IF;
      END IF;
*/
   -------------------FIN MANTIS 34529-------------------------------------------
    END IF;

  END IF;
--   END IF;
END TR_AUR_A5021604;
/
