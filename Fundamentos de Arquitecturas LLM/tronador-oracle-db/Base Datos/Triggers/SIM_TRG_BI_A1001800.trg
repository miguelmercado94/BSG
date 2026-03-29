CREATE OR REPLACE TRIGGER SIM_TRG_BI_A1001800
BEFORE INSERT
   on a1001800
FOR EACH ROW
DECLARE
  l_secuencia NUMBER(15);
BEGIN
  IF INSERTING AND :new.sub_cod_texto IS NULL AND :new.cod_proceso = '2' THEN
    BEGIN
      BEGIN
        SELECT seq_productos.nextval
          INTO l_secuencia
          FROM dual;
      END;
      INSERT INTO sim_productos(id_producto,
                               cod_producto,
                               abrev_producto,
                               nom_producto,
                               cod_cia,
                               cod_secc,
                               estado,
                               usuario_creacion,
                               fecha_creacion,
                               fecha_alta,
                               clau_anex,
                               mca_txt_fijo,
                               mca_txt_asoc,
                               mca_end_temp,
                               mca_factura,
                               cod_tratamiento,
                               mca_multiramo,
                               mca_periodo_fact,
                               mca_finan,
                               mca_manual,
                               mca_pension,
                               mca_genera_carnet,
                               mca_impresion_web,
                               mca_bancaseguros,
                               usuario_modificacion,
                               fecha_modificacion,
                               mca_poliza_ppal,
                               desc_producto,
                               nombre_logo,
                               mca_renovacion,
                               mca_renovacion_linea,
                               mca_factura_informada,
                               mca_factura_debito,
                               mca_factura_libranza,
                               mca_anula_diaria,
                               mca_anula_mensual,
                               fec_inicio_impresion_doc1,
                               mca_visualiza_textos,
                               mca_coordenada_sini)
      	               VALUES (l_secuencia,
                               :new.cod_texto,
                               :new.txt_red,
                               :new.txt_red,
                               :new.COD_CIA,
                               :new.cod_secc,
                               'A',
                               'TRONADOR',
                               SYSDATE,
                               SYSDATE,
                               nvl(:new.clau_anex,'N'),
                               nvl(:new.mca_txt_fijo,'N'),
                               nvl(:new.mca_txt_asoc,'N'),
                               nvl(:new.mca_end_temp,'N'),
                               nvl(:new.mca_factura,'N'),
                               nvl(:new.cod_tratamiento,'N'),
                               nvl(:new.mca_multiramo,'N'),
                               nvl(:new.mca_periodo_fact,'N'),
                               nvl(:new.mca_finan,'N'),
                               nvl(:new.mca_manual,'N'),
                               nvl(:new.mca_pension,'N'),
                               nvl(:new.mca_genera_carnet,'N'),
                               nvl(:new.mca_impresion_web,'N'),
                               NULL,
                               NULL,
                               NULL,
                               'N',
                               nvl(:new.txt_red,'N'),
                               'default.gif',
                               'N',
                               'N',
                               'N',
                               'N',
                               'N',
                               'N',
                               'N',
                               :new.fec_ini_impresion_doc1
                               ,'N'
                               ,'N');
    END;
  END IF;
  EXCEPTION WHEN OTHERS THEN
    sim_pck_errores.grabarLog('SIM_TRG_BI_A1001800','Error:'||SQLERRM||'-'||SQLCODE,NULL);
END SIM_TRG_BIU_A1001800;
/
