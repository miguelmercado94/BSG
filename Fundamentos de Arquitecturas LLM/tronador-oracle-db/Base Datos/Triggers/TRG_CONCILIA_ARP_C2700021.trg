CREATE OR REPLACE TRIGGER Trg_Concilia_Arp_C2700021 --ORIGINAL
  /************************************************************************************************************************************
  *  OBJETIVO   : INSERTAR O ACTUALIZAR EN LA TABLA DE CONCILIACIONES LOS DATOS QUE VENGAN DE LA TABLA DEL IBC.                       *
  *  AUTOR      : JULIANA STELLA LOPEZ                                                                                                *
  *  FECHA      : AGOSTO DEL 2008                                                                                                     *
  *                                                                                                                                   *
  *  REVISIONS:                                                                                                                       *
  *  VER        DATE        AUTHOR           DESCRIPTION                                                                              *
  *  ---------  ----------  -----------  ---------------------------------------------------------------------------------------------*
  *  1.0        08/04/2010  INTASI32          1. SE MODIFICA LAS CONDICIONES CUANDO SE ACTUALIZA EN PAGO EN LA TABLA C2701000         *
  *  1.1        15/08/2010  INTASI32          1. SE AJUSTA A FIN DE INSERTAR LA TASA DEL TRABAJADOR EN LA TABLA C2701000              *
  *  1.2        03/10/2011  INTASI32          1. SE CONTROLA CON LOS ESTADO LA NO INSERCION D REGISTRO DOBLE O CONCILIACIONES ERRONEA *                                                                                                                           *
  *  1.3        04/08/2023  SCHAPARRO         1. SE AGREGA LA COLUMA MCA_CONCILIACION_DIARIA A LA TABLA Y SE AGREGA A LOS INSERT Y    *
  *                                             UPDATE                                                                                *
  *  1.4        28/10/2024  MDURAN            1. SE ELIMINA IF Estcore-5173 Se ajsuta update para qeu sume dato anterior con nuevo    *
  *  1.5        01/08/2025  MARCOS CARVAJAL   1. Se ajusta Ide_Nit_trab para dejar el ultimo digito para insercion en la C2701000     *
  *  1.6        06/10/2025  MARCOS CARVAJAL   1. Se ajusta Ide_Nit_trab se busca por funcion para convertir a un caracter             *
  *  1.7        28/11/2025  WFLC              1. Se convierte parametros (tasa_cotiz) a variables ya que pueden venir vacias                *
  *************************************************************************************************************************************/
  AFTER INSERT ON C2700021
  FOR EACH ROW
DECLARE
  v_Num_Secu_Pol   A2000030.Num_Secu_Pol%TYPE;
  v_Tarifa_Arp     C2701000.Tarifa_Arp%TYPE;
  v_Cont           NUMBER(1) := 0;
  v_Conciliado     VARCHAR2(1);
  v_Novedad        C2700021.Tipo_Nov%TYPE;
  v_Dias_Trondador NUMBER(5);
  v_Fecha_Liqui    C2701000.Fecha_Liqui%TYPE;
  v_Tarifa_Trabaj  C2701000.Tarifa_Arp%TYPE;
  Vexist_Pna       NUMBER(5) := 0;
  v_Tdoc_Trab      VARCHAR(1);
  v_Tasa_Cotiz     C2700021.Tasa_Cotiz%TYPE;
