CREATE OR REPLACE TRIGGER Trg_Ai_A5020301_Histco
  AFTER INSERT
  ON A5020301 
  REFERENCING NEW AS NEW OLD AS OLD
  FOR EACH ROW
DECLARE
  Vcod_Agente      C1000501.Cod_Agente%TYPE;
  Vnro_Documto     A2000030.Nro_Documto%TYPE;
  Vnum_Secu_Pol    A2000030.Num_Secu_Pol%TYPE;
  Vporc_Comi       A2000250.Porc_Comi%TYPE;
  Vfecha_Vig_Fact  A2000163.Fecha_Vig_Fact%TYPE;
  Vporce_Iva       C1000501.Porce_Iva%TYPE;
  Vcom_Dev_Normal  A5020302.Com_Dev_Normal%TYPE;
/*************************************************************************************************************
   NAME:       TRG_AI_A5020301_HISTCO
   PURPOSE:
    REVISIONS:
   VER        DATE        AUTHOR           DESCRIPTION
   ---------  ----------  ---------------  ------------------------------------------------------------------
   1.0        30/12/2011  INTASI32          1. CREATED THIS TRIGGER.
    NOTES: REPLICA A LA TABLA C5020301 LOS REGISTROS DE LA COMPAÑIA 2 Y 3
    AUTOMATICALLY AVAILABLE AUTO REPLACE KEYWORDS:
      OBJECT NAME:     TRG_AI_A5020301_HISTCO
      SYSDATE:         30/12/2011
      DATE AND TIME:   30/12/2011, 09:22:45 A.M., AND 30/12/2011 09:22:45 A.M.
      USERNAME:        79704401 (SET IN TOAD OPTIONS, PROC TEMPLATES)
      TABLE NAME:      A5020301 (SET IN THE "NEW PL/SQL OBJECT" DIALOG)
      TRIGGER OPTIONS:  (SET IN THE "NEW PL/SQL OBJECT" DIALOG)
   1.0.1      12/03/2012 INTASI32          1.SE AJUSTA VPORC_COMI Y VFECHA_VIG_FACT ROWNUM = 1
*************************************************************************************************************/
BEGIN
  IF :NEW.Cod_Cia IN (2, 3) THEN
    BEGIN
      /********************************************************************************************************************************************
      * DESCRIPTION: SE BUSCA EL CODIGO DEL AGENTE                                                      DATE:03/02/2011  REQUIREMENT:SRS000576    *
      ********************************************************************************************************************************************/
      SELECT /*+ INDEX(  A2990700 A OPS$PUMA.I_A2990700  ) */
            B.Cod_Agente, B.Porce_Iva
        INTO Vcod_Agente, Vporce_Iva
        FROM A2990700 A
            ,C1000501 B
       WHERE A.Num_Pol1 = :NEW.Num_Pol1
         AND A.Cod_Secc = :NEW.Cod_Secc
         AND A.Num_Factura = :NEW.Num_Factura
         AND A.Cod_Cia = :NEW.Cod_Cia
         AND A.Cod_Ramo = :NEW.Cod_Ramo
         AND A.Cod_Prod = B.Cod_Agente;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        Vcod_Agente := NULL;
      WHEN OTHERS THEN
        Vcod_Agente := NULL;
    END;

    IF Vcod_Agente IS NOT NULL THEN
      BEGIN
        SELECT /*+ ALL_ROWS */
              A.Nro_Documto, A.Num_Secu_Pol
          INTO Vnro_Documto, Vnum_Secu_Pol
          FROM A2000030 A
         WHERE A.Num_Pol1 = :NEW.Num_Pol1
           AND A.Cod_Secc = :NEW.Cod_Secc
           AND A.Cod_Cia = :NEW.Cod_Cia
           AND A.Cod_Ramo = :NEW.Cod_Ramo
           AND A.Num_End = (SELECT MAX( C.Num_End )
                              FROM A2000030 C
                             WHERE C.Num_Secu_Pol = A.Num_Secu_Pol
                               AND C.Num_End = :NEW.Num_End);
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          BEGIN
            SELECT /*+ ALL_ROWS */
                  A.Nro_Documto, A.Num_Secu_Pol
              INTO Vnro_Documto, Vnum_Secu_Pol
              FROM A2010030 A
             WHERE A.Num_Pol1 = :NEW.Num_Pol1
               AND A.Cod_Secc = :NEW.Cod_Secc
               AND A.Cod_Cia = :NEW.Cod_Cia
               AND A.Num_End = :NEW.Num_End
               AND A.Cod_Ramo = :NEW.Cod_Ramo;
          EXCEPTION
            WHEN NO_DATA_FOUND THEN
              Vnro_Documto  := NULL;
              Vnum_Secu_Pol := NULL;
            WHEN OTHERS THEN
              Vnro_Documto  := NULL;
              Vnum_Secu_Pol := NULL;
          END;
        WHEN OTHERS THEN
          Vnro_Documto  := NULL;
          Vnum_Secu_Pol := NULL;
      END;

      BEGIN
        SELECT /*+ ALL_ROWS */
              A.Porc_Comi
          INTO Vporc_Comi
          FROM A2000250 A
         WHERE A.Num_Secu_Pol = Vnum_Secu_Pol
           AND A.Cod_Agente = Vcod_Agente
           AND A.Num_End <= (SELECT MAX( C.Num_End )
                               FROM A2000250 C
                              WHERE C.Num_Secu_Pol = A.Num_Secu_Pol
                                AND C.Cod_Agente = A.Cod_Agente
                                AND C.Num_End <= :NEW.Num_End)
           AND ROWNUM = 1;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          Vporc_Comi := 0;
        WHEN OTHERS THEN
          Vporc_Comi := 0;
      END;

      BEGIN
        SELECT /*+ ALL_ROWS */
              A.Fecha_Vig_Fact
          INTO Vfecha_Vig_Fact
          FROM A2000163 A
         WHERE A.Num_Secu_Pol = Vnum_Secu_Pol
           AND A.Num_Factura = :NEW.Num_Factura
           AND A.Fecha_Vig_Fact IS NOT NULL
           AND A.Cod_Agrup_Cont = 'GENERICOS'
           AND ROWNUM = 1;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          Vfecha_Vig_Fact := NULL;
        WHEN OTHERS THEN
          Vfecha_Vig_Fact := NULL;
      END;

      BEGIN
        SELECT /*+ ALL_ROWS */
              A.Com_Dev_Normal
          INTO Vcom_Dev_Normal
          FROM A5020302 A
         WHERE A.Cod_Cia = :NEW.Cod_Cia
           AND A.Cod_Secc = :NEW.Cod_Secc
           AND A.Num_Pol1 = :NEW.Num_Pol1
           AND A.Num_Factura = :NEW.Num_Factura
           AND A.Num_Mvto = :NEW.Num_Mvto
           AND A.Cod_Agente = Vcod_Agente;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          Vcom_Dev_Normal := 0;
        WHEN OTHERS THEN
          Vcom_Dev_Normal := 0;
      END;

      BEGIN
        INSERT INTO C5020301(Cod_Cia, Cod_Secc, Num_Pol1, Num_End, Num_Cuota
                     ,Num_Mvto, Num_Recibo, Cod_Cobro, Clave_Gestor, Fec_Actu
                     ,Tipo_Actu, Fec_Valor, Imp_Interes, Imp_Recargo_Local, Imp_Moneda_Local
                     ,Imp_Gastos, Imp_Comision_Local, Cod_Mon, Tc, Imp_Imptos_Mon_Local
                     ,Cod_Mon_Imptos, Cod_Causa_Anu, Nro_Per, Cod_Ramo, Mca_Transmit
                     ,Nodo_Id, Fecha_Equipo, Imp_Prima, Mca_Anul, Cod_User
                     ,Numero_Liq, Recibo, Num_Ord_Pago, Imp_Der_Emi, Mca_Tipo_Cob
                     ,Imp_Rec_Adm, Num_Factura, Mca_Comision, Fecha_Comision, Planilla
                     ,Cod_Agente, Nro_Documto, Porc_Comi, Num_Secu_Pol, Fecha_Vig_Fact
                     ,Porce_Iva, Com_Dev_Normal )
             VALUES ( :NEW.Cod_Cia, :NEW.Cod_Secc, :NEW.Num_Pol1, :NEW.Num_End, :NEW.Num_Cuota
                     ,:NEW.Num_Mvto, :NEW.Num_Recibo, :NEW.Cod_Cobro, :NEW.Clave_Gestor, :NEW.Fec_Actu
                     ,:NEW.Tipo_Actu, :NEW.Fec_Valor, :NEW.Imp_Interes, :NEW.Imp_Recargo_Local, :NEW.Imp_Moneda_Local
                     ,:NEW.Imp_Gastos, :NEW.Imp_Comision_Local, :NEW.Cod_Mon, :NEW.Tc, :NEW.Imp_Imptos_Mon_Local
                     ,:NEW.Cod_Mon_Imptos, :NEW.Cod_Causa_Anu, :NEW.Nro_Per, :NEW.Cod_Ramo, :NEW.Mca_Transmit
                     ,:NEW.Nodo_Id, :NEW.Fecha_Equipo, :NEW.Imp_Prima, :NEW.Mca_Anul, :NEW.Cod_User
                     ,:NEW.Numero_Liq, :NEW.Recibo, :NEW.Num_Ord_Pago, :NEW.Imp_Der_Emi, :NEW.Mca_Tipo_Cob
                     ,:NEW.Imp_Rec_Adm, :NEW.Num_Factura, :NEW.Mca_Comision, :NEW.Fecha_Comision, :NEW.Planilla
                     ,Vcod_Agente, Vnro_Documto, Vporc_Comi, Vnum_Secu_Pol, Vfecha_Vig_Fact
                     ,Vporce_Iva, Vcom_Dev_Normal );
      EXCEPTION
        WHEN OTHERS THEN
          NULL;
      END;
    END IF;
  END IF;
END Trg_Ai_A5020301_Histco;
/
