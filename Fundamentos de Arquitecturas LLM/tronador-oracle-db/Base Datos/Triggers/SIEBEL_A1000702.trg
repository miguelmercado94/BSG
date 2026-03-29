CREATE OR REPLACE TRIGGER SIEBEL_A1000702
AFTER
INSERT or UPDATE or DELETE on "OPS$PUMA"."A1000702"
for each row
declare
woperacion       varchar2(3)  := null;
wurl                      varchar2(20) := '130.100.1.101';
winstancia          varchar2(20) := 'tron';
westado                             varchar2(20) := 'PENDIENTE';
wtabla                  varchar2(20) := null;
var_x                    varchar2(1)  := null;
wproceso           varchar2(20) := null;
westado_ope   varchar2(20) := null;
wusuario             varchar2(16) := null;
wsecuencia_ope             number(10);
wsecuencia_evt              number(10);
wcodigo                              number(4);
wfecha_i             date;
wfecha_f            date;
NO_CONEXION               Exception;
PRAGMA                            Exception_init(NO_CONEXION,-2068);
begin
   /*....se obtiene la fecha y hora inicial del proceso....*/
   select sysdate
   into   wfecha_i
   from   dual;
   /*....se obtiene la secuencia a grabar en la tabla de eventos....*/
   begin
     select int_sc_eventos_01.nextval
     into   wsecuencia_evt
     from   dual;
   exception
     when others then wsecuencia_evt := 0;
   end;
   /*....se obtiene la secuencia a grabar en la tabla de operaciones....*/
   begin
     select int_sc_operaciones_01.nextval
     into   wsecuencia_ope
     from   dual;
   exception
     when others then wsecuencia_ope := 0;
   end;
   /*....se determino el tipo de operacion realizado....*/
   if inserting then
      wcodigo      := :new.cod_agencia;
      woperacion   := 'INS';
      wtabla       := 'A1000702';
      wproceso     := 'INSERCION';
      westado_ope  := 'ACTIVA';
      wusuario     := :new.cod_usr;
   end if;
   if updating then
      wcodigo      := :new.cod_agencia;
      woperacion   := 'ACT';
      wtabla       := 'A1000702';
      wproceso     := 'ACTUALIZACION';
      westado_ope  := 'ACTIVA';
      wusuario     := :new.cod_usr;
   end if;
   if deleting then
      begin
        select 'X'
        into   var_x
        from   a1000702F
        where  cod_agencia = :old.cod_agencia;
        wcodigo      := :old.cod_agencia;
        woperacion   := 'DEL';
        wtabla       := 'A1000702';
        wproceso     := 'FUSION';
        westado_ope  := 'CERRADA';
        wusuario     := :old.cod_usr;
      exception
        when no_data_found then
             wcodigo      := :old.cod_agencia;
             woperacion   := 'DEL';
             wtabla       := 'A1000702';
             wproceso     := 'BORRADO';
             westado_ope  := 'CERRADA';
             wusuario     := :old.cod_usr;
             var_x        := null;
        when others then
             null;
      end;
   end if;
   /*....se obtiene la fecha y hora final del proceso....*/
   select sysdate
   into   wfecha_f
   from   dual;
   /*....insercion en tabla de eventos....*/
   begin
     insert into int_tb_eventos_01
     values(wsecuencia_evt,
            wurl,
            winstancia,
            wproceso,
            westado,
            wfecha_i,
            wfecha_f,
            wusuario);
     /*....insercion en tabla de operaciones....*/
     begin
       insert into int_tb_operaciones_01
       values(wsecuencia_evt,
              wsecuencia_ope,
              wcodigo,
              woperacion,
              wtabla,
              westado_ope,
              wfecha_f);
     Exception
        when NO_CONEXION then
             insert into conexion_tronsieb
             values('Oficinas...Error al conectarse a siebel',sysdate);
        when others then
             insert into conexion_tronsieb
             values('Oficinas...Error al insertar en siebel',sysdate);
     end;
   Exception
      when NO_CONEXION then
             insert into conexion_tronsieb
             values('Oficinas...Error al conectarse a siebel',sysdate);
      when others then
             insert into conexion_tronsieb
             values('Oficinas...Error al insertar en siebel',sysdate);
   end;
   if var_x is not null then
     /*....se obtiene la secuencia a grabar en la tabla de operaciones....*/
     begin
       select int_sc_operaciones_01.nextval
       into   wsecuencia_ope
       from   dual;
     exception
       when others then wsecuencia_ope := 0;
     end;
     begin
       woperacion  := 'INS';
       wtabla      := 'A1000702F';
       westado_ope := 'FUSIONADA';
       wusuario    := :new.cod_usr;
       insert into int_tb_operaciones_01
       values(wsecuencia_evt,
              wsecuencia_ope,
              wcodigo,
              woperacion,
              wtabla,
              westado_ope,
              wfecha_f);
     Exception
        when NO_CONEXION then
             insert into conexion_tronsieb
             values('Oficinas...Error al conectarse a siebel',sysdate);
        when others then
             insert into conexion_tronsieb
             values('Oficinas...Error al insertar en siebel',sysdate);
     end;
   end if;
end;
/
