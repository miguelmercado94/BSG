CREATE OR REPLACE TRIGGER PIU_A502_PSE_CTA_BCO

/*
   Este trigger hace la auditoria despues de insertar o actualizar la tabla
   de parametros de las cuentas bancarias inscritas por compania
   y producto para el sistema PSE

*/

AFTER INSERT OR UPDATE
ON A502_PSE_CTA_BCO
REFERENCING OLD AS OLD NEW AS NEW
FOR EACH ROW
DECLARE
   merror                     varchar2(500) := null;
   hora_                      varchar2(8)   := null;

   Cursor hora is
    Select to_char(sysdate,'HH24:MI:SS') la_hora
      from dual;
BEGIN
   For h in hora loop
       hora_ := h.la_hora;
   end loop;
   Begin
     insert into A502_PSE_CTA_BCO_HIST
     (COD_CIA                     ,
      COD_SECC                    ,
      NRO_CUENTA                  ,
      NRO_CUENTA_ANT              ,
      ESTADO                      ,
      ESTADO_ANTERIOR             ,
      USUARIO                     ,
      FECHA                       ,
      HORA                        ) values
     (:NEW.cod_cia                ,
      :NEW.cod_secc               ,
      :NEW.NRO_CUENTA             ,
      :OLD.NRO_CUENTA             ,
      :NEW.ESTADO                 ,
      :OLD.ESTADO                 ,
      USER                        ,
      trunc(SYSDATE)              ,
      hora_                       );
   Exception
   When others then
      merror := sqlerrm ||' insertando en la A502_PSE_CTA_BCO_HIST';
      RAISE_APPLICATION_ERROR( -20008, merror );
   End;
END;
/
