CREATE OR REPLACE TRIGGER TR_AI_R_SIM_HIST_ESTADOS_SINI
/*Modifico : Richard Ibarra Negrette
    fecha :  23 de Noviembre de 2015
    Desc : Se modifica la busqueda del director comercial y el director de ventas para cuando llame al 
    procedimiento que busca los datos del agente trabaje con los datos que arroja de director de ventas
    y los datos de director comercial
            */
  /*Modifico : Richard Ibarra Negrette
    fecha :  15 de Septiembre de 2015
    Desc : Se agrega el codigo 12 de Tipo de Vinculacion a la condicion de IF para que los agentes
           independiente tambien salgan en la consulta
         " IF to_number(NVL(V_tip_nomina, '0')) = 4 AND
           to_number(NVL(V_tip_vinculacion, '0')) IN (6, 7, 8, 12) AND
            to_number(NVL(V_cla_vinculacion, '0')) IN (1, 2) THEN"
          Si cumple todo se guarda la informacion del Agente MANTIS 39010
            */
           
  /*Modifico : Richard Ibarra Negrette
    fecha :  03 de Marzo de 2015
    Desc : Se cambia la logica del trigger para guardar un valor en la variable v_TICKET_ENVIO la cual
            se almacena en la tabla SIM_SINIESTROS_SMS y nos ayudara a saber que codigo de evento se le
            asigna en el envio de mensajes */

  /*
     Modifico: Rolphy Quintero - Asesoftware
     Fecha   : 17 Octubre de 2014
     Desc    : Se agrega el codigo de estado PF y AV al trigger y se separa el codigo que corresponde
               para OB a PF y AV mediante un IF. Cuando el nuevo estado es PF y el producto hace
               referencia a compa?ia 2, seccion 29 y producto 761, es decir Microseguros, se envia
               un mensaje SMS, ya sea al beneficiario o al asegurado, segun sea el caso, en donde
               se le informa la existencia de documentacion incompleta a un numero de Daviplata.
*/
  after INSERT on SIM_HIST_ESTADOS_SINI
  for each row
when (new.COD_ESTADO IN ('OB','PF') )
declare
  CURSOR cur_datos_benef IS
    SELECT DISTINCT B.num_secu_sini, --a7000900.NUM_SECU_SINI
                    B.TIPO_ID_BENEFICIARIO,
                    B.ID_BENEFICIARIO,
                    SUBSTR(NVL(B.nombre_beneficiario, B.NOMBRE_APODERADO),
                           1,
                           100) NOMBRE_BENEFICIARIO
      FROM C7990400 B
     WHERE B.NUM_SECU_SINI = :new.num_secu_sini
       AND B.TIPO_ID_BENEFICIARIO IS NOT NULL
       AND (B.ID_BENEFICIARIO IS NOT NULL
       AND B.TIPO_ID_BENEFICIARIO<> 'NT')
    UNION
    SELECT A.NUM_SECU_SINI,
           A.TDOC_TERCERO_ASEG,
           A.COD_ASEG,
           A.NOM_ASEG || ' ' || A.APE_ASEG
      FROM A7000900 A
     WHERE A.NUM_SECU_SINI = :new.num_secu_sini
       AND A.COD_ASEG IS NOT NULL
       AND (A.TDOC_TERCERO_ASEG IS NOT NULL
       AND A.TDOC_TERCERO_ASEG <> 'NT');
  -- v_user SIM_HIST_ESTADOS_SINI.USUARIO_CREACION%TYPE :=NULL;
  v_cod_prod             A7000900.Cod_Prod%TYPE DEFAULT NULL;
  v_NOMBRES              VARCHAR2(100) DEFAULT NULL;
  v_cod_cia              A7000900.Cod_Cia%type;
  v_TICKET_ENVIO         sim_siniestros_sms.ticket_envio%TYPE DEFAULT NULL;
  vl_cod_cia             a7000900.cod_cia%type;
  vl_cod_secc            a7000900.cod_secc%type;
  vl_cod_ramo            a7000900.cod_ramo%type;
  V_dir_vendedor         VARCHAR2(20);
  V_dir_vendedor_2       VARCHAR2(20);
  V_dir_com              VARCHAR2(20);
  V_tip_nomina           VARCHAR2(20);
  V_tip_vinculacion      VARCHAR2(20);
  V_cla_vinculacion      VARCHAR2(20);
  V_tip_persona          VARCHAR2(20);
  V_num_documento        VARCHAR2(20);
  T_AGEN                 Pkg_Api1.t_agente;
  REC_SIM_SINIESTROS_SMS SIM_SINIESTROS_SMS%ROWTYPE;
