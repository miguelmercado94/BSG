CREATE OR REPLACE TRIGGER ACTUALIZA_LOCALIDADES_ARP
BEFORE INSERT OR
      UPDATE OR DELETE OF cod_div_dreg,cod_ofi_comer,abrev_agencia,nom_agencia
   ON A1000702
FOR EACH ROW
-----------------------------------------------------------------------------
-- Objetivo : insertar o actualizar las localidades en el sistema de informacion
--            de SISALUD ARP
-- Autor    : Elsa Victoria Duque Gomez
-- Fecha    : Marzo 08 de 2003
-- Modificado Jairo Fracica C
-- Fecha    : Mayo 17 de 2000
-- Cuando se borran las localidades en Tronador no se estaba actualizando en Sisalud
-------------------------------------------------------------------------------
DECLARE
  existe VARCHAR2(1):= 'N';
BEGIN

   IF UPDATING THEN
    IF  :NEW.cod_div_dreg  != :OLD.cod_div_dreg
     OR :NEW.cod_ofi_comer != :OLD.cod_ofi_comer
     OR :NEW.nom_agencia   != :OLD.nom_agencia
     OR :NEW.abrev_agencia != :OLD.abrev_agencia THEN
      UPDATE arp_localidades
        SET cod_div_dreg  = :NEW.cod_div_dreg
           ,cod_ofi_comer = :NEW.cod_ofi_comer
           ,nom_agencia   = :NEW.nom_agencia
           ,abrev_agencia = :NEW.abrev_agencia
           ,ESTADO='A'
           ,fecha_estado=SYSDATE
      WHERE cod_div_dreg  = :OLD.cod_div_dreg
        AND cod_ofi_comer = :OLD.cod_ofi_comer
        AND cod_agencia   = :OLD.cod_agencia;

  END IF;

  END IF;


  IF DELETING THEN
      BEGIN
     UPDATE arp_localidades
       SET ESTADO='I'
           ,FECHA_ESTADO=SYSDATE
           WHERE
           cod_div_dreg  = :OLD.cod_div_dreg
           AND cod_ofi_comer = :OLD.cod_ofi_comer
           AND cod_agencia   = :OLD.cod_agencia;
         EXCEPTION WHEN OTHERS THEN
        -- RAISE_APPLICATION_ERROR(-20001,'Falla en delete jota F');
        NULL;

      END;

    END IF;

    IF INSERTING THEN
    BEGIN

        BEGIN
          INSERT INTO arp_localidades(cod_div_dreg
                                       ,cod_ofi_comer
                                       ,cod_agencia
                                       ,abrev_agencia
                                       ,nom_agencia
                                       ,ESTADO
                                       ,FECHA_ESTADO
                                       )
                                 VALUES(:NEW.cod_div_dreg
                                       ,:NEW.cod_ofi_comer
                                       ,:NEW.cod_agencia
                                       ,:NEW.abrev_agencia
                                       ,:NEW.nom_agencia
                                       ,'A'
                                       ,SYSDATE
                                       );



          EXCEPTION
          WHEN DUP_VAL_ON_INDEX THEN
        --  RAISE_APPLICATION_ERROR(-20001,'Falla en commit ct'||SQLERRM);
            UPDATE arp_localidades
            SET cod_div_dreg  = :NEW.cod_div_dreg
           ,cod_ofi_comer = :NEW.cod_ofi_comer
           ,nom_agencia   = :NEW.nom_agencia
           ,abrev_agencia = :NEW.abrev_agencia
           ,ESTADO='A'
           ,FECHA_ESTADO=SYSDATE
      WHERE cod_div_dreg  = :NEW.cod_div_dreg
        AND cod_ofi_comer = :NEW.cod_ofi_comer
        AND cod_agencia   = :NEW.cod_agencia;

          WHEN OTHERS THEN
          dbms_output.put_line(SQLERRM);


        END;
    END;

  END IF;
END actualiza_localidades_arp;
/
