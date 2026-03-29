CREATE OR REPLACE TRIGGER trgtest
after insert on pfasecolda
for each row
declare
resultado varchar2(2000);
begin
resultado := utl_http.request('http://webserver.fasecolda.com:15008/autos/plsql/autos.consulta?lpara1=CHG2531=2=3=4=90195=8330');
insert into rfasecolda values (resultado);
end;
/
