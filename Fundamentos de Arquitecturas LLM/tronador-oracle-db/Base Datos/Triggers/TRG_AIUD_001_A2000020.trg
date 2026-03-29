CREATE OR REPLACE TRIGGER TRG_AIUD_001_A2000020
    BEFORE INSERT
    ON A2000020 
    REFERENCING NEW AS New OLD AS Old
    FOR EACH ROW
WHEN (
       (New.Cod_Campo = 'ACTIVIDADPP'
       AND New.Mca_Vigente = 'S'
       AND New.Num_End > 0)
      )
DECLARE

/******************************************************************************
   NAME:       TRG_AIUD_001_A2000020
   PURPOSE:

   REVISIONS:
   Ver        Date        Author           Description
   ---------  ----------  ---------------  ------------------------------------
   1.0        17/04/2024  Brian Manjarres  1. Se capturan novedades de modificación
                                              de actividades economicas.

******************************************************************************/

BEGIN
    IF INSERTING
    THEN          
      BEGIN
         UPDATE Sim_Arl_Sat_Empresas A
         SET A.Tipo_Movimiento = 'VARIACION_ACT_ECO'
         WHERE A.Num_Secu_Pol = :New.Num_Secu_Pol
         AND A.Num_End = :New.Num_End
         AND A.Cod_End = 2
         AND A.Sub_Cod_End = 0;
      END;
    END IF;

END TRG_AIUD_001_A2000020;
/
