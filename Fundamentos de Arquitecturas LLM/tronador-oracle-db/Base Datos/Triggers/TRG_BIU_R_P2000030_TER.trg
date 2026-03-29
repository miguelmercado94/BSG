CREATE OR REPLACE TRIGGER Trg_Biu_R_P2000030_Ter
  BEFORE INSERT OR UPDATE OF Nro_Documto, Tdoc_Tercero, Sec_Tercero
  ON P2000030 
  REFERENCING NEW AS NEW OLD AS OLD
  FOR EACH ROW
DECLARE
   V_Primera        Naturales.Primer_Apellido%TYPE;
  V_Segundoa       Naturales.Segundo_Apellido%TYPE;
  V_Primern        Naturales.Primer_Nombre%TYPE;
  V_Segundon       Naturales.Segundo_Nombre%TYPE;
  V_Razon_Social   Juridicos.Razon_Social%TYPE;
  V_Tipo           VARCHAR2 (1);
  V_Desctipo       VARCHAR2 (200);
  V_Coderr         C1991300.Cod_Error%TYPE;
  V_Msgerr         C1991300.Msg_Error%TYPE;
BEGIN
  IF INSERTING
  THEN
    IF :NEW.Nro_Documto IS NOT NULL
   AND :NEW.Tdoc_Tercero IS NOT NULL
    THEN
      BEGIN
      --  :NEW.Sec_Tercero   := NULL;
       If :New.Sec_Tercero Is Null Then
        PCK999_TERCEROS.Prc_Datosd_Tercero (:NEW.Nro_Documto, :NEW.Tdoc_Tercero, :NEW.Sec_Tercero,
                                            V_Primera, V_Segundoa, V_Primern,
                                            V_Segundon, V_Razon_Social, V_Tipo,
                                            V_Desctipo);
       End If; --si la secuencia tiene valor no se hace nada
      EXCEPTION
        WHEN OTHERS
        THEN
          BEGIN
            V_Coderr   := SQLCODE;
            V_Msgerr   := SQLERRM;
          EXCEPTION
            WHEN DUP_VAL_ON_INDEX
            THEN
              NULL;
          END;
      END;
    ELSE
      IF :NEW.Tdoc_Tercero IS NULL
      OR :NEW.Sec_Tercero IS NULL
      THEN
        BEGIN
          :NEW.Sec_Tercero   := NULL;
          PCK999_TERCEROS.Prc_Datosd_Tercero (:NEW.Nro_Documto, :NEW.Tdoc_Tercero, :NEW.Sec_Tercero,
                                              V_Primera, V_Segundoa, V_Primern,
                                              V_Segundon, V_Razon_Social, V_Tipo,
                                              V_Desctipo);
        EXCEPTION
          WHEN OTHERS
          THEN
            BEGIN
              V_Coderr   := SQLCODE;
              V_Msgerr   := SQLERRM;
            EXCEPTION
              WHEN DUP_VAL_ON_INDEX
              THEN
                NULL;
            END;
        END;
      END IF;
    END IF;
  ELSE
    DECLARE
      Vtipo   VARCHAR2 (3) := NVL (:NEW.Tdoc_Tercero, :OLD.Tdoc_Tercero);
      Vnro    NUMBER (16) := NVL (:NEW.Nro_Documto, :OLD.Nro_Documto);
      Vsec    NUMBER (13) := NVL (:NEW.Sec_Tercero, :OLD.Sec_Tercero);
    BEGIN
      Vsec                := NULL;
      PCK999_TERCEROS.Prc_Datosd_Tercero (Vnro, Vtipo, Vsec,
                                          V_Primera, V_Segundoa, V_Primern,
                                          V_Segundon, V_Razon_Social, V_Tipo,
                                          V_Desctipo);
      :NEW.Nro_Documto    := Vnro;
      :NEW.Tdoc_Tercero   := Vtipo;
      :NEW.Sec_Tercero    := Vsec;
    EXCEPTION
      WHEN OTHERS
      THEN
        BEGIN
          V_Coderr   := SQLCODE;
          V_Msgerr   := SQLERRM;
        EXCEPTION
          WHEN DUP_VAL_ON_INDEX
          THEN
            NULL;
        END;
    END;
  END IF;
EXCEPTION
  WHEN Others  Then
    V_Coderr   := SQLCODE;
    V_Msgerr   := SQLERRM;
END Trg_Biu_R_P2000030_Ter;
/
