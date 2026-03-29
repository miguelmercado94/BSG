CREATE OR REPLACE TRIGGER ACTUALIZA_CONTROLES_TECNICOS
before insert or
      update of desc_error
   on G2000210
for each row
-----------------------------------------------------------------------------
-- Objetivo : insertar o actualizar los controles tecnicos  en el sistema de
--            informacion de SISALUD
-- Autor    : Elsa Victoria Duque Gomez
-- Fecha    : febrero 24 de 2000
-------------------------------------------------------------------------------

declare
  vn_valida NUMBER;
Begin
  if INSERTING THEN

      select COUNT(5)

        into vn_valida
      from tipos_control
      where tct_codigo = :new.cod_error;

      IF vn_valida = 0 THEN

        begin
          insert into tipos_control(tct_codigo
                                   ,tct_descripci
                                   ,tct_tipo
                                   )
                             values(:new.cod_error
                                   ,:new.desc_error
                                   ,'1' );
          exception when others then
            dbms_output.put_line(sqlerrm);
        end;
    END IF;
  elsif UPDATING then
    if :new.desc_error != :old.desc_error then
      update tipos_control
      set tct_descripci = :new.desc_error
      where tct_codigo  = :old.cod_error;
    end if;
  end if;
End actualiza_controles_tecnicos;
/
