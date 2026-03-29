CREATE OR REPLACE TRIGGER "TRG_SEQ_SIM_LOG_GENERAL_PARAM" 
   before insert on "OPS$PUMA"."SIM_LOG_GENERAL_PARAM" 
   for each row
begin

    if ( :NEW.MODULE is null and :NEW.SESSION_USER is null and :NEW.IP_ADDRESS is null and :NEW.SESSIONID is null and :NEW.OS_USER is null ) then
        raise_application_error (-20000, 'Se requiere un valor para los campos SESSION_USER, IP_ADDRESS, SESSIONID o OS_USER');
    end if;
    
    if ( :NEW.INICIO > :NEW.FIN ) then
        raise_application_error (-20000, 'La fecha de INICIO no puede ser mayor que la fecha FIN');
    end if;
    
    if ( sysdate > :NEW.INICIO ) then
        :NEW.INICIO := sysdate;
    end if;
    
    if ( sysdate >= :NEW.FIN ) then
        raise_application_error (-20000, 'La fecha de FIN no puede ser menor o igual que la fecha de sistema');
    end if;
    
    if ( (:NEW.FIN - sysdate)*24 > 1 ) then
        raise_application_error (-20000, 'La fecha de FIN no puede ser mayor a una hora en el futuro');
    end if;
    
    :NEW.OS_USER        := lower(:NEW.OS_USER);
    
    if inserting then 
        :NEW.HABILITADO := 'S';
        select SEQ_SIM_LOG_GENERAL_PARAM.nextval into :NEW."SECUENCIA" from dual; 
    end if; 
end;
/
