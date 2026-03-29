CREATE OR REPLACE TRIGGER TRG_AIUD_001_C2700001
AFTER DELETE OR INSERT OR UPDATE
ON C2700001 
REFERENCING NEW AS NEW OLD AS OLD
FOR EACH ROW
DECLARE
/********************************************************************************************************
   NAME:       TRG_AIUD_001_C2700001
   PURPOSE:

   REVISIONS:
   VER        DATE        AUTHOR           DESCRIPTION
   ---------  ----------  ---------------  --------------------------------------------------------------
   1.0        08/08/2013      79704401       1. CREATED THIS TRIGGER.
   NOTES:

   AUTOMATICALLY AVAILABLE AUTO REPLACE KEYWORDS:
      OBJECT NAME:     TRG_AIUD_001_C2700001
      SYSDATE:         08/08/2013
      DATE AND TIME:   08/08/2013, 11:12:08 A.M., AND 08/08/2013 11:12:08 A.M.
      USERNAME:        79704401 (SET IN TOAD OPTIONS, PROC TEMPLATES)
      TABLE NAME:      C2700001 (SET IN THE "NEW PL/SQL OBJECT" DIALOG)
      TRIGGER OPTIONS:  (SET IN THE "NEW PL/SQL OBJECT" DIALOG)
********************************************************************************************************/


BEGIN
    IF INSERTING
    THEN
        IF :New.Estado = 'ING'
        THEN
            INSERT INTO Sim_Arl_Sat_Trabajador A (A.Cod_Cia, A.Cod_Secc, A.Cod_Ramo, A.Num_Pol1, A.Centro_Trab,
                                                  A.Nit, A.Ide_Nit, A.Salario, A.Fec_Ingreso, A.Estado_Movimiento,
                                                  A.Medio_Cargue_Arp, A.Depend_Indepen, A.Subtipo_Cotizante, A.Fecha_Ini_Cobertura, A.Fecha_Fin_Cobertura,
                                                  A.Valor_Ibc, A.Estado, A.Observaciones, A.Aud_Fecha_Creacion, A.Aud_User_Creacion)
                     VALUES ( :New.Cod_Cia, :New.Cod_Secc, :New.Cod_Ramo, :New.Num_Pol1, :New.Centro_Trab, :New.Nit, :New.Ide_Nit, :New.Salario, :New.Fec_Ingreso, 'AFILIACION_TRABAJADOR', :New.Medio_Cargue_Arp,
                         :New.Depend_Indepen, NULL, :New.Fecha_Ini_Cobertura, :New.Fecha_Fin_Cobertura, :New.Valor_Ibc, :New.Estado, 'AFILIACION_TRABAJADOR', SYSDATE, USER);
        END IF;
    ELSIF UPDATING
    THEN
        IF :New.Depend_Indepen <> :Old.Depend_Indepen
        THEN
            BEGIN
                INSERT INTO Sim_Arl_Sat_Trabajador A (A.Cod_Cia, A.Cod_Secc, A.Cod_Ramo, A.Num_Pol1, A.Centro_Trab,
                                                      A.Nit, A.Ide_Nit, A.Salario, A.Fec_Ingreso, A.Estado_Movimiento,
                                                      A.Medio_Cargue_Arp, A.Depend_Indepen, A.Subtipo_Cotizante, A.Fecha_Ini_Cobertura, A.Fecha_Fin_Cobertura,
                                                      A.Valor_Ibc, A.Estado, A.Observaciones, A.Aud_Fecha_Creacion, A.Aud_User_Creacion)
                         VALUES ( :New.Cod_Cia, :New.Cod_Secc, :New.Cod_Ramo, :New.Num_Pol1, :New.Centro_Trab, :New.Nit, :New.Ide_Nit, :New.Salario, :New.Fec_Ingreso, 'UPD_TIPO_COTIZANTE_TRABAJADOR',
                             :New.Medio_Cargue_Arp, :New.Depend_Indepen, NULL, :New.Fecha_Ini_Cobertura, :New.Fecha_Fin_Cobertura, :New.Valor_Ibc, :New.Estado, 'UPD_TIPO_COTIZANTE_TRABAJADOR', SYSDATE, USER);
            END;
        END IF;

        IF :New.Estado = 'RET' AND :Old.Estado = 'ING'
        THEN
            BEGIN
                INSERT INTO Sim_Arl_Sat_Trabajador A (A.Cod_Cia, A.Cod_Secc, A.Cod_Ramo, A.Num_Pol1, A.Centro_Trab,
                                                      A.Nit, A.Ide_Nit, A.Salario, A.Fec_Ingreso, A.Estado_Movimiento,
                                                      A.Medio_Cargue_Arp, A.Depend_Indepen, A.Subtipo_Cotizante, A.Fecha_Ini_Cobertura, A.Fecha_Fin_Cobertura,
                                                      A.Valor_Ibc, A.Estado, A.Observaciones, A.Aud_Fecha_Creacion, A.Aud_User_Creacion)
                         VALUES ( :New.Cod_Cia,
                             :New.Cod_Secc, :New.Cod_Ramo, :New.Num_Pol1, :New.Centro_Trab, :New.Nit, :New.Ide_Nit, :New.Salario, :New.Fec_Ingreso, 'UPD_Estado_movimiento_TRABAJADOR', :New.Medio_Cargue_Arp,
                             :New.Depend_Indepen, NULL, :New.Fecha_Ini_Cobertura, :New.Fecha_Fin_Cobertura, :New.Valor_Ibc, :New.Estado, 'UPD_Estado_movimiento_TRABAJADOR', SYSDATE, USER);
            END;
        END IF;
    ELSIF DELETING
    THEN
        NULL;
    END IF;
EXCEPTION
    WHEN OTHERS
    THEN
        -- CONSIDER LOGGING THE ERROR AND THEN RE-RAISE
        --RAISE;
        NULL;
END Trg_Aiud_001_C2700001;
/
