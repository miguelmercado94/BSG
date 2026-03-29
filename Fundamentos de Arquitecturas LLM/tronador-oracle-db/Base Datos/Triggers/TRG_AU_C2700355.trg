CREATE OR REPLACE TRIGGER Trg_Au_C2700355
  AFTER UPDATE OF Num_Pol1, Ide_Nit, Nit, Tipo_Cotizante, Fecha_Fin_Cobertura, ESTADO, Fecha_Inicial, Fecha_Final, Condicion
  ON C2700355
  REFERENCING NEW AS NEW OLD AS OLD
  FOR EACH ROW
DECLARE
  Tmpvar  NUMBER;
/******************************************************************************
   NAME:       TRG_AU_C2700355
   PURPOSE:

   REVISIONS:
   VER        DATE        AUTHOR           DESCRIPTION
   ---------  ----------  ---------------  ------------------------------------
   1.0        12/04/2011  INTASI32         1. CREATED THIS TRIGGER.
   1.1        04/02/2012  INTASI32         1. ACTUALIZA LA POLIZA EN LA TABLA C2700356
   1.2        16/06/2017  DIANA CAROLINA   1. SE RETIRA EL CAMPO CONDICION PARA REQUERIMIENTO MANTIS 54851 Y SE AGREGAN LOS NUEVOS
                          AMAYA				  CAMPOS EN EL INSERT C2700360
   1.3        22/12/2017  DIANA AMAYA      1. SE AGREGA DE NUEVO EL CAMPO CONDICION PARA EL REGISTRO DE HISTORICOS                                         
   1.4        22/12/2017  DIANA AMAYA      1. SE RETIRA EL CAMPO DE CENTRO DE TRABAJO DE LAS OPCIONES DEL UPDATE PARA EVITAR
                                              ACTUALIZAR EL HISTORICO DE LA TABLA C2700360
   1.5        20/03/2018  DIANA AMAYA      1. EL USUARIO DE MODIFICACION SE TOMARA COMO EL USUARIO QUE ACTUALIZA EL REGISTRO EN LA TABLA C2700355    
   1.6        17/01/2023  JAVIER PEREZ     1. SI SE ANULA COBERTURA, NO SE ACTIVA EL TRIGGER. LA EDICIÓN INSERTA REGISTROS EN ESTADO INACTIVO AL HISTORICO
   NOTES:

   AUTOMATICALLY AVAILABLE AUTO REPLACE KEYWORDS:
      OBJECT NAME:     TRG_AU_C2700355
      SYSDATE:         12/04/2011
      DATE AND TIME:   12/04/2011, 08:10:57 A.M., AND 12/04/2011 08:10:57 A.M.
      USERNAME:        79704401 (SET IN TOAD OPTIONS, PROC TEMPLATES)
      TABLE NAME:      C2700355 (SET IN THE "NEW PL/SQL OBJECT" DIALOG)
      TRIGGER OPTIONS:  (SET IN THE "NEW PL/SQL OBJECT" DIALOG)
******************************************************************************/
BEGIN
  IF :OLD.Num_Pol1 = :NEW.Num_Pol1 THEN
    IF :NEW.Condicion <> 'E' THEN
        BEGIN
          INSERT INTO C2700360(Num_Pol1, Ide_Nit, Nit, Tipo_Cotizante, Centro_Trab
                       ,ESTADO, Sec_Tercero, Fecha_Inicial, Fecha_Final, Fecha_Creacion
                       ,Usuario_Creacion, Fecha_Modifica, Usuario_Modifica, Condicion,Tipo_Trn_Cob,Secuencia_Cob )
               VALUES ( :OLD.Num_Pol1, :OLD.Ide_Nit, :OLD.Nit, :OLD.Tipo_Cotizante, :OLD.Centro_Trab
                       ,:OLD.ESTADO, :OLD.Sec_Tercero, :OLD.Fecha_Inicial, :OLD.Fecha_Final, :OLD.Fecha_Creacion
                       ,:OLD.Usuario_Creacion, SYSDATE,:NEW.USUARIO_CREACION, 'D', :OLD.Tipo_Trn_Cob, :OLD.Secuencia_Cob );
        EXCEPTION
          WHEN OTHERS THEN
            RAISE_APPLICATION_ERROR (-20000, 'Error general ejecutando trigger');
        END;
    END IF;
  ELSIF :OLD.Num_Pol1 <> :NEW.Num_Pol1
    AND :OLD.Condicion = 'A' THEN
    /*****************************************************************************************************************************************************
     * ENGINEER : WILSON FERNANDO LOPEZ COLMENARES                                             DATE CREATED: 04/02/2012  SEQUENCE REQUIREMENT :SRS000591 *
     * DESCRIPTION : SE ACTUALIZA LA POLIZA EN LA TABLA QUE CORRESPONDE A LAS EMPRESAS QUE NO DEBEN DESACTIVARSE                                         *
    *****************************************************************************************************************************************************/
    BEGIN
      UPDATE /*+ ALL_ROWS */
            C2700356 A
         SET A.Num_Pol1 = :NEW.Num_Pol1
       WHERE A.Num_Pol1 = :OLD.Num_Pol1
         AND A.Mca_Trmin_Condicn = 'N';
    EXCEPTION
      WHEN OTHERS THEN
         RAISE_APPLICATION_ERROR (-20000, 'Error general ejecutando trigger'); 
    END;
  END IF;
END Trg_Au_C2700355;
/
