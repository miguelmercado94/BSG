CREATE OR REPLACE TRIGGER TRG_SEQ_C9999909
  before insert on C9999909
  for each row
declare
  -- local variables here
  V_secuencia number(17) := 0;
begin
  Begin
     Select seq_C9999909.Nextval
     Into   V_secuencia
     from   dual;
  End;

  :new.secuencia := V_secuencia;

end TRG_SEQ_C9999909;
/