BEGIN
  IF Inserting
  THEN
    IF Length(:New.Ide_Nit_Trab) = 2
    THEN
      v_Tdoc_Trab := Pck270_Validaciones_Grales.Fun_Identif_Tipo_Doc(:New.Ide_Nit_Trab);
    
      IF v_Tdoc_Trab IS NULL
      THEN
        v_Tdoc_Trab := :New.Ide_Nit_Trab;
      END IF;
    ELSE
      v_Tdoc_Trab := :New.Ide_Nit_Trab;
    END IF;
  
    /*  BUSCO EL NUM_SECU_POL*/
    BEGIN
      v_Num_Secu_Pol := Pck270_Validaciones_Grales.Fun_Busca_Numsecupol(:New.Num_Pol1, :New.Cod_Secc);
    EXCEPTION
      WHEN No_Data_Found THEN
        v_Num_Secu_Pol := 0;
      WHEN OTHERS THEN
        v_Num_Secu_Pol := 0;
    END;
  
    /* BUSCO LA TASA COTIZACION ACTUAL*/
    BEGIN
      SELECT l.Valor_Campo
        INTO v_Tarifa_Arp
        FROM A2000020 l
       WHERE l.Num_Secu_Pol = v_Num_Secu_Pol
         AND l.Cod_Campo = 'ULTIMA_TASA'
         AND l.Cod_Ries = :New.Centro_Trab
         AND l.Mca_Vigente = 'S';
    EXCEPTION
      WHEN No_Data_Found THEN
        v_Tarifa_Arp := 0;
      WHEN OTHERS THEN
        NULL;
    END;
  
    v_Novedad    := :New.Tipo_Nov;
    v_Tasa_Cotiz := :New.Tasa_Cotiz;
  
    BEGIN
      /*COMPARO LAS TASAS DE COTIZACION*/
      IF Nvl(v_Tasa_Cotiz, 0) < Nvl(v_Tarifa_Arp, 0) AND
         v_Cont < 1
      THEN
        v_Cont := v_Cont + 1;
      
        /* INSERTO EN LA TABLA DE ENCABEZADOS DE CONCILIACION*/
        UPDATE C2700030 o
           SET o.Fecha_Creacion = SYSDATE
         WHERE o.Nit_Empresa = :New.Cod_Benef
           AND o.Num_Pol1 = :New.Num_Pol1;
      
        IF SQL%NOTFOUND
        THEN
          BEGIN
            INSERT INTO C2700030
              (Depend_Indepen, Centro_Trab, Num_Pol1, Fecha_Creacion, Numero_Cartas, Nit_Empresa, Tdoc_Empresa, Usuario)
            VALUES
              (:New.Depend_Indepen, :New.Centro_Trab, :New.Num_Pol1, SYSDATE, 0, :New.Cod_Benef, :New.Ide_Nit, USER);
          EXCEPTION
            WHEN OTHERS THEN
              Raise_Application_Error(-20099, 'ERROR AL INSERTAR EN LA TABLA DE C2700030' || SQLERRM);
          END;
        END IF;
      ELSIF Nvl(v_Tasa_Cotiz, 0) > Nvl(v_Tarifa_Arp, 0)
      THEN
        v_Cont := 3;
      
        -- BUSCO LA TASA DEL CENTRO DE TRABAJO DEL TRABAJADOR
        -- 15 ABRIL 2010
        BEGIN
          SELECT Pck270_Conciliaciones_Arp.Dato_Varb_Ries(v_Num_Secu_Pol, 'ULTIMA_TASA', a.Centro_Trab)
            INTO v_Tarifa_Trabaj
            FROM C2701000 a
           WHERE a.Nit = :New.Nit
             AND To_Char(a.Fecha_Liqui, 'YYYYMM') = To_Char(:New.Periodo_Pago)
             AND a.Num_Pol_Cli = :New.Num_Pol_Cli
             AND a.Depend_Indepen = :New.Depend_Indepen;
        EXCEPTION
          WHEN No_Data_Found THEN
            v_Tarifa_Trabaj := v_Tarifa_Arp;
          WHEN Too_Many_Rows THEN
            v_Tarifa_Trabaj := v_Tarifa_Arp;
          WHEN OTHERS THEN
            v_Tarifa_Trabaj := v_Tarifa_Arp;
        END;
      
        UPDATE C2701000 o
           SET o.Dias_Liq_Empresa = :New.Dias_Cotiz, o.Salario_Liq_Empresa = :New.Salario, o.Existente_Arp = 'S', o.Centro_Trab_Empresa = :New.Centro_Trab, o.Tarifa_Empresa = :New.Tasa_Cotiz,
               o.Depend_Indepen = :New.Depend_Indepen, o.Estado_Pago = 'TAP', o.Ibc = :New.Ibc, o.Valor_Aporte = :New.Valor_Aporte, o.Tarifa_Arp = Nvl(v_Tarifa_Trabaj, v_Tarifa_Arp),
               o.Nit_Empresa = :New.Cod_Benef, o.Tdoc_Empresa = :New.Ide_Nit, o.Conciliado = 'T', o.Mca_Conciliacion_Diaria = 'D'
         WHERE o.Nit = :New.Nit
           AND To_Char(o.Fecha_Liqui, 'YYYYMM') = To_Char(:New.Periodo_Pago)
           AND o.Num_Pol_Cli = :New.Num_Pol_Cli -- 08 ABRIL 2010
           AND o.Depend_Indepen = :New.Depend_Indepen
           AND o.Estado_Pago IN ('ANP', 'TAP'); /* DATE MODIFICATION: 03/10/2011 REQUIREMENT:SRS000515 */
      
        IF SQL%NOTFOUND
        THEN
          /******************************************************************************************************************************************/
          /* DESCRIPTION:  SE VERIFICA SI YA EXISTE UN PNA, SI EXISTE NO SE VUELVE A INSERTAR                DATE:03/10/2011  REQUIREMENT:SRS000515 */
          /******************************************************************************************************************************************/
        
          BEGIN
            SELECT /*+ INDEX(C2701000 A   OPS$PUMA.I5_C2701000) */
             COUNT(1)
              INTO Vexist_Pna
              FROM C2701000 a
             WHERE To_Char(a.Fecha_Liqui, 'YYYYMM') = To_Char(:New.Periodo_Pago)
               AND a.Num_Pol_Cli = :New.Num_Pol_Cli
               AND a.Nit = :New.Nit
               AND a.Depend_Indepen = :New.Depend_Indepen
               AND a.Estado_Pago = 'PNA';
          END;
        
          IF Vexist_Pna = 0
          THEN
            BEGIN
              SELECT Last_Day(To_Date(:New.Periodo_Pago, 'YYYYMM')) INTO v_Fecha_Liqui FROM Dual;
            END;
          
            BEGIN
              INSERT INTO C2701000
                (Cod_Cia, Cod_Secc, Cod_Ramo, Num_Pol1, Centro_Trab, Nit, Ide_Nit, Fecha_Liqui, Salario, Dias_Liq, Estado, Dias_Liq_Empresa, Salario_Liq_Empresa, Existente_Arp, Centro_Trab_Empresa,
                 Tarifa_Empresa, Depend_Indepen, Estado_Pago, Ibc, Valor_Aporte, Tarifa_Arp, Nit_Empresa, Tdoc_Empresa, Fecha_Creacion, Conciliado, Mca_Conciliacion_Diaria)
              VALUES
                (:New.Cod_Cia, :New.Cod_Secc, :New.Cod_Ramo, :New.Num_Pol1, :New.Centro_Trab, :New.Nit, v_Tdoc_Trab, v_Fecha_Liqui, NULL, NULL, :New.Tipo_Nov, :New.Dias_Cotiz, :New.Salario, 'N',
                 :New.Centro_Trab, :New.Tasa_Cotiz, :New.Depend_Indepen, 'PNA', :New.Ibc, :New.Valor_Aporte, v_Tarifa_Arp, :New.Cod_Benef, :New.Ide_Nit, SYSDATE, 'T', 'D');
            EXCEPTION
              WHEN OTHERS THEN
                Raise_Application_Error(-20099, 'ERROR AL INSERTAR EN LA TABLA DE CONCILIACIONES' || SQLERRM);
            END;
          END IF;
        END IF;
      END IF;
    
      /*PREGUNTO SI ES UNA NOVEDAD DE INGRESO Y RETIRO*/
      IF v_Novedad = 'I-R' AND
         v_Cont < 1
      THEN
        v_Cont := v_Cont + 1;
      
        /* INSERTO EN LA TABLA DE ENCABEZADOS DE CONCILIACION*/
        UPDATE C2700030 o
           SET o.Fecha_Creacion = SYSDATE
         WHERE o.Nit_Empresa = :New.Cod_Benef
           AND o.Num_Pol1 = :New.Num_Pol1;
      
        IF SQL%NOTFOUND
        THEN
          BEGIN
            INSERT INTO C2700030
              (Depend_Indepen, Centro_Trab, Num_Pol1, Fecha_Creacion, Numero_Cartas, Nit_Empresa, Tdoc_Empresa, Usuario)
            VALUES
              (:New.Depend_Indepen, :New.Centro_Trab, :New.Num_Pol1, SYSDATE, 0, :New.Cod_Benef, :New.Ide_Nit, USER);
          EXCEPTION
            WHEN OTHERS THEN
              Raise_Application_Error(-20099, 'ERROR AL INSERTAR EN LA TABLA DE C2700030' || SQLERRM);
          END;
        END IF;
      END IF;
    END;
  
    IF :New.Dias_Cotiz < 30
    THEN
      IF :New.Tipo_Nov = 'ING'
      THEN
        IF :New.Fecha_Desde IS NOT NULL
        THEN
          v_Dias_Trondador := Trunc(Last_Day(SYSDATE) - :New.Fecha_Desde);
        
          IF v_Dias_Trondador > 30
          THEN
            v_Dias_Trondador := 30;
          END IF;
        
          IF v_Dias_Trondador > :New.Dias_Cotiz AND
             v_Cont < 1
          THEN
            v_Cont := v_Cont + 1;
          
            UPDATE C2700030 o
               SET o.Fecha_Creacion = SYSDATE
             WHERE o.Nit_Empresa = :New.Cod_Benef
               AND o.Num_Pol1 = :New.Num_Pol1;
          
            IF SQL%NOTFOUND
            THEN
              BEGIN
                INSERT INTO C2700030
                  (Depend_Indepen, Centro_Trab, Num_Pol1, Fecha_Creacion, Numero_Cartas, Nit_Empresa, Tdoc_Empresa, Usuario)
                VALUES
                  (:New.Depend_Indepen, :New.Centro_Trab, :New.Num_Pol1, SYSDATE, 0, :New.Cod_Benef, :New.Ide_Nit, USER);
              EXCEPTION
                WHEN OTHERS THEN
                  Raise_Application_Error(-20099, 'ERROR AL INSERTAR EN LA TABLA DE C2700030' || SQLERRM);
              END;
            END IF;
          END IF;
        END IF;
      ELSIF :New.Tipo_Nov NOT IN ('SLN', 'LMA', 'IGE', 'VAC', 'IRP') AND
            v_Cont < 1
      THEN
        v_Cont := v_Cont + 1;
      
        UPDATE C2700030 o
           SET o.Fecha_Creacion = SYSDATE
         WHERE o.Nit_Empresa = :New.Cod_Benef
           AND o.Num_Pol1 = :New.Num_Pol1;
      
        IF SQL%NOTFOUND
        THEN
          BEGIN
            INSERT INTO C2700030
              (Depend_Indepen, Centro_Trab, Num_Pol1, Fecha_Creacion, Numero_Cartas, Nit_Empresa, Tdoc_Empresa, Usuario)
            VALUES
              (:New.Depend_Indepen, :New.Centro_Trab, :New.Num_Pol1, SYSDATE, 0, :New.Cod_Benef, :New.Ide_Nit, USER);
          EXCEPTION
            WHEN OTHERS THEN
              Raise_Application_Error(-20099, 'ERROR AL INSERTAR EN LA TABLA DE C2700030' || SQLERRM);
          END;
        END IF;
      END IF;
    END IF;
  
    BEGIN
      /*INSERTO EN EL DETALLE DE TRABAJADORES CONCILIACION*/
      IF v_Cont < 3
      THEN
        IF v_Cont > 0
        THEN
          v_Conciliado := 'N';
        ELSE
          v_Conciliado := 'S';
        END IF;
      
        -- BUSCO LA TASA DEL CENTRO DE TRABAJO DEL TRABAJADOR
        -- 15 ABRIL 2010
        BEGIN
          SELECT Pck270_Conciliaciones_Arp.Dato_Varb_Ries(v_Num_Secu_Pol, 'ULTIMA_TASA', a.Centro_Trab)
            INTO v_Tarifa_Trabaj
            FROM C2701000 a
           WHERE a.Nit = :New.Nit
             AND To_Char(a.Fecha_Liqui, 'YYYYMM') = To_Char(:New.Periodo_Pago)
             AND a.Num_Pol_Cli = :New.Num_Pol_Cli
             AND a.Depend_Indepen = :New.Depend_Indepen;
        EXCEPTION
          WHEN No_Data_Found THEN
            v_Tarifa_Trabaj := v_Tarifa_Arp;
          WHEN Too_Many_Rows THEN
            v_Tarifa_Trabaj := v_Tarifa_Arp;
          WHEN OTHERS THEN
            v_Tarifa_Trabaj := v_Tarifa_Arp;
        END;
      
        /*Ajuste segun Estcore-5173 Mario Duran Nueva regla usuario se desacartan los pagos
        con tasa en cero.*/
        --IF :NEW.Tasa_Cotiz > 0
        --THEN
        /*Estcore-10911 Mario Duran Se quita if Estcore-5173 y se ajusta set de update*/
        UPDATE C2701000 o
           SET o.Dias_Liq_Empresa = Nvl(o.Dias_Liq_Empresa, 0) + Nvl(:New.Dias_Cotiz, 0),
               o.Salario_Liq_Empresa = CASE
                                         WHEN Nvl(:New.Salario, 0) <> Nvl(o.Salario, 0) THEN
                                          Nvl(o.Salario_Liq_Empresa, 0) + Nvl(:New.Salario, 0)
                                         WHEN (Nvl(:New.Salario, 0) = Nvl(o.Salario, 0) AND Nvl(:New.Salario, 0) > 0 AND Nvl(o.Salario, 0) > 0) THEN
                                          Nvl(:New.Salario, 0)
                                       END, o.Existente_Arp = 'S', o.Centro_Trab_Empresa = :New.Centro_Trab,
               o.Tarifa_Empresa = CASE
                                    WHEN Nvl(v_Tasa_Cotiz, 0) = 0 THEN
                                     Nvl(v_Tarifa_Trabaj, v_Tarifa_Arp)
                                    WHEN Nvl(v_Tasa_Cotiz, 0) > 0 THEN
                                     Nvl(v_Tasa_Cotiz, 0)
                                  END, o.Depend_Indepen = :New.Depend_Indepen, o.Estado_Pago = 'TAP', o.Ibc = Nvl(o.Ibc, 0) + Nvl(:New.Ibc, 0),
               o.Valor_Aporte = Nvl(o.Valor_Aporte, 0) + Nvl(:New.Valor_Aporte, 0), o.Tarifa_Arp = Nvl(v_Tarifa_Trabaj, v_Tarifa_Arp), o.Nit_Empresa = :New.Cod_Benef, o.Tdoc_Empresa = :New.Ide_Nit,
               o.Conciliado = v_Conciliado, o.Mca_Conciliacion_Diaria = 'D'
        /*Fin Estcore-10911 Mario Duran Se quita if Estcore-5173 y se ajusta set de update*/
        /*SET O.Dias_Liq_Empresa = :NEW.Dias_Cotiz, O.Salario_Liq_Empresa = :NEW.Salario, O.Existente_Arp = 'S', O.Centro_Trab_Empresa = :NEW.Centro_Trab
        ,O.Tarifa_Empresa = :NEW.Tasa_Cotiz, O.Depend_Indepen = :NEW.Depend_Indepen, O.Estado_Pago = 'TAP', O.Ibc = :NEW.Ibc
        ,O.Valor_Aporte = :NEW.Valor_Aporte, O.Tarifa_Arp = NVL( V_Tarifa_Trabaj, V_Tarifa_Arp ), O.Nit_Empresa = :NEW.Cod_Benef, O.Tdoc_Empresa = :NEW.Ide_Nit
        ,O.Conciliado = V_Conciliado, O.mca_conciliacion_diaria = 'D' */
         WHERE o.Nit = :New.Nit
           AND To_Char(o.Fecha_Liqui, 'YYYYMM') = To_Char(:New.Periodo_Pago)
           AND o.Num_Pol_Cli = :New.Num_Pol_Cli -- 08 ABRIL 2010
           AND o.Depend_Indepen = :New.Depend_Indepen
           AND o.Estado_Pago IN ('ANP', 'TAP'); /* DATE MODIFICATION: 03/10/2011 REQUIREMENT:SRS000515 */
      
        IF SQL%NOTFOUND
        THEN
          /******************************************************************************************************************************************/
          /* DESCRIPTION:  SE VERIFICA SI YA EXISTE UN PNA, SI EXISTE NO SE VUELVE A INSERTAR                DATE:03/10/2011  REQUIREMENT:SRS000515 */
          /******************************************************************************************************************************************/
          BEGIN
            SELECT /*+ INDEX(C2701000 A   OPS$PUMA.I5_C2701000) */
             COUNT(1)
              INTO Vexist_Pna
              FROM C2701000 a
             WHERE To_Char(a.Fecha_Liqui, 'YYYYMM') = To_Char(:New.Periodo_Pago)
               AND a.Num_Pol_Cli = :New.Num_Pol_Cli
               AND a.Nit = :New.Nit
               AND a.Depend_Indepen = :New.Depend_Indepen
               AND a.Estado_Pago = 'PNA';
          END;
        
          IF Vexist_Pna = 0
          THEN
            BEGIN
              SELECT Last_Day(To_Date(:New.Periodo_Pago, 'YYYYMM')) INTO v_Fecha_Liqui FROM Dual;
            END;
          
            BEGIN
              INSERT INTO C2701000
                (Cod_Cia, Cod_Secc, Cod_Ramo, Num_Pol1, Centro_Trab, Nit, Ide_Nit, Fecha_Liqui, Salario, Dias_Liq, Estado, Dias_Liq_Empresa, Salario_Liq_Empresa, Existente_Arp, Centro_Trab_Empresa,
                 Tarifa_Empresa, Depend_Indepen, Estado_Pago, Ibc, Valor_Aporte, Tarifa_Arp, Nit_Empresa, Tdoc_Empresa, Fecha_Creacion, Conciliado, Mca_Conciliacion_Diaria)
              VALUES
                (:New.Cod_Cia, :New.Cod_Secc, :New.Cod_Ramo, :New.Num_Pol1, :New.Centro_Trab, :New.Nit, v_Tdoc_Trab, v_Fecha_Liqui, NULL, NULL, :New.Tipo_Nov, :New.Dias_Cotiz, :New.Salario, 'N',
                 :New.Centro_Trab, :New.Tasa_Cotiz, :New.Depend_Indepen, 'PNA', :New.Ibc, :New.Valor_Aporte, v_Tarifa_Arp, :New.Cod_Benef, :New.Ide_Nit, SYSDATE, v_Conciliado, 'D');
            EXCEPTION
              WHEN OTHERS THEN
                Raise_Application_Error(-20099, 'ERROR AL INSERTAR EN LA TABLA DE CONCILIACIONES' || SQLERRM);
            END;
          
            IF v_Cont < 1
            THEN
              /* INSERTO EN LA TABLA DE ENCABEZADOS DE CONCILIACION SI SE TRATA DE UN 'PNA' PAGO NO AFILIADO*/
              UPDATE C2700030 o
                 SET o.Fecha_Creacion = SYSDATE
               WHERE o.Nit_Empresa = :New.Cod_Benef
                 AND o.Num_Pol1 = :New.Num_Pol1;
            
              IF SQL%NOTFOUND
              THEN
                BEGIN
                  INSERT INTO C2700030
                    (Depend_Indepen, Centro_Trab, Num_Pol1, Fecha_Creacion, Numero_Cartas, Nit_Empresa, Tdoc_Empresa, Usuario)
                  VALUES
                    (:New.Depend_Indepen, :New.Centro_Trab, :New.Num_Pol1, SYSDATE, 0, :New.Cod_Benef, :New.Ide_Nit, USER);
                EXCEPTION
                  WHEN OTHERS THEN
                    Raise_Application_Error(-20099, 'ERROR AL INSERTAR EN LA TABLA DE C2700030' || SQLERRM);
                END;
              END IF;
            END IF;
          END IF;
        END IF;
        --END IF;
      END IF;
    END;
  END IF;
END Trg_Concilia_Arp_C2700021;
/