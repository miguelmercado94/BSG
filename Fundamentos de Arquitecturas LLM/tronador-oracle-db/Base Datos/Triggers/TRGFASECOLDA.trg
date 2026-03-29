CREATE OR REPLACE TRIGGER trgfasecolda
before insert ON A2040100 for each row
declare
resultado varchar2(2000);
numsecupol A2000030.num_secu_pol%TYPE;
numend     A2000030.num_end%TYPE;
codries    a2000040.cod_ries%TYPE;
-- <Comment>
-- <Author>Asesoftware Dliv</Author>
-- <Date>09/09/2010</Date>
-- <Control>Lb_Req_Nomenclatura_Placa 1.0</Control>
-- <Summary>Se Cambia El Tipo De La Variable Pplaca De Varchar2(6)
--          A A2040100.Pat_Veh%Type</Summary>
PPlaca     A2040100.PAT_VEH%TYPE;
-- </Comment>
PMotor     A2040100.motor_veh%TYPE;
PChasis    A2040100.Chasis_veh%TYPE;
Contador   Number(5);
Anualidad  Number(2);
begin
numsecupol := :new.num_secu_pol;
numend     := :new.num_end;
codries    := :new.cod_ries;
PPlaca     := :new.Pat_veh;
PChasis    := :new.Chasis_veh;
PMotor     := :new.Motor_veh;
if user != 'OPS$INTASI14' then
select count(*) into contador from a2000040
where num_Secu_pol = numsecupol and cod_ries = codries and
      num_end != numend;
if contador = 0 then
   if numend = 0 then
      -- se adiciona num_end por caso de mantis 19794 donde quedaron mal los datos del riesgo 1441
      select to_number(substr(lpad(to_char(num_pol1),13,'0'),12,2))
      into Anualidad
      from a2000030
      where num_Secu_pol = numsecupol and num_end=0;
    else
      Anualidad := 0;
    end if;
    if anualidad <= 1 then
    Begin
    null;
--PGT,diciembre 2 de 2011: Se modifica URL por cambio en Fasecolda
-- resultado := utl_http.request('http://webserver.fasecolda.com:15008/autos/plsql/autos.consulta?lpara1='||PPlaca||'='||PMotor||'='||PChasis||'==9019860002503=2503');
   resultado := utl_http.request('http://consultas.fasecolda.com:15008/inverfas/autos.consulta?lpara1='||PPlaca||'='||PMotor||'='||PChasis||'==9019860002503=2503');
    insert into F2040100
    values (TRunc(sysdate),numsecupol,PPlaca, PMotor, Pchasis,codries,'S');
Exception
   when OThers THEN
        insert into F2040100
        values (TRunc(sysdate),numsecupol,PPlaca, PMotor, Pchasis,codries,'N');
   end;
   end if;
end if;
end if;
end;
/
