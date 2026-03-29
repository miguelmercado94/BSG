CREATE OR REPLACE TRIGGER "TRG_SEQ_G2000200"
  before insert on G2000200
  for each row
declare
 -- local variables here
  V_secuencia number(17) := 0;
begin
  Begin
     Select SEQ_G2000200.Nextval
     Into   V_secuencia
     from   dual;
  End;
:new.secuencia := V_secuencia;
end TRG_SEQ_G2000200;
/
