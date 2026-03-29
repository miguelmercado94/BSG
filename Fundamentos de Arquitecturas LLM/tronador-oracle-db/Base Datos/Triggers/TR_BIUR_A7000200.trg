CREATE OR REPLACE TRIGGER TR_BIUR_A7000200
  BEFORE  INSERT OR  UPDATE ON A7000200 for each row
Declare
  varDescCausa a7000200.desc_causa%TYPE;

  BEGIN
    IF INSERTING OR UPDATING THEN
       IF :NEW.COD_CIA IN (2,3) THEN
          BEGIN
            SELECT X.Desc_Causa
              INTO varDescCausa
              FROM A7000200 X
             WHERE X.TIPO_CAUSA = :NEW.TIPO_CAUSA
               AND X.COD_CAUSA = :NEW.COD_CAUSA
               AND X.COD_CIA <> :new.Cod_Cia
               AND x.cod_cia IN (2,3);

             IF varDescCausa IS NOT NULL AND varDescCausa <> :new.Desc_Causa THEN
                raise_application_error(-20200, 'El código de causa debe tener la misma descripción para ambas Cias. Cau: '||:NEW.Cod_Causa||' Desc: '||:new.Desc_Causa);
             END IF;  
          EXCEPTION
            WHEN NO_DATA_FOUND THEN NULL;
            WHEN too_many_rows THEN
                 raise_application_error(-20201, 'Codigo de causa ya esta siendo utilizado para compañías 2 y 3');
            WHEN OTHERS THEN 
              raise_application_error(-20202,'Error en TR_BIUR_A7000200 '||SQLERRM);
          END;
       END IF;
    END IF;
  END;
/
