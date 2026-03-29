CREATE OR REPLACE TRIGGER TRG_SEQ_C1010796
  before insert on C1010796
  for each row
declare
  -- local variables here
  V_secuencia number(17) := 0;
begin
  Begin
     Select seq_C1010796.Nextval
     Into   V_secuencia
     from   dual;
  End;

  :new.secuencia := V_secuencia;

end TRG_SEQ_C1010796;
/
