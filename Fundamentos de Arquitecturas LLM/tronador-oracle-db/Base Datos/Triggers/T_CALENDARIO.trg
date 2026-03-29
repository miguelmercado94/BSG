CREATE OR REPLACE TRIGGER t_calendario
after insert or  UPDATE ON calendario
FOR EACH ROW
BEGIN
    declare
       una_actualizacion  varchar2(6) := null;
     begin
       if inserting then
          una_actualizacion := 'INSERT';
       elsif updating then
         una_actualizacion := 'UPDATE';
       end if;
      if (nvl(:old.tipo_dia,'M') <> nvl(:new.tipo_dia,'M'))
                             or
                 (:old.fechA  <> :NEW.FECHA)  then
             insert into calendario_historico
                                   (cod_cia,
                                    fecha,
                                    tipo_dia,
                                    cierre,
                                    actualizacion,
                                    cod_user,
                                    fecha_modificacion)
            values
                                  (:old.cod_cia,
                                   :old.fecha,
                                   :old.tipo_dia,
                                   :old.cierre,
                                   una_actualizacion,
                                   substr(user,5,8),
       to_date(to_char(sysdate,'yyyymmdd hh24miss'),'yyyymmdd hh24miss') )
      ;
      end if;
      END;
END;
/
