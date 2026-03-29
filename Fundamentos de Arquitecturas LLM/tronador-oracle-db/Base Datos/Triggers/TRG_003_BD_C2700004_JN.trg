CREATE OR REPLACE TRIGGER Trg_003_Bd_C2700004_Jn
  BEFORE DELETE
  ON C2700004 
  REFERENCING NEW AS NEW OLD AS OLD
  FOR EACH ROW
DECLARE
  Tmpvar            NUMBER;
  /******************************************************************************
     NAME:       Trg_003_Bd_C2700004_Jn
     PURPOSE:
     REVISIONS:
     Ver        Date        Author           Description
     ---------  ----------  ---------------  ------------------------------------
     1.0        04/12/2014      79704401       1. Created this trigger.
     NOTES:
     Automatically available Auto Replace Keywords:
        Object Name:     Trg_003_Bd_C2700004_Jn
        Sysdate:         04/12/2014
        Date and Time:   04/12/2014, 04:25:50 p.m., and 04/12/2014 04:25:50 p.m.
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

  V_Operacion   := 'D';

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
         VALUES (:OLD.Dlg_Secuencia, Vdlgh_Secuencia, V_Operacion, SYSDATE,
                 :OLD.Dlg_Tipo_Doc_Empresa, :OLD.Dlg_Numero_Doc_Empresa, :OLD.Dlg_Tipo_Documento, :OLD.Dlg_Numero_Documento,
                 :OLD.Dlg_Primer_Apellido, :OLD.Dlg_Primero_Nombre, :OLD.Dlg_Segundo_Apellido, :OLD.Dlg_Segundo_Nombre,
                 :OLD.Dlg_Sexo, :OLD.Dlg_Fecha_Nacimiento, :OLD.Dlg_Direccion, :OLD.Dlg_Ciudad_Residencia,
                 :OLD.Dlg_Telefono_Residencia, :OLD.Dlg_Telefono_Movil, :OLD.Dlg_Correo_Electronico, :OLD.Dlg_Ciudad_Nacimiento,
                 :OLD.Dlg_Estado_Civil, :OLD.Dlg_Nacionalidad, :OLD.Dlg_Mca_Tercero, :OLD.Dlg_Secuencia_Tercero,
                 :OLD.Dlg_Observaciones, :OLD.Dlg_Mca_Gestion_Usuario, :OLD.Dlg_Observacion_Gestion, :OLD.Aud_Fecha_Creacion,
                 :OLD.Aud_Usuario_Creacion, :OLD.Aud_Fecha_Actualizacion, :OLD.Aud_Usuario_Actualizacion, :OLD.Aud_Eliminacion,
                 :OLD.Aud_Operacion, :OLD.Dlg_Cod_End, :OLD.Dlg_Sub_Cod_End, :OLD.Dlg_Mca_Para_Envio, :OLD.Dlg_Num_Pol_Cli);
  END;
END Trg_003_Bd_C2700004_Jn;
/
