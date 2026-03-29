CREATE OR REPLACE TRIGGER Trg_002_Aiu_C2700004_Jn
  AFTER INSERT OR UPDATE
  ON C2700004 
  REFERENCING NEW AS NEW OLD AS OLD
  FOR EACH ROW
DECLARE
  Tmpvar            NUMBER;
  /******************************************************************************
     NAME:       TRG_002_AIU_C2700004_JN
     PURPOSE:

     REVISIONS:
     Ver        Date        Author                              Description
     ---------  ----------  ----------------------------------  ------------------------------------
     1.0        03/12/2014  WILSON FERNANDO lOPEZ COLMENARES    1. Created this trigger.
     1.0.1      03/12/2014  WILSON FERNANDO lOPEZ COLMENARES    1. GUARDA LOS MOVIMIENTOS DE LA TABLA C2700004

     NOTES:

     Automatically available Auto Replace Keywords:
        Object Name:     TRG_002_AIU_C2700004_JN
        Sysdate:         03/12/2014
        Date and Time:   03/12/2014, 03:45:41 p.m., and 03/12/2014 03:45:41 p.m.
        Username:        79704401 (set in TOAD Options, Proc Templates)
        Table Name:      C2700004 (set in the "New PL/SQL Object" dialog)
        Trigger Options:  (set in the "New PL/SQL Object" dialog)
  ******************************************************************************/
  V_Operacion       CHAR (1);
  Vdlgh_Secuencia   C2700009.Dlgh_Secuencia%TYPE;
BEGIN

  BEGIN
    SELECT /*+ ALL_ROWS */
           NVL (MAX (A.Dlgh_Secuencia) + 1, 1)
      INTO Vdlgh_Secuencia
      FROM C2700009 A;
  END;

  IF UPDATING
  THEN
    V_Operacion   := 'M';
  ELSIF INSERTING
  THEN
    V_Operacion   := 'C';
  END IF;

  BEGIN
    INSERT INTO C2700009 (Dlg_Secuencia, Dlgh_Secuencia, Dlgh_Jn_Tipo_Operacion, Dlgh_Jn_Fecha,
                          Dlgh_Tipo_Doc_Empresa, Dlgh_Numero_Doc_Empresa, Dlgh_Tipo_Documento, Dlgh_Numero_Documento,
                          Dlgh_Primer_Apellido, Dlgh_Primero_Nombre, Dlgh_Segundo_Apellido, Dlgh_Segundo_Nombre,
                          Dlgh_Sexo, Dlgh_Fecha_Nacimiento, Dlgh_Direccion, Dlgh_Ciudad_Residencia,
                          Dlgh_Telefono_Residencia, Dlgh_Telefono_Movil, Dlgh_Correo_Electronico, Dlgh_Ciudad_Nacimiento,
                          Dlgh_Estado_Civil, Dlgh_Nacionalidad, Dlgh_Mca_Tercero, Dlgh_Secuencia_Tercero,
                          Dlgh_Observaciones, Dlgh_Mca_Gestion_Usuario, Dlgh_Observacion_Gestion, Aud_Fecha_Creacion,
                          Aud_Usuario_Creacion, Aud_Fecha_Actualizacion, Aud_Usuario_Actualizacion, Aud_Eliminacion,
                          Aud_Operacion, Dlgh_Cod_End, Dlgh_Sub_Cod_End, Dlgh_Mca_Para_Envio, Dlgh_Num_Pol_Cli)
         VALUES (:NEW.Dlg_Secuencia, Vdlgh_Secuencia, V_Operacion, SYSDATE,
                 :NEW.Dlg_Tipo_Doc_Empresa, :NEW.Dlg_Numero_Doc_Empresa, :NEW.Dlg_Tipo_Documento, :NEW.Dlg_Numero_Documento,
                 :NEW.Dlg_Primer_Apellido, :NEW.Dlg_Primero_Nombre, :NEW.Dlg_Segundo_Apellido, :NEW.Dlg_Segundo_Nombre,
                 :NEW.Dlg_Sexo, :NEW.Dlg_Fecha_Nacimiento, :NEW.Dlg_Direccion, :NEW.Dlg_Ciudad_Residencia,
                 :NEW.Dlg_Telefono_Residencia, :NEW.Dlg_Telefono_Movil, :NEW.Dlg_Correo_Electronico, :NEW.Dlg_Ciudad_Nacimiento,
                 :NEW.Dlg_Estado_Civil, :NEW.Dlg_Nacionalidad, :NEW.Dlg_Mca_Tercero, :NEW.Dlg_Secuencia_Tercero,
                 :NEW.Dlg_Observaciones, :NEW.Dlg_Mca_Gestion_Usuario, :NEW.Dlg_Observacion_Gestion, :NEW.Aud_Fecha_Creacion,
                 :NEW.Aud_Usuario_Creacion, :NEW.Aud_Fecha_Actualizacion, :NEW.Aud_Usuario_Actualizacion, :NEW.Aud_Eliminacion,
                 :NEW.Aud_Operacion, :NEW.Dlg_Cod_End, :NEW.Dlg_Sub_Cod_End, :NEW.Dlg_Mca_Para_Envio, :NEW.Dlg_Num_Pol_Cli);
  END;
END Trg_002_Aiu_C2700004_Jn;
/
