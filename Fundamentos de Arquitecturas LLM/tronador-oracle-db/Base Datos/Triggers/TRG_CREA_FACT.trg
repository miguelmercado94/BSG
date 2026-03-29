CREATE OR REPLACE TRIGGER TRG_CREA_FACT
BEFORE DELETE OR INSERT OR UPDATE 
ON A2990700 
REFERENCING NEW AS NEW OLD AS OLD
FOR EACH ROW
DECLARE
      --V_anexa          VARCHAR2(1);
      V_multicia       VARCHAR2(1);
      V_sectercero     NUMBER(13) := NULL;
      V_tipo           VARCHAR2(1) := NULL;
      V_desrol         VARCHAR2(60) := NULL;
      V_codactbenef    NUMBER(2) := NULL;
      V_mcaestado      VARCHAR2(1) := 'V';
      V_fechapago      DATE := NULL;
      V_fecasiento     DATE := NULL;
      V_porccomi       NUMBER(5, 2) := 100;
      V_eslider        VARCHAR2(1);
      V_nsplider       NUMBER;
      V_anexoexclu     VARCHAR2(1);
      --V_asignasecu     VARCHAR2(1) := 'S';
      V_nspaux         NUMBER; -- Almacena Nsp Anexo
      V_nendaux        NUMBER; -- Almacena Endoso Anexo
      --V_contabiliza    NUMBER;
      V_contestadop    NUMBER;
      V_nendlider      NUMBER;
      L_numend         NUMBER;
      L_numendref      NUMBER;
      L_mcaanulada     VARCHAR2(1);
      L_cambiaestado   VARCHAR2(1);
      L_fechaequipo    DATE;
      l_Tipoend        Varchar2(2);
    	V_CODERROR    SIM_LOG_ERRORES.CODIGO%TYPE := NULL;
    	V_MSGERROR    SIM_LOG_ERRORES.DESCRIPCION%TYPE := NULL;
