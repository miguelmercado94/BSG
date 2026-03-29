CREATE OR REPLACE TRIGGER TRG_LOG_TESORERIA
BEFORE INSERT
ON LOG_TESORERIA
FOR EACH ROW
DECLARE

new_secuencia number(6);

BEGIN

/* Se Comentario esta new.secuencia debido a que bloqueba la pantalla */

-- Caso 1: Incrementar Secuencia
  IF :new.secuencia = 0 THEN

    SELECT S_LOGTESO.NEXTVAL INTO new_secuencia FROM DUAL;

-- Caso 2: Usar Secuencia actual
  ELSIF :new.secuencia = -1 THEN

    SELECT S_LOGTESO.CURRVAL INTO new_secuencia FROM DUAL;

 -- Caso 3: Usar Secuencia que viene en el INSERT
  ELSE

     new_secuencia := :new.secuencia;
  END IF;

  :new.secuencia := new_secuencia;
/* */

/* Se Comentario new.fecha debido a que genera error en la pantalla */
:new.fecha := SYSDATE;
:new.ID_SESSION := USERENV('SESSIONID');
:new.USUARIO :=USER;

END;
/
