CREATE OR REPLACE TRIGGER TRG_UD_C2990019_JN BEFORE update or delete on C2990019_JN
  for each row
Begin
  RAISE_APPLICATION_ERROR(-20000,'No se puede alterar o borrar la informacion de Journal');
End TRG_UD_C2990019_JN;
/