BEGIN      
   Begin
      IF INSERTING THEN
         :New.Imp_imptos_iva   := :New.Imp_imptos_mon_local;
         UPDATE A2000163
         SET Fecha_creacion   = SYSDATE
         WHERE Num_secu_pol = :New.Num_secu_pol
         AND Num_factura = :New.Num_factura 
         AND Fecha_creacion IS NULL;    
 
        IF :New.Fecha_creacion IS NULL THEN
            :New.Fecha_creacion   := SYSDATE;
         END IF;

         V_multicia            := Pkg299_multicompania.Negocio_multicompania( :New.Num_secu_pol);
         SELECT Num_end,
                   Num_end_ref,
                   Fecha_equipo
          INTO L_numend,
               L_numendref,
               L_fechaequipo
          FROM A2000163
          WHERE Num_secu_pol = :New.Num_secu_pol
            AND Num_factura = :New.Num_factura
            AND Cod_agrup_cont = 'GENERICOS'
            AND Tipo_reg = 'T';

         IF V_multicia = 'S' THEN
            -- Verifico Si Es Poliza Lider
            V_eslider   := Pkg299_multicompania.Verifica_poliza_lider( :New.Num_secu_pol);


            IF V_eslider = 'N' THEN
               -- Si No Es La Poliza Lider Recupero El Numero Interno Poliza Lider

               V_nsplider      :=
                  Pkg299_multicompania.Retorna_num_secu_pol_lider( :New.Num_secu_pol);
               V_nspaux   := :New.Num_secu_pol;
            --    v_nendaux := l_NumEnd;
            ELSE
               -- Si Es La Poliza Lider Recupero El Numero Interno Poliza Anexo

               V_nsplider   := :New.Num_secu_pol;
               --  v_nendLider := l_NumEnd;
               V_nspaux      :=
                  Pkg299_multicompania.Retorna_num_secu_pol_anexo( :New.Num_secu_pol);
            END IF;

            -- Valido Si Se Exluyo Poliza Anexa
            V_anexoexclu      :=
               NVL(Pkg299_multicompania.Valida_exclusion_anexo( V_nsplider),
                   'N');

            IF V_anexoexclu <> 'S' THEN
               /* verifica endoso es multicia */
               IF L_numend IS NOT NULL THEN
                  /* factura de endoso */
                  BEGIN
                     IF V_eslider = 'S' THEN
                        V_nendlider   := L_numend;
                        Pkg299_multicompania.Recupera_anexo(V_nsplider,
                                                            V_nendlider,
                                                            V_nspaux,
                                                            V_nendaux);
                     ELSE
                        V_nendaux   := L_numend;
                        Pkg299_multicompania.Recupera_lider(V_nspaux,
                                                            V_nendaux,
                                                            V_nsplider,
                                                            V_nendlider);
                     END IF;
                     Begin
                     Select nvl(tipo_end,'XX')
                        Into l_Tipoend 
                      From a2000030
                      Where num_secu_pol = V_nspaux
                       And num_End = V_nendaux;
                      If L_tipoEnd = 'SM' Then
                         :New.Secuencia   := NULL;
                         :New.Lider       := NULL;
                         RETURN;
                      End If; 
                     Exception When Others Then Null;
                     End;

                     IF V_nendaux IS NULL
                     OR V_nendlider IS NULL THEN
                        :New.Secuencia   := NULL;
                        :New.Lider       := NULL;
                        RETURN;
                     END IF;
                  EXCEPTION
                     WHEN OTHERS THEN
                        :New.Secuencia   := NULL;
                        :New.Lider       := NULL;
                        RETURN;
                  END;
               ELSE
                  SELECT NVL(Mca_anu_pol, 'N')
                    INTO L_mcaanulada
                    FROM A2000030 A
                   WHERE Num_secu_pol = V_nspaux
                     AND Num_end =
                            (SELECT MAX( Num_end)
                               FROM A2000030
                              WHERE Num_secu_pol = A.Num_secu_pol
                                AND Num_end <= L_numendref);

                  IF L_mcaanulada = 'S' THEN
                     :New.Secuencia   := NULL;
                     :New.Lider       := NULL;
                     RETURN;
                  END IF;
               END IF;

               Pkg299_multicompania.Asigna_secuencia_a2000163( :New.Num_secu_pol, :New.Num_factura);

               Pkg299_multicompania.Asigna_secuencia_a2990700(
                  :New.Num_secu_pol,
                  :New.Num_factura,
                  :New.Secuencia,
                  :New.Lider);


               IF NVL( :New.Secuencia, 0) = 0 THEN
                  SELECT Cons_fac_multicia.NEXTVAL
                    INTO :New.Secuencia
                    FROM DUAL;

                  :New.Lider   := Pkg299_multicompania.Verifica_poliza_lider( :New.Num_secu_pol);
               END IF;

               DECLARE
                  Id_var   A2000163%ROWTYPE;
               BEGIN
                  Pkg299_datos_gen_mc.Recupera_a2000163(
                     P_numsecupol   => :New.Num_secu_pol,
                     P_numfactura   => :New.Num_factura,
                     Id_var         => Id_var);

                  IF NVL( :New.Sec_tercero, 0) != 0 THEN
                     BEGIN
                        Pck999_terceros.Prc_roltercero(V_sectercero,
                                                       V_tipo,
                                                       V_codactbenef,
                                                       V_desrol);
                     EXCEPTION
                        WHEN OTHERS THEN
                           V_codactbenef   := 1;
                     END;
                  ELSE
                     V_codactbenef   := 1;
                  END IF;

                  BEGIN
                     INSERT INTO A502_multi_cia(Secuencia,
                                                Lider,
                                                Cod_cia,
                                                Cod_secc,
                                                Cod_ramo,
                                                Num_pol1,
                                                Num_end,
                                                Num_factura,
                                                Num_cuota,
                                                Fecha_vig_fact,
                                                Fecha_vto_fact,
                                                Fecha_equipo,
                                                Cod_situacion,
                                                Cod_prod,
                                                Cod_benef,
                                                Cod_act_benef,
                                                Clave_gestor,
                                                Imp_prima,
                                                Imp_mon_local,
                                                Imp_imptos_local,
                                                Imp_der_emi,
                                                Imp_rec_adm,
                                                Cod_mon,
                                                Tc,
                                                Porc_comi,
                                                Fecha_pago,
                                                Fec_asiento,
                                                Mca_estado)
                          VALUES ( :New.Secuencia,
                                  :New.Lider,
                                  :New.Cod_cia,
                                  :New.Cod_secc,
                                  :New.Cod_ramo,
                                  :New.Num_pol1,
                                  :New.Num_end,
                                  :New.Num_factura,
                                  NVL( :New.Num_cuota, 1),
                                  Id_var.Fecha_vig_fact,
                                  Id_var.Fecha_vto_fact,
                                  Id_var.Fecha_equipo,
                                  :New.Cod_situacion,
                                  NVL( :New.Cod_prod, 99999),
                                  NVL( :New.Nro_documto, 9999999999),
                                  V_codactbenef,
                                  NVL( :New.Clave_gestor, 99999),
                                  :New.Imp_prima,
                                  :New.Imp_moneda_local,
                                  :New.Imp_imptos_mon_local,
                                  :New.Imp_der_emi,
                                  :New.Imp_rec_adm,
                                  Id_var.Cod_mon,
                                  Id_var.Tc,
                                  V_porccomi,
                                  V_fechapago,
                                  V_fecasiento,
                                  V_mcaestado);
                  END;
               EXCEPTION
                  WHEN OTHERS THEN
                     Raise_application_error( -20000, SQLERRM);
               END;
            ELSE
               :New.Secuencia   := NULL;
               :New.Lider       := NULL;
            END IF;
         ELSE
            :New.Secuencia   := NULL;
            :New.Lider       := NULL;
         END IF;
      -- <Comment>
      ELSIF DELETING THEN
         DELETE A502_multi_cia
          WHERE Secuencia = :Old.Secuencia
            AND Num_pol1 = :Old.Num_pol1
            AND Cod_secc = :Old.Cod_secc
            AND Num_factura = :Old.Num_factura;
      ELSE
        SELECT Num_end,
                   Num_end_ref,
                   Fecha_equipo
          INTO L_numend,
               L_numendref,
               L_fechaequipo
          FROM A2000163
          WHERE Num_secu_pol = :New.Num_secu_pol
            AND Num_factura = :New.Num_factura
            AND Cod_agrup_cont = 'GENERICOS'
            AND Tipo_reg = 'T';
            
         :New.Imp_imptos_iva   := :New.Imp_imptos_mon_local;

         UPDATE A502_multi_cia
            SET Cod_prod        = NVL( :New.Cod_prod, 99999),
                Cod_benef       = NVL( :New.Nro_documto, 9999999999),
                Clave_gestor    = NVL( :New.Clave_gestor, 99999),
                Cod_mon         = :New.Cod_mon,
                Tc              = :New.Tc,
                Cod_situacion   = :New.Cod_situacion,
                Mca_estado      = DECODE( :New.Cod_situacion, 'CT', 'P', 'V')
          WHERE Secuencia = :Old.Secuencia
            AND Num_pol1 = :Old.Num_pol1
            AND Cod_secc = :Old.Cod_secc
            AND Num_factura = :Old.Num_factura;
      END IF;

      IF INSERTING  THEN
         /* Marca estado y marca Contabiliza */
         SELECT COUNT( 1)
          INTO V_contestadop
         FROM A2000163 A
         WHERE A.Num_secu_pol = :new.Num_secu_pol
           AND a.num_factura = :New.Num_Factura
           AND A.Cod_agrup_cont = 'GENERICOS'
           AND A.Tipo_reg = 'T'
           AND A.Mca_estado = 'P';
         IF V_contestadop > 0 THEN         
            l_cambiaestado      :=
            Fun_cambiaestado_factura(:New.Cod_cia, :New.Cod_secc,  :New.Cod_ramo,
                                     :New.Num_secu_pol, l_numendref);
      --  Se añade el cambio de fechas de equipos para numeros de endoso.
      --  Daniel Torres ASW 09092015 
         ELSIF :new.Cod_Secc = 310 THEN
            l_cambiaestado      := 'S';
            SELECT greatest(fecha_emi_end, trunc(sysdate))
               INTO l_fechaequipo
             FROM a2000030 a
            WHERE num_secu_pol = :NEW.num_secu_pol 
              AND Num_end = (SELECT MAX( Num_end)
                               FROM A2000030
                              WHERE Num_secu_pol = A.Num_secu_pol
                                AND Num_end <= l_numendref);
         ELSIF :new.num_end <>0 THEN
            l_cambiaestado      := 'S';
            SELECT greatest(fecha_equipo, trunc(sysdate))
               INTO l_fechaequipo
             FROM a2000030 a
            WHERE num_secu_pol = :NEW.num_secu_pol 
              AND Num_end = (SELECT MAX( Num_end)
                               FROM A2000030
                              WHERE Num_secu_pol = A.Num_secu_pol
                                AND Num_end <= l_numendref);
         END IF;
         IF L_cambiaestado = 'S' THEN
               UPDATE A2000163 F
                 SET F.Mca_estado     = 'E',
                     F.Fecha_emi      = l_fechaequipo,
                     F.Fecha_equipo   = l_fechaequipo
               WHERE F.Num_secu_pol = :New.Num_secu_pol
                 AND F.Num_factura = :New.Num_factura;

              IF SQL%FOUND THEN
                 :New.Fecha_emi_end   := l_fechaequipo;
                 :New.Fecha_equipo    := l_fechaequipo;
              END IF;
         END IF;
      ELSIF updating  THEN
            SELECT fecha_equipo
               INTO l_fechaequipo
             FROM a2000163 a
            WHERE num_secu_pol = :NEW.num_secu_pol 
              AND Num_factura = :new.Num_Factura
              AND cod_agrup_cont ='GENERICOS'
              AND tipo_reg ='T';
            UPDATE A2000163 F
                 SET  F.Fecha_emi      = l_fechaequipo
               WHERE F.Num_secu_pol = :New.Num_secu_pol
                 AND F.Num_factura = :New.Num_factura;
        :new.Fecha_Equipo := l_fechaequipo;
        :New.Fecha_emi_end := :new.fecha_equipo;
      END IF;
   END;
   EXCEPTION
     WHEN OTHERS THEN 
       BEGIN
          V_CODERROR := SQLCODE;
         V_MSGERROR := SQLERRM; 
         insert into fact_log_errores    ---hlc 26042017  siempre debe quedar mca_estado en 'E'
               (codigo, descripcion, programa, fecha, usuario, numsecupol, poliza)
        values
               (V_CODERROR, V_MSGERROR, 'TRG_CREA_FACT', sysdate, :new.cod_usr, :new.num_secu_pol, :new.num_pol1); 
        END;       
END TRG_CREA_FACT;
/
