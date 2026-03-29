CREATE OR REPLACE TRIGGER clientes_act_mvtos
after insert or update of ciiu, naturaleza_juridica, nit, nombre
on clientes referencing new as new old as old for each row
begin
   if  :old.nit                 <> :new.nit
   or  :old.nombre              <> :new.nombre
   or  :old.ciiu                <> :new.ciiu
   or  :old.naturaleza_juridica <> :new.naturaleza_juridica
   or  :old.digito_chequeo      <> :new.digito_chequeo
   then
      update  mvtos_consolidados
         set  nro_identificacion  = :new.nit,
              digito_chequeo      = :new.digito_chequeo,
              nombre_cliente      = :new.nombre,
              ciiu                = :new.ciiu,
              naturaleza_juridica = :new.naturaleza_juridica
       where  codigo_compania     > 0
         and  nro_identificacion  = :old.nit;
   end if;
   if    :old.nit <> :new.nit
   then   sisgie.insenove (
     user  , null    , null   ,
     null  ,:old.nit , null   ,
    'NIT'  ,:old.nit ,:new.nit,
     null  , null    , null   );
   end if;
   if    :old.naturaleza_juridica is not null
   and   :old.naturaleza_juridica <> :new.naturaleza_juridica
   then   sisgie.insenove (
     user                , null                   , null                   ,
     null                ,:new.nit                , null                   ,
    'NATURALEZA_JURIDICA',:old.naturaleza_juridica,:new.naturaleza_juridica,
     null                , null                   , null                   );
   end if;
   if    :old.ciiu <> :new.ciiu
   then   sisgie.insenove (
     user              , null              , null             ,
     null              ,:new.nit           , null             ,
    'CIIU'             ,:old.ciiu          ,:new.ciiu         ,
     null              , null              , null             );
   end if;
   if    :old.nombre <> :new.nombre
   then   sisgie.insenove (
     user            , null                , null             ,
     null            ,:new.nit             , null             ,
    'NOMBRE'         ,:old.nombre          ,:new.nombre       ,
     null            , null                , null             );
   end if;
end;
/
