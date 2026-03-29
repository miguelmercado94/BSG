CREATE OR REPLACE TRIGGER audit_trans
BEFORE DELETE ON X2000040 
FOR EACH ROW
WHEN (old.cod_cob = 999)
BEGIN
    declare
        numend number;
    begin
        select num_end into numend from a2000030
        where num_secu_pol = :old.num_secu_pol and
              num_end = 0 and fecha_emi = trunc(sysdate);
         exception when no_data_found then goto fin;
                   when too_many_rows then null;
    end;
     insert into audit_trans
     values (:old.num_secu_pol,substr(user,5,8));
    <<fin>>
     null;
END;
/
