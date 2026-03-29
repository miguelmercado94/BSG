CREATE OR REPLACE TRIGGER audit_debito
BEFORE INSERT OR DELETE
OR UPDATE of nro_cuenta, MCA_NOVEDAD,
 CAUSA_NOVEDAD,INS_NOVEDAD ON A2000060 
FOR EACH ROW
BEGIN
    IF INSERTING THEN
       INSERT INTO debito_audit
       (OPERACION, NUM_SECU_POL, NUM_END, NRO_CUENTA_VIEJO,
        NRO_CUENTA_NUEVO, FECHA, COD_USR ,
        MCA_NOVEDAD, CAUSA_NOVEDAD, INS_NOVEDAD, MCA_BAJA_CONVENIO,
        FEC_BAJA_CONVENIO, FECHA_NOVEDAD, CAUSA_NOVEDAD_ACH,
        CAUSAL_BAJA_CONVENIO)
       VALUES ('INSERT',:new.num_secu_pol,:new.num_end,:old.nro_cuenta,
               :new.nro_cuenta,sysdate,substr(user,1,15),
               :new.MCA_NOVEDAD, :new.CAUSA_NOVEDAD, :new.INS_NOVEDAD,
               :new.MCA_BAJA_CONVENIO, :new.FEC_BAJA_CONVENIO,
               :new.FECHA_NOVEDAD, :new.CAUSA_NOVEDAD_ACH,
               :new.CAUSAL_BAJA_CONVENIO);
    ELSIF UPDATING  THEN
       INSERT INTO debito_audit
       VALUES ('UPDATE',:old.num_secu_pol,:old.num_end,:old.nro_cuenta,
               :new.nro_cuenta,sysdate,substr(user,1,15),
               :new.MCA_NOVEDAD, :new.CAUSA_NOVEDAD, :new.INS_NOVEDAD,
               :new.MCA_BAJA_CONVENIO, :new.FEC_BAJA_CONVENIO,
               :new.FECHA_NOVEDAD, :new.CAUSA_NOVEDAD_ACH,
               :new.CAUSAL_BAJA_CONVENIO,
               :old.MCA_NOVEDAD, :old.CAUSA_NOVEDAD, :old.INS_NOVEDAD,
               :old.MCA_BAJA_CONVENIO, :old.FEC_BAJA_CONVENIO,
               :old.FECHA_NOVEDAD, :old.CAUSA_NOVEDAD_ACH,
               :old.CAUSAL_BAJA_CONVENIO);
    ELSE
       INSERT INTO debito_audit
       (OPERACION, NUM_SECU_POL, NUM_END, NRO_CUENTA_VIEJO,
        NRO_CUENTA_NUEVO, FECHA, COD_USR )
       VALUES ('DELETE',:old.num_secu_pol,:old.num_end,:old.nro_cuenta,
               :old.nro_cuenta,sysdate,substr(user,1,15));
    END IF;
END;
/
