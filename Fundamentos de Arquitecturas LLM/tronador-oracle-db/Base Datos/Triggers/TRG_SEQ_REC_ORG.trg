CREATE OR REPLACE TRIGGER TRG_SEQ_REC_ORG
  before insert on SIM_CARGUE_RECAUDO_ORG
  for each row
declare
  -- local variables here
  V_secuencia number(17) := 0;
begin
  Begin
     Select SEQ_REC_ORG.Nextval
     Into   V_secuencia
     from   dual;
  End;

  :new.id_recaudo_org := V_secuencia;

end TRG_SEQ_REC_ORG;
/
