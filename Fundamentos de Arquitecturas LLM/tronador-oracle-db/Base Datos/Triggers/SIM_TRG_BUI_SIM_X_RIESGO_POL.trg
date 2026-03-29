CREATE OR REPLACE TRIGGER SIM_TRG_BUI_SIM_X_RIESGO_POL
BEFORE Update Or Insert ON SIM_X_RIESGO_POLIZA REFERENCING NEW AS NEW OLD AS OLD
FOR EACH Row
Declare
l_BIEN   Number;
l_OPCION Number;
l_dato   varchar2(1);
BEGIN
  select '' into l_dato from x2000030
  where num_secu_pol = :new.Num_Secu_Pol
  and cod_secc in (922,923);
 If :new.sim_bien_asegurado Is Null Then 
    Begin 
     :new.sim_bien_asegurado :=  fun_rescata_a2000020('BIEN_ASEGURADO',:new.Num_Secu_Pol, :new.Cod_Ries);
    Exception When Others Then 
       Begin 
        :new.sim_bien_asegurado:=  fun_rescata_X2000020('BIEN_ASEGURADO',:new.Num_Secu_Pol, :new.Cod_Ries);
       Exception When Others Then Null;
       End;
    End;
 End If;
 If :new.Sim_Opcion Is Null Then 
    Begin 
      :new.Sim_Opcion:= fun_rescata_a2000020('API_OPCION',:new.Num_Secu_Pol, :new.Cod_Ries);
    Exception When Others Then 
       Begin 
        :new.Sim_Opcion:=  fun_rescata_X2000020('API_OPCION',:new.Num_Secu_Pol, :new.Cod_Ries);
       Exception When Others Then Null;
       End;
    End;
 End If;
 Exception When Others Then Null;
END;
/
