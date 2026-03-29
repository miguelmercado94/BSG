CREATE OR REPLACE TRIGGER SIM_TRG_TARIFACION_SALUD
BEFORE INSERT on SIM_TARIFACION_SALUD
for each row
begin
IF INSERTING THEN
  select sim_seq_tarifacion_salud.nextval
    into :new.secuencia
    from dual;
END IF;
end;
/
