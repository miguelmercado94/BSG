CREATE OR REPLACE TRIGGER TRG_NIVEL_CT
  after insert on c2999300  
  for each row
declare
  v_provisoria varchar2(01) := null;
begin
   v_provisoria := 'N';
  begin
    SELECT 'S' 
     into v_provisoria
    from a2000030 x
    where x.num_secu_pol = :new.num_secu_pol_lider
     AND x.num_end = :new.Num_End_Lider
     AND nvl(x.mca_provisorio,'x') = 'S';
    exception when no_data_found then
      v_provisoria := 'N';
  end;  
  if v_provisoria  =  'S'  then
   begin
     update a2000220 t set t.nivel_aut = (select min(x.nivel_aut)
                                           from a2000220 x
                                          where x.num_secu_pol = :NEW.NUM_SECU_POL_LIDER
                                            and     x.num_orden      = :NEW.NUM_END_LIDER)
      where t.num_secu_pol  =  :NEW.NUM_SECU_POL_ANEXO
      and     t.num_orden       =  :NEW.NUM_END_ANEXO
      and     t.cod_rechazo     = 3;
    end;
  end if;  
end TRG_NIVEL_CT;
/
