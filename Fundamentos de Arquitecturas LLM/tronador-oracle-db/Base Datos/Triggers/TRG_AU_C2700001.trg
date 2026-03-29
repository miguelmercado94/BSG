CREATE OR REPLACE TRIGGER TRG_AU_C2700001
AFTER UPDATE
ON C2700001
REFERENCING NEW AS NEW OLD AS OLD
FOR EACH ROW
DECLARE
  tmpvar  NUMBER;
  -- Jira GD724-3 
  lt_C2700001 C2700001%ROWTYPE;
/***********************************************************************************************************************************************


   NAME:       TRG_AU_C2700001
   PURPOSE:

   REVISIONS:
   VER        DATE        AUTHOR           DESCRIPTION
   ---------  ----------  ---------------  ------------------------------------
   1.0        06/04/2011  INTASI32         1. SE CONTROLA LA ACTUALIZACION DE LA POLIZA EN LA TABLA C2700355 - TRABAJADORES EN EL EXTERIOR.
   2.0        10/10/2023  Orlando Gomez    1. Jira GD724-3 Se adiciona procedimiento para modificar conciliación cuando de retira retroactivo un trabajador
   NOTES:

   AUTOMATICALLY AVAILABLE AUTO REPLACE KEYWORDS:
      OBJECT NAME:     TRG_AU_C2700001
      SYSDATE:         06/04/2011
      DATE AND TIME:   06/04/2011, 09:19:11 A.M., AND 06/04/2011 09:19:11 A.M.
      USERNAME:        79704401 (SET IN TOAD OPTIONS, PROC TEMPLATES)
      TABLE NAME:      C2700001 (SET IN THE "NEW PL/SQL OBJECT" DIALOG)
      TRIGGER OPTIONS:  (SET IN THE "NEW PL/SQL OBJECT" DIALOG)
***********************************************************************************************************************************************/
BEGIN
  BEGIN
    /******************************************************************************************************************************************/
    /* DESCRIPTION:ACTUALIZA LA POLIZA EN C2700355 CUANDO ESTA SUFRE ALGUNA MODIFICACION.              DATE:06/04/2011  REQUIREMENT:SRS000394 */
    /******************************************************************************************************************************************/

    IF :old.num_pol1 <> :new.num_pol1
   AND :old.estado = 'ING' THEN
      BEGIN
        UPDATE /*+ ALL_ROWS */
              c2700355 a
           SET a.num_pol1  = :new.num_pol1
         WHERE a.nit = :old.nit
           AND a.num_pol1 = :old.num_pol1
           AND a.tipo_cotizante = :old.depend_indepen
           AND a.centro_trab = :old.centro_trab
           AND a.ide_nit = pck270_validaciones_grales.fun_identif_tipo_doc( :old.ide_nit );
      EXCEPTION
        WHEN OTHERS THEN
          NULL;
      END;
    END IF;

    IF :old.estado = 'ING'
   AND :new.estado = 'RET' THEN
      BEGIN
        UPDATE /*+ ALL_ROWS */
              c2700355 a
           SET a.estado = :new.estado, a.fecha_fin_cobertura = :new.fecha_fin_cobertura, a.condicion = 'D'
         WHERE a.nit = :old.nit
           AND a.num_pol1 = :old.num_pol1
           AND a.tipo_cotizante = :old.depend_indepen
           AND a.centro_trab = :old.centro_trab
           AND a.ide_nit = pck270_validaciones_grales.fun_identif_tipo_doc( :old.ide_nit );
      EXCEPTION
        WHEN OTHERS THEN
          NULL;
      END;
      -- Jira GD724-3  asigna datos nuevos a type
      Lt_C2700001.COD_CIA            := :new.COD_CIA;
      Lt_C2700001.COD_SECC           := :new.COD_SECC;
      Lt_C2700001.COD_RAMO           := :new.COD_RAMO;
      Lt_C2700001.NUM_POL1           := :new.NUM_POL1;
      Lt_C2700001.CENTRO_TRAB        := :new.CENTRO_TRAB; 
      Lt_C2700001.NIT                := :new.NIT;
      Lt_C2700001.IDE_NIT            := :new.IDE_NIT;
      Lt_C2700001.DEPEND_INDEPEN     := :new.DEPEND_INDEPEN;
      Lt_C2700001.ESTADO             := :new.ESTADO;
      Lt_C2700001.Fecha_Fin_Cobertura := :NEW.FECHA_FIN_COBERTURA;

      -- Jira GD724-3 llama a procedimiento actualiza conciliacion 
      PCK270_CONCILIACIONES_DIA.PRC_TRABAJA_RETIRADO_RETRO(Lt_C2700001);
      
    END IF;
  END;
END trg_au_c2700001;
/
