CREATE OR REPLACE TRIGGER SIEBEL_A1000701
AFTER
INSERT or UPDATE or DELETE on a1000701
for each row
declare
woperacion	varchar2(3)  := null;
wurl		varchar2(20) := '130.100.1.101';
winstancia	varchar2(20) := 'tron';
westado		varchar2(20) := 'PENDIENTE';
wproceso	varchar2(20) := null;
westado_ope	varchar2(20) := null;
wtabla		varchar2(20) := 'A1000701';
wusuario	varchar2(16) := null;
wsecuencia_ope	number(10);
wsecuencia_evt	number(10);
wcodigo		number(3);
wfecha_i	date;
wfecha_f	date;
NO_CONEXION	Exception;
PRAGMA		Exception_init(NO_CONEXION,-2068);
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
   /*....se determina el tipo de operacion realizado....*/
   if inserting then
      wcodigo     := :new.cod_ofi_comer;
      woperacion  := 'INS';
      wproceso    := 'INSERCION';
      westado_ope := 'ACTIVA';
      wusuario    := :new.cod_usr;
   end if;
   if updating then
      wcodigo     := :new.cod_ofi_comer;
      woperacion  := 'ACT';
      wproceso    := 'ACTUALIZACION';
      westado_ope := 'ACTIVA';
      wusuario    := :new.cod_usr;
   end if;
   if deleting then
      wcodigo    := :old.cod_ofi_comer;
      woperacion := 'DEL';
      wproceso    := 'BORRADO';
      westado_ope := 'CERRADA';
      wusuario    := :old.cod_usr;
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
             values('Sucursales...Error al conectarse a siebel',sysdate);
        when others then
             insert into conexion_tronsieb
             values('Sucursales...Error al insertar en siebel',sysdate);
     end;
   Exception
      when NO_CONEXION then
           insert into conexion_tronsieb
           values('Sucursales...Error al conectarse a siebel',sysdate);
      when others then
           insert into conexion_tronsieb
           values('Sucursales...Error al insertar en siebel',sysdate);
   end;
end;
/
