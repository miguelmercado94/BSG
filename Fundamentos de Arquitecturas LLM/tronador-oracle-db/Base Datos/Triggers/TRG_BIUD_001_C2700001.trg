CREATE OR REPLACE TRIGGER Trg_Biud_001_C2700001
  BEFORE DELETE OR INSERT OR UPDATE ON C2700001 
  REFERENCING NEW AS NEW OLD AS OLD
  FOR EACH ROW
DECLARE
  v_Cantidad NUMBER;
  v_Edad     NUMBER;
  /******************************************************************************
     NAME:       TRG_001_BIUD_C2700001
     PURPOSE:
      REVISIONS:
     Ver        Date        Author           Description
     ---------  ----------  ---------------  ---------------------------------------------------------------------------------------
     1.0        16/09/2014  79704401         1. Created this trigger.
     1.0.1      22/09/2014  Wilson Lopez     1. Se Unifica este Trigger con Trg_Biu_C2700001_Fecbaja
     1.0.2      22/09/2014  Wilson Lopez     1. Control ING Mantis Srto[199-2014]ArlMntsNo2907
     1.0.3      06/10/2014  Wilson Lopez     1. control medio de Cargue 4, Mantis 30328
     1.0.4      13/01/2015  Oscar Montiel    1. Se modifica la  validación existente sobre fecha de baja para que aplique para los
                                                trabajadores dependientes. Mantis 33754
                                             2. Se adiciona control para los trabajadores independientes sobre fecha de fin de contrato
                                                cuando se realiza una inserción o actualización. Mantis 33754, Mantis 32728
     1.0.5     20/06/2016   Leonardo Rojas   1. Se actualiza los filtro del query.
     1.0.6     19/07/2016   Wilson Lopez     1. Se controla registros Duplicados mantis Srto[117-2016]MntsNo[46681]
     1.0.5     10/10/2016  Oscar Montiel     1. Mantis 49476 - Se adiciona validación de que el mensaje de error solo aplique si la
                                                operacion se realiza desde la pagina.
     1.0.6     12/10/2016  Wilson F Lopez    1. Se omite la validación de actualización Mantis 49476 ya que la actualización se respeta el medio de cargue
                                                donde fue ingresado por lo anterior no es actualizado.
     1.0.7     22/03/2017   Wilson F Lopez   1. Se adiciona los valores por defecto de FORMA PAGO/Tpo_Contrato/Modalidad Srto[053-2017]MntsNo[53206][ARLOnline]                                               
  
     NOTES:
      Automatically available Auto Replace Keywords:
        Object Name:     Trg_Biud_001_C2700001
        Sysdate:         16/09/2014
        Date and Time:   16/09/2014, 09:45:41 a.m., and 16/09/2014 09:45:41 a.m.
        Username:        79704401 (set in TOAD Options, Proc Templates)
        Table Name:      C2700001 (set in the "New PL/SQL Object" dialog)
        Trigger Options:  (set in the "New PL/SQL Object" dialog)
  ******************************************************************************/

