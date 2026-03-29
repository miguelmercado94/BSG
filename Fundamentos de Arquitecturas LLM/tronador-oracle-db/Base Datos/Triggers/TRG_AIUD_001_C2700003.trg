CREATE OR REPLACE TRIGGER TRG_AIUD_001_C2700003
AFTER INSERT
ON C2700003
REFERENCING NEW AS NEW OLD AS OLD
FOR EACH ROW

/********************************************************************************************************
   NAME:       TRG_AIUD_001_C2700003
   HU:         GD805-135
 
   REVISIONS:
   VER        DATE        AUTHOR           DESCRIPTION
   ---------  ----------  ---------------  --------------------------------------------------------------
   1.0        17/01/2024  Brian Manjarres  1. CREATED THIS TRIGGER.
   NOTES:

   AUTOMATICALLY AVAILABLE AUTO REPLACE KEYWORDS:
      OBJECT NAME:     TRG_AIUD_001_C2700003
      SYSDATE:         17/01/2024
      USERNAME:        Brian Manjarres
      TABLE NAME:      C2700003
      OBJECTIVE:       CAPTURAR LAS NOVEDADES DE VARIACIÓN DE CENTRO DE TRABAJO PARA TRABAJADORES A SER REPORTADAS AL SAT.
********************************************************************************************************/
BEGIN
    IF INSERTING
    THEN
        IF (:New.Cod_Movimi = 'VCT' AND :New.Estado_Novedad = 'NSC' AND (:New.Medio_Cargue_Arp = 2 OR :New.Medio_Cargue_Arp = 3 OR :New.Medio_Cargue_Arp = 4) AND (:New.Depend_Indepen <> 57 AND :New.Depend_Indepen <> 59))
        THEN

            INSERT INTO Sim_Arl_Sat_Trabajador A (A.Cod_Cia, A.Cod_Secc, A.Cod_Ramo, A.Num_Pol1, A.Centro_Trab,
                                                  A.Nit, A.Ide_Nit, A.Salario, A.Fec_Ingreso, A.Estado_Movimiento,
                                                  A.Medio_Cargue_Arp, A.Depend_Indepen, A.Subtipo_Cotizante, A.Fecha_Ini_Cobertura, A.Fecha_Fin_Cobertura,
                                                  A.Valor_Ibc, A.Estado, A.Observaciones, A.Aud_Fecha_Creacion, A.Aud_User_Creacion, A.Fecha_Equipo)
            VALUES (:New.Cod_Cia, :New.Cod_Secc, :New.Cod_Ramo, :New.Num_Pol1, :New.Centro_Trab, :New.Nit, :New.Ide_Nit, :New.Salario, :New.Fec_Ingreso, 'VARIACION_CT', :New.Medio_Cargue_Arp,
                    :New.Depend_Indepen, 0, :New.Fecha_Ini_Cobertura, :New.Fecha_Fin_Cobertura, :New.Valor_Ibc, 'ING', 'VARIACION_CT', SYSDATE, USER, :New.Fec_Equipo);

        END IF;
    END IF;

EXCEPTION
    WHEN OTHERS
    THEN
      
        NULL;

END TRG_AIUD_001_C2700003;
/
