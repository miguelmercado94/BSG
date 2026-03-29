CREATE OR REPLACE TRIGGER SIM_TRG_MAXMIN_AGE_C2200050
AFTER INSERT OR UPDATE ON C2200050
FOR EACH ROW

--Solo se hace el cambio cuando se modifica la cobertura básica para productos vida individual
WHEN ((
          NEW.Cod_Ramo IN(940,942,944,946)
      AND NEW.cod_cob =901
     ))

/*
Created by: Juan González
Date:24 10 2018
Porpouse: Guardar la edad máxima i minima en la tabla parametro
          para hacer la validación de ingreso en Simones Ventas - Vida Individual
Recomendacion:
Todo bloque definido como autonomous transaction debe finalizar con un COMMIT o ROLLBACK explícito.
De lo contrario al programa principal le queda una transacción pendiente lo que hace que se ejecute una exception.
*/
DECLARE
    l_maxEdad   NUMBER;
    l_minEdad   NUMBER;
    l_sexo      VARCHAR2(1);
    pragma autonomous_transaction;
BEGIN
     --Para la variable MAX_AGE
     IF UPDATING AND
       ((:NEW.edad_max_m <>:OLD.edad_max_m)OR (:NEW.edad_max_f <>:OLD.edad_max_f)) THEN
         --Identifica el mayor de la nueva edad entre Masculino o Femenino
         IF :NEW.edad_max_m > :NEW.edad_max_f THEN
            l_sexo:= 'M';
           ELSE
            l_sexo:= 'F';
         END IF;

         --busca la edad máxima teniendo en cuenta todas las opciones de cobertura y solo para la cobertura básica
        SELECT  DECODE (l_sexo,'M', MAX(c.edad_max_m),MAX(c.edad_max_f))
                INTO
                l_maxEdad
        FROM  c2200050 c
        WHERE c.cod_secc =:NEW.cod_secc
              AND c.cod_ramo = :NEW.cod_ramo
              AND c.cod_cob=:NEW.cod_cob
              AND c.opcion <> :NEW.opcion
              AND c.fecha_baja IS NULL
              AND c.fecha_vig =
              (SELECT  MAX (t.fecha_vig)
              FROM  c2200050 t
              WHERE  t.cod_secc= c.cod_secc
              AND t.cod_ramo = c.cod_ramo
              AND t.cod_cob=c.cod_cob
              AND c.opcion=t.opcion
              )
      ;

        --Valida la carga del valor por defecto
        l_maxEdad:=nvl(l_maxEdad,0);

        --evalua la max Edad recien ingresada con las existentes
        IF (l_sexo ='M') AND (:NEW.edad_max_m>l_maxEdad) THEN
           l_maxEdad:=:NEW.edad_max_m;
        END IF;
        IF (l_sexo ='F') AND (:NEW.edad_max_f>l_maxEdad) THEN
           l_maxEdad:=:NEW.edad_max_f;
        END IF;

        --Actualiza el parámetro de Simones Ventas
        UPDATE C9999909 c
               SET c.dat_num=l_maxEdad,
               c.codigo=:NEW.cod_cob,              -- Cobertura que afectó el tope de la edad
               c.dat_obs='Opcion '|| :NEW.opcion, -- dice cual es la opcion que tiene el tope de edad
               c.fecha_act=SYSDATE,               --Momento en que se actualizó
               c.usuario=USER                     --Usuario que lo hizo
        WHERE c.cod_tab='PARAM_COT_VIDA'
        AND c.dat_car='MAX_AGE'
        AND c.cod_ramo=:NEW.Cod_Ramo
        ;
    END IF;


     --Para la variable MIN_AGE
     IF UPDATING AND
       ((:NEW.edad_min_m <>:OLD.edad_min_m)OR (:NEW.edad_min_f <>:OLD.edad_min_f)) THEN

         --Identifica el mayor de la nueva edad entre Masculino o Femenino
         IF :NEW.edad_min_m < :NEW.edad_min_f THEN
            l_sexo:= 'M';
           ELSE
            l_sexo:= 'F';
         END IF;

         --busca la edad minima teniendo en cuenta todas las opciones de cobertura y solo para la cobertura básica
        SELECT  DECODE (l_sexo,'M', MIN(c.edad_min_m),MIN(c.edad_min_f))
                INTO
                l_minEdad
        FROM  c2200050 c
        WHERE c.cod_secc =:NEW.cod_secc
              AND c.cod_ramo = :NEW.cod_ramo
              AND c.cod_cob=:NEW.cod_cob
              AND c.opcion <> :NEW.opcion
              AND c.fecha_baja IS NULL
              AND c.fecha_vig =
              (SELECT  MAX (t.fecha_vig)
              FROM  c2200050 t
              WHERE  t.cod_secc= c.cod_secc
              AND t.cod_ramo = c.cod_ramo
              AND t.cod_cob=c.cod_cob
              AND c.opcion=t.opcion
              )
        ;

        --Valida la carga del valor por defecto
        l_minEdad:=nvl(l_minEdad,0);

        --evalua la min Edad recien ingresada con las existentes
        IF (l_sexo ='M') AND (:NEW.edad_min_m<l_minEdad) THEN
           l_minEdad:=:NEW.edad_min_m;
        END IF;
        IF (l_sexo ='F') AND (:NEW.edad_min_f<l_minEdad) THEN
           l_minEdad:=:NEW.edad_min_f;
        END IF;

        --Actualiza el parámetro de Simones Ventas
        UPDATE C9999909 c
               SET c.dat_num=l_minEdad,
               c.codigo=:NEW.cod_cob,              -- Cobertura que afectó el tope de la edad
               c.dat_obs='Opcion '|| :NEW.opcion, -- dice cual es la opcion que tiene el tope de edad
               c.fecha_act=SYSDATE,               --Momento en que se actualizó
               c.usuario=USER                     --Usuario que lo hizo
        WHERE c.cod_tab='PARAM_COT_VIDA'
        AND c.dat_car='MIN_AGE'
        AND c.cod_ramo=:NEW.Cod_Ramo
        ;
    END IF;
    COMMIT;
EXCEPTION  WHEN  others THEN
  ROLLBACK;
END;
/
