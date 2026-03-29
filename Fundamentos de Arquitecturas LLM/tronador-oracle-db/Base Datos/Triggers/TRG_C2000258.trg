CREATE OR REPLACE TRIGGER TRG_C2000258
  before insert or update on c2000258
  FOR EACH ROW
WHEN (new.for_cobro is null)
declare
  -- local variables here
begin
 begin
 Select for_cobro into :new.for_cobro
     from a2000030 a
  where num_secu_pol = :new.num_secu_pol and
        num_end = (select max(num_end) from a2000030
                    where num_Secu_pol = a.num_Secu_pol
                     and num_end <= :new.num_end
                    );
 exception when no_data_found then
    :new.for_cobro := 'XX';
 end;
 if :new.for_cobro = 'DB' then
     Begin
     select canal_descto into :new.canal_descto
      from a2000060 a
    where num_secu_pol = :new.num_secu_pol and
          num_end = (select max(num_end) from a2000060
                      where num_Secu_pol = a.num_Secu_pol
                       and num_end <= :new.num_end
                      );
    exception when no_data_found then
       :new.canal_descto := 0;
    end;
 end if;

end TRG_C2000258;
/
