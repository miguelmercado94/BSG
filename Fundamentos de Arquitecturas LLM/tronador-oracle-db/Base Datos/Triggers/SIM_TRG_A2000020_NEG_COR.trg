CREATE OR REPLACE TRIGGER SIM_TRG_A2000020_NEG_COR
  before update Of MCA_VIGENTE Or Insert On A2000020
   for each row
WHEN (new.Cod_Campo = 'NEG_CORPORA')
Begin
 
     If :new.Mca_Vigente = 'S'  Then
        DELETE SIM_Negocios_corporativos
        WHERE Num_secu_pol = :new.Num_Secu_Pol;
        If  :new.Valor_Campo ='S' THEN
   
            INSERT INTO SIM_Negocios_corporativos(Num_secu_pol)
            VALUES (:new.Num_Secu_Pol);
        End If;
     END IF;
  
      
end SIM_TRG_A2000020_NEG_COR;
/
