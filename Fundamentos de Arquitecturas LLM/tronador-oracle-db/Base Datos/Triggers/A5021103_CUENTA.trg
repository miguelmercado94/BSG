CREATE OR REPLACE TRIGGER a5021103_cuenta
before
insert or  update  on a5021103
for each row
DISABLE
begin
declare
     nuevo   number(1) := 0;
     cambio  number(1) := 0;
     bloqueo number(1) := 0;
  p_secuencia_tercero       number;
  p_numero_documento        number;
  p_tipo_documento          varchar2(02);
  p_numero_cuenta           number;
  p_tipo_cuenta             varchar2(02);
  p_mca_transferencia       varchar2(1);
  p_mca_estado_cta          varchar2(1);
  p_usuario                 varchar2(15);
  p_codigo_entidad          number;
  p_secuencia_cuenta        number;
p_sqlerr                    number := 0;
p_sqlerrm                   varchar2(240);

 begin
   IF  INSERTING THEN
        nuevo := 1;
        cambio := 0;
        bloqueo := 0;
   elsif   UPDATING  THEN
     if :new.numero_cta_destino <> :old.numero_cta_destino then
        cambio := 1;
        nuevo := 0;
        bloqueo := 0;
     elsif :new.estado <> :old.estado then
        bloqueo := 1;
        nuevo := 0;
        cambio := 0;
     end if;
   END IF;
  if nuevo > 0 or cambio > 0 or bloqueo > 0 then
        select decode(:new.tipo_documento,'01','NT','CC'),
               substr(:new.tipo_cta,2,1)
               into p_tipo_documento,p_tipo_cuenta
       from dual;
   p_numero_documento  := :new.numero_documento;
   p_usuario           := substr(user,1,8);
   p_secuencia_tercero := null;
   p_mca_transferencia := 'S';
   p_secuencia_cuenta   := null;
   p_numero_cuenta     := :new.numero_cta_destino;
   p_codigo_entidad    := :new.cod_entidad_destino;
   if nuevo > 0 then
       p_mca_estado_cta    := 'A';
   elsif cambio > 0 then
         if :new.estado = '1' then
           p_mca_estado_cta    := 'A';
         elsif :new.estado = '2' then
           p_mca_estado_cta    := 'I';
         elsif :new.estado = '3' then
           p_mca_estado_cta    := 'T';
         end if;
   elsif bloqueo > 0 then
         if :new.estado = '1' then
           p_mca_estado_cta    := 'A';
         elsif :new.estado = '2' then
           p_mca_estado_cta    := 'I';
         elsif :new.estado = '3' then
           p_mca_estado_cta    := 'T';
         end if;
   else
         p_mca_estado_cta    := 'A';
   end if;

begin

pkg_prc.PRC_CREA_CUENTA(
 		   				  p_secuencia_tercero,
						  p_numero_documento,
						  p_tipo_documento,
						  p_numero_cuenta,
                          p_tipo_cuenta,
                          p_mca_transferencia,
						  p_mca_estado_cta,
                        p_usuario,
                        p_codigo_entidad,
						  p_secuencia_cuenta,
                          p_sqlerr,
                          p_sqlerrm);

end;
 if p_sqlerr != 0 then
   raise_application_error(-20500,p_sqlerrm);
 end if;

end if;
end;
end;
/
