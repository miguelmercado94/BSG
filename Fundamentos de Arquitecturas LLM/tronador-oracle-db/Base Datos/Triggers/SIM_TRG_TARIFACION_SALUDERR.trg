CREATE OR REPLACE TRIGGER SIM_TRG_TARIFACION_SALUDERR
BEFORE INSERT on SIM_TARIFACION_SALUD_ERR
for each row
begin
IF INSERTING THEN
  select sim_seq_tarifacion_saludERR.nextval
    into :new.secuencia
    from dual;
END IF;
end;
/