BEGIN
  If :NEW.COD_ESTADO = 'OB' Then
    BEGIN
      SELECT D.COD_SECC, D.COD_PROD, D.COD_CIA, D.COD_RAMO
        INTO vl_cod_secc, v_cod_prod, vl_cod_cia, vl_cod_ramo
        FROM A7000900 D
       WHERE D.COD_SECC NOT IN (34, 26, 70, 68, 22)
         AND D.NUM_SECU_SINI = :NEW.NUM_SECU_SINI
         AND D.NRO_ORDEN_SINI = :NEW.NRO_ORDEN_SINI
         AND D.Cod_Cia = 2
      UNION
      SELECT D.COD_SECC, D.COD_PROD, D.COD_CIA, D.COD_RAMO
      --INTO v_secc, v_cod_prod
        FROM A7000900 D
       WHERE  D.COD_SECC != 33
         AND D.COD_CIA = 3
         AND D.NUM_SECU_SINI = :NEW.NUM_SECU_SINI
         AND D.NRO_ORDEN_SINI = :NEW.NRO_ORDEN_SINI;
    EXCEPTION
      WHEN OTHERS THEN
        vl_cod_secc := NULL;
    END;
  
      If vl_cod_cia = 2 and vl_cod_secc = 29 and vl_cod_ramo = 761 Then
        v_TICKET_ENVIO := 'CL_OB_MC'; --PARA MICROSEGUROS
      ELSIF vl_cod_cia = 3 THEN
        v_TICKET_ENVIO := 'CL_OB_AU'; -- PARA OBJECIONES DE VIDA AUTOS
      ELSIF vl_cod_cia = 2 and (vl_cod_secc != 29 or vl_cod_ramo != 761) then
        v_TICKET_ENVIO := 'CL_OB'; --PARA OBJECIONES DE VIDA
      END IF;
      REC_SIM_SINIESTROS_SMS := NULL;
      
      FOR C IN cur_datos_benef LOOP
        BEGIN
          --SE CAPTURAN LOS VALORE PARA REC_SIM_SINIESTROS_SMS BENEFICIARIO
          REC_SIM_SINIESTROS_SMS.SECUN_SMS            := SEQ_SINIESTROS_SMS.Nextval;
          REC_SIM_SINIESTROS_SMS.COD_MENSAJE          := 1;
          REC_SIM_SINIESTROS_SMS.NUM_SECU_SINI        := :NEW.NUM_SECU_SINI;
          REC_SIM_SINIESTROS_SMS.TDOC_BENEFICIARIO    := C.TIPO_ID_BENEFICIARIO;
          REC_SIM_SINIESTROS_SMS.NUM_IDEN_BENEF       := C.ID_BENEFICIARIO;
          REC_SIM_SINIESTROS_SMS.NOMBRE_BENEFICIARIO  := C.NOMBRE_BENEFICIARIO;
          REC_SIM_SINIESTROS_SMS.NUM_CELULAR          := NULL;
          REC_SIM_SINIESTROS_SMS.TICKET_ENVIO         := v_TICKET_ENVIO;
          REC_SIM_SINIESTROS_SMS.FECHA_CREACION       := SYSDATE;
          REC_SIM_SINIESTROS_SMS.FECHA_ENVIO          := SYSDATE;
          REC_SIM_SINIESTROS_SMS.ESTADO_ENVIO         := NULL;
          REC_SIM_SINIESTROS_SMS.CAUSAL_RECHAZO       := NULL;
          REC_SIM_SINIESTROS_SMS.USUARIO_CREACION     := :NEW.USUARIO_CREACION;
          REC_SIM_SINIESTROS_SMS.USUARIO_MODIFICACION := NULL;
          REC_SIM_SINIESTROS_SMS.NUM_ORD_PAGO         := NULL;
          ---SE LLAMA A LA FUNCION PARA QUE INSERTE               
          SIM_PCK_MENSAJERIA.PRC_INSERT_SIM_SINIESTROS_SMS(REC_SIM_SINIESTROS_SMS);
        EXCEPTION
          WHEN OTHERS THEN
            DBMS_OUTPUT.put_line('ERROR EN LA INSERCION DE LA TABLA SIM_SINIESTROS_SMS: Codigo del error : ' ||
                                 SQLCODE || ' Mensaje de error : ' ||
                                 SQLERRM);
            NULL;
        END;
    

  
    ---------------------------VALIDACION DE INFORMACION DEL AGENTE----MANTIS 34529
  
    IF v_cod_prod IS NOT NULL AND vl_cod_ramo != 761 THEN --Mensaje para el Agente
      REC_SIM_SINIESTROS_SMS := NULL;
      T_AGEN                 := NULL;
      T_AGEN.p_clave         := v_cod_prod;
      Pkg_Api1.PRC_DATOS_AGENTE(T_AGEN);
      Lfv_pk_int_mpc.Prc_retorna_jefe(v_cod_prod,
                                      V_dir_vendedor,
                                      V_cod_cia,
                                      V_dir_com,
                                      V_tip_nomina,
                                      V_tip_vinculacion,
                                      V_cla_vinculacion,
                                      V_tip_persona,
                                      V_num_documento);
    
      IF to_number(NVL(V_tip_nomina, '0')) = 4 AND
         to_number(NVL(V_tip_vinculacion, '0')) IN (6, 7, 8, 12) AND
         to_number(NVL(V_cla_vinculacion, '0')) IN (1, 2) THEN
        --RIN
          v_TICKET_ENVIO := 'AG_OB';
          v_NOMBRES := PCK999_TERCEROS.FUN_RETORNA_NOMBRES(P_NUMDOC    => V_num_documento,
                                                           P_TIPDOC    => V_tip_persona,
                                                           P_SECUENCIA => NULL);
        
          BEGIN 
            --SE CAPTURAN LOS VALORE PARA REC_SIM_SINIESTROS_SMS BENEFICIARIO
            REC_SIM_SINIESTROS_SMS.SECUN_SMS            := SEQ_SINIESTROS_SMS.Nextval;
            REC_SIM_SINIESTROS_SMS.COD_MENSAJE          := 1;
            REC_SIM_SINIESTROS_SMS.NUM_SECU_SINI        := :NEW.NUM_SECU_SINI;
            REC_SIM_SINIESTROS_SMS.TDOC_BENEFICIARIO    := V_tip_persona;
            REC_SIM_SINIESTROS_SMS.NUM_IDEN_BENEF       := V_num_documento;
            REC_SIM_SINIESTROS_SMS.NOMBRE_BENEFICIARIO  := v_NOMBRES;
            REC_SIM_SINIESTROS_SMS.NUM_CELULAR          := NULL;
            REC_SIM_SINIESTROS_SMS.TICKET_ENVIO         := v_TICKET_ENVIO;
            REC_SIM_SINIESTROS_SMS.FECHA_CREACION       := SYSDATE;
            REC_SIM_SINIESTROS_SMS.FECHA_ENVIO          := SYSDATE;
            REC_SIM_SINIESTROS_SMS.ESTADO_ENVIO         := NULL;
            REC_SIM_SINIESTROS_SMS.CAUSAL_RECHAZO       := NULL;
            REC_SIM_SINIESTROS_SMS.USUARIO_CREACION     := :NEW.USUARIO_CREACION;
            REC_SIM_SINIESTROS_SMS.USUARIO_MODIFICACION := NULL;
            REC_SIM_SINIESTROS_SMS.NUM_ORD_PAGO         := NULL;
            ---SE LLAMA A LA FUNCION PARA QUE INSERTE
            SIM_PCK_MENSAJERIA.PRC_INSERT_SIM_SINIESTROS_SMS(REC_SIM_SINIESTROS_SMS);
          
          EXCEPTION
            WHEN OTHERS THEN
              DBMS_OUTPUT.put_line('ERROR EN LA INSERCION DE LA TABLA SIM_SINIESTROS_SMS: Codigo del error : ' ||
                                   SQLCODE || ' Mensaje de error : ' ||
                                   SQLERRM);
              NULL;
          END;
    ---------------------------------------------------------------------------------------------------------
    ------------------------------Director de Comercial------------------------------------------------------
      IF NVL(TRIM(V_dir_com),0) != 0 THEN ---Mensaje para el Director Comercial
      REC_SIM_SINIESTROS_SMS := NULL;
      T_AGEN                 := NULL;
      T_AGEN.p_clave         := V_dir_com;
      Pkg_Api1.PRC_DATOS_AGENTE(T_AGEN);
    
      Lfv_pk_int_mpc.Prc_retorna_jefe(V_dir_com,
                                      V_dir_vendedor_2,
                                      V_cod_cia,
                                      V_dir_com,
                                      V_tip_nomina,
                                      V_tip_vinculacion,
                                      V_cla_vinculacion,
                                      V_tip_persona,
                                      V_num_documento);
      IF NVL(:NEW.COD_ESTADO, 'XX') != NVL(:OLD.COD_ESTADO, 'XX') THEN
          v_TICKET_ENVIO := 'AG_OB_COM';
          v_NOMBRES := PCK999_TERCEROS.FUN_RETORNA_NOMBRES(P_NUMDOC    => V_num_documento,
                                                           P_TIPDOC    => V_tip_persona,
                                                           P_SECUENCIA => NULL);
        
          BEGIN
            --SE CAPTURAN LOS VALORE PARA REC_SIM_SINIESTROS_SMS BENEFICIARIO
            REC_SIM_SINIESTROS_SMS.SECUN_SMS            := SEQ_SINIESTROS_SMS.Nextval;
            REC_SIM_SINIESTROS_SMS.COD_MENSAJE          := 1;
            REC_SIM_SINIESTROS_SMS.NUM_SECU_SINI        := :NEW.NUM_SECU_SINI;
            REC_SIM_SINIESTROS_SMS.TDOC_BENEFICIARIO    := V_tip_persona;
            REC_SIM_SINIESTROS_SMS.NUM_IDEN_BENEF       := V_num_documento;
            REC_SIM_SINIESTROS_SMS.NOMBRE_BENEFICIARIO  := v_NOMBRES;
            REC_SIM_SINIESTROS_SMS.NUM_CELULAR          := NULL;
            REC_SIM_SINIESTROS_SMS.TICKET_ENVIO         := v_TICKET_ENVIO;
            REC_SIM_SINIESTROS_SMS.FECHA_CREACION       := SYSDATE;
            REC_SIM_SINIESTROS_SMS.FECHA_ENVIO          := SYSDATE;
            REC_SIM_SINIESTROS_SMS.ESTADO_ENVIO         := NULL;
            REC_SIM_SINIESTROS_SMS.CAUSAL_RECHAZO       := NULL;
            REC_SIM_SINIESTROS_SMS.USUARIO_CREACION     := :NEW.USUARIO_CREACION;
            REC_SIM_SINIESTROS_SMS.USUARIO_MODIFICACION := NULL;
            REC_SIM_SINIESTROS_SMS.NUM_ORD_PAGO         := NULL;
            ---SE LLAMA A LA FUNCION PARA QUE INSERTE
            SIM_PCK_MENSAJERIA.PRC_INSERT_SIM_SINIESTROS_SMS(REC_SIM_SINIESTROS_SMS);
          
          EXCEPTION
            WHEN OTHERS THEN
              DBMS_OUTPUT.put_line('ERROR EN LA INSERCION DE LA TABLA SIM_SINIESTROS_SMS: Codigo del error : ' ||
                                   SQLCODE || ' Mensaje de error : ' ||
                                   SQLERRM);
              NULL;
          END;
        END IF;                                
      END IF;
      -----------------------------------------------------------------------------------------
      ------------------------------Director de Ventas-----------------------------------------
      IF NVL(TRIM(V_dir_vendedor),0) != 0 THEN ---Mensaje para el Director Comercial
      REC_SIM_SINIESTROS_SMS := NULL;
      T_AGEN                 := NULL;
      T_AGEN.p_clave         := V_dir_vendedor;
      Pkg_Api1.PRC_DATOS_AGENTE(T_AGEN);
    
      Lfv_pk_int_mpc.Prc_retorna_jefe(V_dir_vendedor,
                                      V_dir_vendedor_2,
                                      V_cod_cia,
                                      V_dir_com,
                                      V_tip_nomina,
                                      V_tip_vinculacion,
                                      V_cla_vinculacion,
                                      V_tip_persona,
                                      V_num_documento);
      IF NVL(:NEW.COD_ESTADO, 'XX') != NVL(:OLD.COD_ESTADO, 'XX') THEN
          v_TICKET_ENVIO := 'AG_OB_VEN';
          v_NOMBRES := PCK999_TERCEROS.FUN_RETORNA_NOMBRES(P_NUMDOC    => V_num_documento,
                                                           P_TIPDOC    => V_tip_persona,
                                                           P_SECUENCIA => NULL);
        
          BEGIN
            --SE CAPTURAN LOS VALORE PARA REC_SIM_SINIESTROS_SMS BENEFICIARIO
            REC_SIM_SINIESTROS_SMS.SECUN_SMS            := SEQ_SINIESTROS_SMS.Nextval;
            REC_SIM_SINIESTROS_SMS.COD_MENSAJE          := 1;
            REC_SIM_SINIESTROS_SMS.NUM_SECU_SINI        := :NEW.NUM_SECU_SINI;
            REC_SIM_SINIESTROS_SMS.TDOC_BENEFICIARIO    := V_tip_persona;
            REC_SIM_SINIESTROS_SMS.NUM_IDEN_BENEF       := V_num_documento;
            REC_SIM_SINIESTROS_SMS.NOMBRE_BENEFICIARIO  := v_NOMBRES;
            REC_SIM_SINIESTROS_SMS.NUM_CELULAR          := NULL;
            REC_SIM_SINIESTROS_SMS.TICKET_ENVIO         := v_TICKET_ENVIO;
            REC_SIM_SINIESTROS_SMS.FECHA_CREACION       := SYSDATE;
            REC_SIM_SINIESTROS_SMS.FECHA_ENVIO          := SYSDATE;
            REC_SIM_SINIESTROS_SMS.ESTADO_ENVIO         := NULL;
            REC_SIM_SINIESTROS_SMS.CAUSAL_RECHAZO       := NULL;
            REC_SIM_SINIESTROS_SMS.USUARIO_CREACION     := :NEW.USUARIO_CREACION;
            REC_SIM_SINIESTROS_SMS.USUARIO_MODIFICACION := NULL;
            REC_SIM_SINIESTROS_SMS.NUM_ORD_PAGO         := NULL;
            ---SE LLAMA A LA FUNCION PARA QUE INSERTE
            SIM_PCK_MENSAJERIA.PRC_INSERT_SIM_SINIESTROS_SMS(REC_SIM_SINIESTROS_SMS);
          
          EXCEPTION
            WHEN OTHERS THEN
              DBMS_OUTPUT.put_line('ERROR EN LA INSERCION DE LA TABLA SIM_SINIESTROS_SMS: Codigo del error : ' ||
                                   SQLCODE || ' Mensaje de error : ' ||
                                   SQLERRM);
              NULL;
          END;
        END IF;                                
      END IF;
      -----------------------------------------------------------------------------------------
     END IF;
    END IF;
    END LOOP;
    -------------------FIN MANTIS 34529-------------------------------------------
  
    --
  
    -- Microseguros - Rolphy Quintero - Asesoftware - INI
  Elsif :NEW.COD_ESTADO = 'PF' Then
    Declare
      vl_valor  A7000025.Valor_Campo%type;
      vl_tdoc   a7000900.tdoc_tercero_aseg%type;
      vl_nro    a7000900.cod_aseg%type;
      vl_nombre C7990400.NOMBRE_BENEFICIARIO%type;
    
    Begin
      -- Se busca la compa?ia, seccion y producto del siniestro
      Begin
        select p.cod_cia, p.cod_secc, p.cod_ramo
          into vl_cod_cia, vl_cod_secc, vl_cod_ramo
          from a7000900 p
         where p.num_secu_sini = :NEW.NUM_SECU_SINI
           and p.nro_orden_sini = :NEW.NRO_ORDEN_SINI;
      Exception
        When NO_DATA_FOUND Then
          vl_cod_cia  := null;
          vl_cod_secc := null;
          vl_cod_ramo := null;
      End;
      -- Pregunta si es el producto de Microseguros
      If vl_cod_cia = 2 and vl_cod_secc = 29 and vl_cod_ramo = 761 Then
        -- Se busca si el siniestro reportado hace referencia al asegurado
        Begin
          SELECT v.valor_campo
            into vl_valor
            FROM A7000025 v
           WHERE v.num_secu_sini = :NEW.NUM_SECU_SINI
             and v.nro_orden_sini = :NEW.NRO_ORDEN_SINI
             and v.cod_campo = 'ES_ASEGURADO';
        Exception
          When NO_DATA_FOUND Then
            vl_valor := null;
        End;
        Declare
          vl_cod_mensaje pls_integer;
        Begin
          If :NEW.COD_ESTADO = 'PF' Then
            vl_cod_mensaje := 3;
            v_TICKET_ENVIO := 'CL_PF_MC';
       /*   Elsif :NEW.COD_ESTADO = 'AV' Then
            vl_cod_mensaje := 2;
            v_TICKET_ENVIO:='CL_AV_MC';*/
          else
            v_TICKET_ENVIO := NULL;
          End If;
          If vl_valor = 'N' Then
            -- Muere el beneficiario
            -- Toma los nombres, tipo y numero de identificacion del asegurado
            select tdoc_tercero_aseg,
                   cod_aseg,
                   substr(nom_aseg || ' ' || ape_aseg, 1, 100)
              into vl_tdoc, vl_nro, vl_nombre
              from a7000900 a
             where a.NUM_SECU_SINI = :NEW.NUM_SECU_SINI
               and a.nro_orden_sini = :NEW.NRO_ORDEN_SINI;
          Elsif vl_valor = 'S' Then
            -- Muere el asegurado
            -- Toma los nombres, tipo y numero de identificacion del beneficiario
            -- El producto 761 - Microseguros, solo debe tener un beneficiario
            select c.tipo_id_beneficiario,
                   c.id_beneficiario,
                   c.nombre_beneficiario
              into vl_tdoc, vl_nro, vl_nombre
              from C7990400 c
             where NUM_SECU_SINI = :NEW.NUM_SECU_SINI
               and rownum <= 1;
          End If;
          -- Se ingresa el mensaje de texto para su posterior envio
          If vl_valor IN ('S', 'N') Then
            /* COD_MENSAJE = 3, No ha sido posible definir su reclamo del seguro por documentacion incompleta.
               Consulte los documentos requeridos en www.daviplata.com o comuniquese al #322
               COD_MENSAJE = 2, De acuerdo con la forma de indemnizacion convenida, en los proximos dias recibira el
               pago del seguro en seis cuotas cada 2 meses. Informese en www.daviplata.com
               COD_MENSAJE = 1, Su reclamacion ha sido negada por falta de cobertura segun las condiciones del contrato
               de seguro, por lo tanto no hay lugar al pago. Mayor informacion #322
            */
            --SE CAPTURAN LOS VALORE PARA REC_SIM_SINIESTROS_SMS BENEFICIARIO
            BEGIN
              REC_SIM_SINIESTROS_SMS.SECUN_SMS            := SEQ_SINIESTROS_SMS.Nextval;
              REC_SIM_SINIESTROS_SMS.COD_MENSAJE          := vl_cod_mensaje;
              REC_SIM_SINIESTROS_SMS.NUM_SECU_SINI        := :NEW.NUM_SECU_SINI;
              REC_SIM_SINIESTROS_SMS.TDOC_BENEFICIARIO    := vl_tdoc;
              REC_SIM_SINIESTROS_SMS.NUM_IDEN_BENEF       := vl_nro;
              REC_SIM_SINIESTROS_SMS.NOMBRE_BENEFICIARIO  := vl_nombre;
              REC_SIM_SINIESTROS_SMS.NUM_CELULAR          := NULL;
              REC_SIM_SINIESTROS_SMS.TICKET_ENVIO         := v_TICKET_ENVIO;
              REC_SIM_SINIESTROS_SMS.FECHA_CREACION       := SYSDATE;
              REC_SIM_SINIESTROS_SMS.FECHA_ENVIO          := SYSDATE;
              REC_SIM_SINIESTROS_SMS.ESTADO_ENVIO         := NULL;
              REC_SIM_SINIESTROS_SMS.CAUSAL_RECHAZO       := NULL;
              REC_SIM_SINIESTROS_SMS.USUARIO_CREACION     := :NEW.USUARIO_CREACION;
              REC_SIM_SINIESTROS_SMS.USUARIO_MODIFICACION := NULL;
              REC_SIM_SINIESTROS_SMS.NUM_ORD_PAGO         := NULL;
              ---SE LLAMA A LA FUNCION PARA QUE INSERTE
              SIM_PCK_MENSAJERIA.PRC_INSERT_SIM_SINIESTROS_SMS(REC_SIM_SINIESTROS_SMS);
            EXCEPTION
              WHEN OTHERS THEN
                DBMS_OUTPUT.put_line('ERROR EN LA INSERCION DE LA TABLA SIM_SINIESTROS_SMS: Codigo del error : ' ||
                                     SQLCODE || ' Mensaje de error : ' ||
                                     SQLERRM);
                NULL;
            END;
          End If;
        Exception
          When others Then
            NULL;
        End;
      End If;
    End;
  End If;
  -- Microseguros - Rolphy Quintero - Asesoftware - FIN
END TR_AI_R_SIM_HIST_ESTADOS_SINI;
/
