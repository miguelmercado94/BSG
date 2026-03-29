CREATE OR REPLACE TRIGGER SIM_TRG_A2000220_DEL
After DELETE ON A2000220 FOR EACH ROW
Declare
    V_numsecupol  number;
Begin
     if  DELETING Then
       Begin
             Update sim_seg_ctroles_tecnicos ssct
             Set    ssct.estado = 'I'
             Where  ssct.num_secu_pol = :old.num_secu_pol
             And    ssct.num_end      = :old.num_orden;
       End;
     End If;
exception
  when others then null;
end SIM_TRG_A2000220_DEL;
/
