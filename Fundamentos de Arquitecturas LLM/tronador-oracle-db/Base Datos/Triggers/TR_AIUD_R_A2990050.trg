CREATE OR REPLACE TRIGGER TR_AIUD_R_A2990050
  after update on A2990050
  for each row
/*
 Modifica: RICHARD IBARRA - Asesoftware
 Fecha   : Mayo 17 de 2016 - Mantis 44150
 Desc    : Se modifica para que solo audite las actualizaciones
 Modifica: Rolphy Quintero - Asesoftware
 Fecha   : Junio 26 de 2015 - Mantis 30955
 Desc    : Se crea el trigger para auditar el borrado, inserción y actualización
           de los registros en la tabla A2990050.


*/
Declare
  v_ope  VARCHAR2(3);

Begin
      v_ope := 'UPD';

    insert into A2990050_JN
      (JN_SECUENCIA, JN_OPERATION, JN_ORACLE_USER, JN_DATETIME, clave, usuario, terminal,
      sesion, fecha, mcalis, para1, para2, para3, para4, para5, parafecha1, parafecha2, parafecha3,
      nombrpt, nomblis, copias, hojas, observacion, impresora, mantiene, para6, para7, nombarc, mca_cierre,
      fecha_cierre, cod_agencia, cod_job, entrada_id, nivel, nom_user, para8, fecha_creacion, id_proceso)
       values
      (SEQ_A2990050_JN.NEXTVAL, v_ope, USER, SYSDATE, :NEW.clave,
      :NEW.usuario, :NEW.terminal, :NEW.sesion, :NEW.fecha, :NEW.mcalis,
      :NEW.para1, :NEW.para2, :NEW.para3, :NEW.para4, :NEW.para5, :NEW.parafecha1,
      :NEW.parafecha2, :NEW.parafecha3, :NEW.nombrpt, :NEW.nomblis, :NEW.copias,
      :NEW.hojas, :NEW.observacion, :NEW.impresora, :NEW.mantiene, :NEW.para6,
      :NEW.para7, :NEW.nombarc, :NEW.mca_cierre, :NEW.fecha_cierre, :NEW.cod_agencia,
      :NEW.cod_job, :NEW.entrada_id, :NEW.nivel, :NEW.nom_user, :NEW.para8, :NEW.fecha_creacion, :NEW.id_proceso);


End TR_AIUD_R_A2990050;
/
