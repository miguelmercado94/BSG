CREATE OR REPLACE TRIGGER t_plano_pab_t
before
insert  on plano_pab_t
for each row
declare
cantidad number :=0;
begin
   INSERT INTO plano_pab_t_HIS values(:new.datos,:new.fecha_creacion,:new.usuario_creador,:new.mca_enviado);

end;
/
