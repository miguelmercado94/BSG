CREATE OR REPLACE TRIGGER TR_BIUR_A7000220
  BEFORE  INSERT OR  UPDATE ON A7000220 for each row
Declare
  varDescConsec a7000220.desc_cons%type := NULL;
  BEGIN
    IF INSERTING OR UPDATING THEN
      IF :NEW.COD_CIA IN (2,3) THEN
         BEGIN
            SELECT X.Desc_Cons
              INTO varDescConsec
              FROM A7000220 X
             WHERE X.COD_CONS = :NEW.COD_CONS
               AND X.COD_CIA <> :new.Cod_Cia 
               AND X.COD_CIA IN (2,3);

             IF varDescConsec IS NOT NULL AND varDescConsec <> :new.Desc_Cons THEN
                raise_application_error(-20200, 'El código de consecuencia debe tener la misma descripción para ambas Cias. Consec: '||:NEW.COD_CONS||' Desc: '||:new.Desc_Cons);
             END IF;  
         EXCEPTION
            WHEN NO_DATA_FOUND THEN NULL;
            WHEN TOO_MANY_ROWS THEN
                 raise_application_error(-20222, 'Codigo de Consecuencia ya esta siendo utilizado en ambas compañías');
            WHEN OTHERS THEN 
                 raise_application_error(-20222, 'Error en TR_BIUR_A7000220 '||SQLERRM);
         END;
      END IF;
    END IF;
  END;
/
