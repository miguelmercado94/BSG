CREATE OR REPLACE TRIGGER Trg_anexo_multicia
   BEFORE INSERT OR UPDATE OF Mca_term_ok
   ON A2000030 
   REFERENCING NEW AS New OLD AS Old
   FOR EACH ROW
DECLARE
   V_esanexa        VARCHAR2(1);
   V_multicia       VARCHAR2(1);
   V_contestadop    NUMBER := 0;
   V_cambiaestado   VARCHAR2(1);
   V_fechaequipo    DATE := TRUNC( SYSDATE);

   CURSOR Facturas  IS
      SELECT X.Num_factura Nfact
        FROM A2000163 X
       WHERE X.Num_secu_pol = :new.Num_secu_pol
         AND X.Cod_agrup_cont = 'GENERICOS'
         AND X.Tipo_reg = 'T'
         AND X.Mca_estado = 'P';
BEGIN
   /*----------------------------------------------------------------------------*
    * <Date>18/09/2014</Date>
    * <Author>Intasi28</Author>
    * <Control>Mantis 29515</Control>
    * <Summary>
    *   Trigger que valida los endosos de anulacion de polizas anexas de
    *   multicompañia.
    *   Caso 1:
    *   Actualiza los registros de la póliza en la tabla A2000163
    *   que tienen MCA_ESTADO = P a E. Si realiza esto actualiza fecha_emi y
    *   fecha_equipo a la fecha del dia en la tabla A2000163 y A2990700 para estos
    *   registros
    * </Summary>
    *----------------------------------------------------------------------------*/
   IF INSERTING THEN
      -- CASO 1
      IF :new.Tipo_end = 'AT' THEN
         -- verifica si es negocio multicia
         V_multicia   := Pkg299_multicompania.Negocio_multicompania( :new.Num_secu_pol);
         -- verifica si es poliza anexa
         V_esanexa    := Pkg299_multicompania.Verifica_poliza_anexa( :new.Num_secu_pol);

         IF V_multicia = 'S' AND V_esanexa = 'S' THEN
            -- verifica si la poliza tiene facturas con mca_estado = P
            BEGIN
               SELECT COUNT( 1)
                 INTO V_contestadop
                 FROM A2000163 A
                WHERE A.Num_secu_pol = :new.Num_secu_pol
                  AND A.Cod_agrup_cont = 'GENERICOS'
                  AND A.Tipo_reg = 'T'
                  AND A.Mca_estado = 'P';

               IF V_contestadop > 0 THEN
                  /* Marca estado y marca Contabiliza */
                  V_cambiaestado      :=
                     Fun_cambiaestado_factura(:new.Cod_cia,
                                              :new.Cod_secc,
                                              :new.Cod_ramo,
                                              :new.Num_secu_pol,
                                              :new.num_end);

                  IF V_cambiaestado = 'S' THEN
                     FOR I IN Facturas LOOP
                        UPDATE A2000163 F
                           SET F.Mca_estado     = 'E',
                               F.Fecha_emi      = V_fechaequipo,
                               F.Fecha_equipo   = V_fechaequipo
                         WHERE F.Num_secu_pol = :new.Num_secu_pol
                           AND F.Num_factura = I.Nfact
                           AND F.Mca_estado = 'P';

                        UPDATE A2990700 G
                           SET G.Fecha_emi_end = V_fechaequipo, G.Fecha_equipo = V_fechaequipo
                         WHERE G.Num_secu_pol = :new.Num_secu_pol
                           AND G.Num_factura = I.Nfact;
                     END LOOP;
                  END IF;
               END IF;
            EXCEPTION
               WHEN NO_DATA_FOUND THEN
                  NULL;
            END;
         END IF;
      END IF;
   END IF;
EXCEPTION
   WHEN OTHERS THEN
      NULL;
END;
/
