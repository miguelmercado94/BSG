CREATE OR REPLACE TRIGGER trg_estado_ct
                  before INSERT ON a2000220
                  FOR EACH ROW
BEGIN
 if :new.cod_rechazo = 3 then
  :new.estado := 'P' ;
end if;
END;
/
