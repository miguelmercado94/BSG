CREATE OR REPLACE TRIGGER TRG_ACTUALIZA_C2700001_RUAF
AFTER UPDATE
OF SEXO
  ,COD_CARGO
  ,FEC_NACE
  ,FEC_INGRESO
  ,DEPEND_INDEPEN
ON C2700001 
REFERENCING NEW AS NEW OLD AS OLD
FOR EACH ROW
DECLARE
  -------------------------------------------------------------------------------
  -- Objetivo : insertar en tabla interfaz C2700024 creacion modificaciones A.R.P.
  -- Autor    : German Felipe Mu$oz Gomez
  -- Fecha    : Septiembre de 2.006
  -------------------------------------------------------------------------------
  Tipo_d      C2700011.Tdoc_tercero%TYPE;
  Fechanull   DATE;
BEGIN
  BEGIN
    SELECT Tdoc_tercero
      INTO Tipo_d
      FROM C2700011
     WHERE Cod_doc = :old.Ide_nit;
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      Raise_application_error (-20105, 'No encontro la conversion del tipo de documento ');
  END;

  IF UPDATING THEN
    IF :new.Depend_indepen != :old.Depend_indepen
    OR :new.Cod_cargo != :old.Cod_cargo
    OR TO_DATE (TO_CHAR (:new.Fec_nace, 'dd-mon-yyyy'), 'dd-mon-yyyy') !=
         TO_DATE (TO_CHAR (:old.Fec_nace, 'dd-mon-yyyy'), 'dd-mon-yyyy')
    OR :new.Fec_ingreso != :old.Fec_ingreso
    OR :new.Sexo != :old.Sexo
    OR (:new.Cod_cargo IS NOT NULL
    AND :old.Cod_cargo IS NULL) THEN
      BEGIN
        INSERT INTO C2700024 (Cod_cia
                             ,Cod_secc
                             ,Num_pol1
                             ,Centro_trab
                             ,Codigo_novedad
                             ,Tdoc_tercero
                             ,Nit_trabajador
                             ,Sexo
                             ,Fec_nace
                             ,Fecha_afiliacion
                             ,Cod_ocupacion
                             ,Fecha_equipo
                             ,Fecha_creacion
                             ,Cod_usr
                             ,Tipo_cotizante)
        VALUES (:old.Cod_cia
               ,:old.Cod_secc
               ,:old.Num_pol1
               ,:old.Centro_trab
               ,'R03'
               ,Tipo_d
               ,:old.Nit
               ,DECODE (:new.Sexo, :old.Sexo, NULL, :new.Sexo)
               ,DECODE (:new.Fec_nace, :old.Fec_nace, Fechanull, :new.Fec_nace)
               ,DECODE (:new.Fec_ingreso, :old.Fec_ingreso, NULL, :new.Fec_ingreso)
               ,DECODE (:new.Cod_cargo, :old.Cod_cargo, NULL, :new.Cod_cargo)
               ,TRUNC (SYSDATE)
               ,SYSDATE
               ,SUBSTR (USER, 5, 8)
               ,:old.Depend_indepen);
      END;
    END IF;
  END IF;
END Trg_actualiza_c2700001_ruaf;
/
