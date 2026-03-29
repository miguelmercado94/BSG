CREATE OR REPLACE TRIGGER sim_cu_trg_act_usr_nivel_ma
    AFTER UPDATE OF cod_agencia, nivel_aut, cat_user ON g1002700
    FOR EACH ROW
BEGIN
    UPDATE sim_cu_nivel_usuario_mesa x
       SET x.cod_agencia = :new.cod_agencia
          ,x.nivel_aut   = :new.nivel_aut
          ,x.cat_user    = :new.cat_user
     WHERE x.cod_cia = 3
       AND x.cod_secc = 4
       AND x.cod_user_cia = :new.cod_user_cia;
EXCEPTION
    WHEN OTHERS THEN
        dbms_output.put_line('Error en la linea : ' || dbms_utility.format_error_backtrace || '. Posible causa: ' || SQLERRM);
END;
/
