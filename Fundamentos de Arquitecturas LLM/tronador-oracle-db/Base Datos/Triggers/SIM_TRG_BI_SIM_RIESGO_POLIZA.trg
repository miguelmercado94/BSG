CREATE OR REPLACE TRIGGER SIM_TRG_BI_SIM_RIESGO_POLIZA
BEFORE Insert ON SIM_RIESGO_POLIZA REFERENCING NEW AS NEW OLD AS OLD
FOR EACH Row
Declare
l_BIEN   Number;
l_OPCION Number;
BEGIN
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