BEGIN
  -- track who created the new row
  IF Inserting THEN
    --
    -- Ini Mantis 33754 Nota 142194 omontiel 02/03/2015
    --
    IF :New.Depend_Indepen = 3 THEN
      --
    
      /*******************************************************************************************************************************************************/
      /* ENGINEER : WFLC DATE : 22/03/2017 DESCRIPTION : FORMA PAGO/Tpo_Contrato/Modalidad Valores Defecto  SEQUENCE : Srto[053-2017]MntsNo[53206][ARLOnline]*/
      /******************************************************************************************************************************************************/
      IF :New.Estado = 'ING' AND
         (Nvl(:New.Forma_Pago, 0) = 0 OR Nvl(:New.Tpo_Contrato, 0) = 0 OR
         Nvl(:New.Modalidad, 0) = 0) THEN
        IF Nvl(:New.Forma_Pago, 0) = 0 THEN
          :New.Forma_Pago := 1;
        END IF;
        IF Nvl(:New.Tpo_Contrato, 0) = 0 THEN
          :New.Tpo_Contrato := 3;
        END IF;
        IF Nvl(:New.Modalidad, 0) = 0 THEN
          :New.Modalidad := '2';
        END IF;
      END IF;
    
      IF :New.Medio_Cargue_Arp = '4' THEN
        -- Mantis 49476 omontiel 10/10/2016 Se adiciona validación
        --
        -- Ini Mantis 32728 omontiel 13/01/2015
        --
        IF Trunc(:New.Fecha_Term_Contrato) <
           Trunc(Add_Months(:New.Fecha_Inic_Contrato, 1)) OR
           Trunc(:New.Fecha_Term_Contrato) >
           Trunc(Add_Months(:New.Fecha_Inic_Contrato, 24)) THEN
          --
          Raise_Application_Error(-20501,
                                  'Señor contratante, el tiempo máximo estimado es de dos años y mínimo de un mes, una vez cumpla con este tiempo no olvide renovar el contrato por la opcion de renovación, si éste excede el tiempo de finalización del contrato.');
          --
        END IF;
        --
        -- Fin Mantis 32728
        --
      END IF;
      --
      --
    ELSE
      --
      IF :New.Fec_Baja IS NOT NULL AND
         (To_Date(To_Char(:New.Fec_Baja, 'DD/MM/YYYY'), 'DD/MM/YYYY') <
         To_Date('01/01/1951', 'DD/MM/YYYY') OR
         To_Date(To_Char(:New.Fec_Baja, 'DD/MM/YYYY'), 'DD/MM/YYYY') >
         Trunc(Add_Months(SYSDATE, 60))) --TO_DATE ('31/12/2020', 'DD/MM/YYYY'))
       THEN
        Raise_Application_Error(-20501,
                                ' Control Del Sistema:* Fecha De Baja No Esta Entre Los Rangos');
      END IF;
      --
    END IF;
  
    --
    -- Fin Mantis 33754
    --
    IF :New.Estado = 'ING' AND
       :New.Medio_Cargue_Arp = '4' THEN
      BEGIN
        BEGIN
          --- LROJAS   20160620      MANTIS 42615 - 46681
          SELECT /*+ INDEX(C2700001 I_C2700001) */
           COUNT(1)
            INTO v_Cantidad
            FROM C2700001 A2
           WHERE A2.Estado = 'ING'
             AND A2.Cod_Cia = :New.Cod_Cia
             AND A2.Cod_Secc = :New.Cod_Secc
             AND A2.Cod_Ramo = :New.Cod_Ramo
             AND A2.Num_Pol1 = :New.Num_Pol1
             AND A2.Centro_Trab = :New.Centro_Trab
             AND A2.Nit = :New.Nit
             AND A2.Ide_Nit = :New.Ide_Nit
             AND A2.Salario = :New.Salario
             AND A2.Sal_Liqui = :New.Sal_Liqui
             AND A2.Cod_Cargo = :New.Cod_Cargo
             AND A2.Cod_Eps = :New.Cod_Eps
             AND A2.Cod_Afp = :New.Cod_Afp
             AND A2.Dias_Liq = :New.Dias_Liq
             AND A2.Fec_Nace = :New.Fec_Nace
             AND A2.Fec_Ingreso = :New.Fec_Ingreso
             AND A2.Fec_Equipo = :New.Fec_Equipo
             AND A2.Depend_Indepen = :New.Depend_Indepen
             AND A2.Medio_Cargue_Arp = :New.Medio_Cargue_Arp
             AND A2.Lote = :New.Lote
             AND A2.Cod_Usr = :New.Cod_Usr;
          ----  MANTIS 42615
        END;
      
        IF v_Cantidad > 0 THEN
          Raise_Application_Error(-20502,
                                  'Control Del Sistema:* No Se Pudo Efectuar La Transacción:.*Trabajador Ya Existe');
        END IF;
      END;
    END IF;
  ELSIF Deleting THEN
    NULL;
  ELSIF Updating THEN
    --    BEGIN
    --      --
    --      -- Ini Mantis 33754 Nota 142194 omontiel 02/03/2015
    --      --
    --      IF :NEW.Depend_Indepen = 3
    --      THEN
    --        --
    --        IF :NEW.Medio_Cargue_Arp = '4'
    --        THEN                                                                                                                                                      -- Mantis 49476 omontiel 10/10/2016 Se adiciona validación
    --          --Ini Mantis 32728 omontiel 13/01/2015
    --
    --           --
    --           IF TRUNC (:NEW.Fecha_Term_Contrato) < TRUNC (ADD_MONTHS (:NEW.Fecha_Inic_Contrato, 1))
    --              OR TRUNC (:NEW.Fecha_Term_Contrato) > TRUNC (ADD_MONTHS (:NEW.Fecha_Inic_Contrato, 24)) THEN
    --                  RAISE_APPLICATION_ERROR (
    --                     -20501,
    --                    'Señor contratante, el tiempo máximo estimado es de dos años y mínimo de un mes, una vez cumpla con este tiempo no olvide renovar el contrato por la opcion de renovación, si éste excede el tiempo de finalización del contrato.');
    --               --
    --           END IF;
    --           --
    --           -- Fin Mantis 32728
    --
    --           --
    --        END IF;
    --
    --      ELSE
    --        --
  
    IF :New.Fec_Baja IS NOT NULL AND
       (To_Date(To_Char(:New.Fec_Baja, 'DD/MM/YYYY'), 'DD/MM/YYYY') <
       To_Date('01/01/1951', 'DD/MM/YYYY') OR
       To_Date(To_Char(:New.Fec_Baja, 'DD/MM/YYYY'), 'DD/MM/YYYY') >
       Trunc(Add_Months(SYSDATE, 60))) --TO_DATE ('31/12/2020', 'DD/MM/YYYY'))
     THEN
      Raise_Application_Error(-20501,
                              ' Control Del Sistema:* Fecha De Baja No Esta Entre Los Rangos');
    END IF;
  
    --
    --      END IF;
    --    --
    --    -- Fin Mantis 33754
    --
    --END;
  
    NULL;
  END IF;
  --
END Trg_Biud_001_C2700001;
/
