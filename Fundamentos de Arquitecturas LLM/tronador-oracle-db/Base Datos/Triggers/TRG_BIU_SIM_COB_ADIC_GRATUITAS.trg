CREATE OR REPLACE TRIGGER TRG_BIU_SIM_COB_ADIC_GRATUITAS
BEFORE INSERT OR UPDATE ON SIM_COB_ADICIONALES_GRATUITAS FOR EACH ROW
/*  Modificado   : Rolphy Quintero - Asesoftware - Claudia Monica Peña
    Fecha        : Marzo 19 de 2019 - Mantis 44444
    Descripción  : Se adicionan las columnas COD_CIA, COD_SECC y COD_RAMO
                   en la tabla SIM_COB_ADICIONALES_GRATUITAS. También se
                   adiciona la validación exista el producto en la tabla
                   SIM_PRODUCTOS.
    
    Modificado   : Rolphy Quintero - Asesoftware - Claudia Monica Peña
    Fecha        : Marzo 11 de 2019 - Mantis 44444
    Descripción  : Se crea el trigger, para validar la cobertura ingresada en
                   la tabla SIM_COB_ADICIONALES_GRATUITAS, debe existir en la
                   tabla A1002100, aplica para INSERT y UPDATE nada más. */
DECLARE
  vl_existe VARCHAR2(1);
BEGIN
  Begin
    SELECT 'S'
      INTO vl_existe
      FROM SIM_PRODUCTOS PRO
     WHERE PRO.COD_CIA = :NEW.COD_CIA
       AND PRO.COD_SECC = :NEW.COD_SECC
       AND PRO.COD_PRODUCTO = :NEW.COD_RAMO
       AND ROWNUM <= 1;
    Begin
      SELECT 'S'
        INTO vl_existe
        FROM A1002100 C
       WHERE C.COD_CIA = :NEW.COD_CIA
         AND C.COD_RAMO = :NEW.COD_RAMO
         AND C.COD_COB = :NEW.COD_COB
         AND ROWNUM <= 1;
    Exception
      When NO_DATA_FOUND Then
        raise_application_error(-20001,'La cobertura: '||:NEW.COD_COB||
        ', cod_cia: '||:NEW.COD_CIA||', cod_ramo: '||:NEW.COD_RAMO||
        ', no esta asociada en la tabla A1002100');
    End;
  Exception
    When NO_DATA_FOUND Then
      raise_application_error(-20001,'No existe producto en la tabla'||
      ' SIM_PRODUCTOS, cod_cia: '||:NEW.COD_CIA||
      ', cod_secc: '||:NEW.COD_SECC||', cod_ramo: '||:NEW.COD_RAMO);
  End;
END TRG_BIU_SIM_COB_ADIC_GRATUITAS;
/
