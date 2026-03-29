CREATE OR REPLACE TRIGGER TRG_AU_EMI_CLIENTE
AFTER UPDATE ON EMI_CLIENTE 
DECLARE

  t_newcli Pkg_Emi_Cliente.t_cliente;

  var_row     ROWID;
  var_mensaje VARCHAR2(255);

BEGIN

  t_newcli := NULL;

  SELECT num_rowid, mensaje, numero_solicitud, codigo_riesgo
    INTO var_row,
         var_mensaje,
         t_newcli.NUMERO_SOLICITUD,
         t_newcli.CODIGO_RIESGO
    FROM EMI_MUTATING
   WHERE table_name = 'EMI_CLIENTE_UPDATE';

  DBMS_OUTPUT.PUT_LINE(' TRG_AU_EMI_CLIENTE : EMI_MUTATING NUMERO_SOLICITUD = ' ||
                       t_newcli.NUMERO_SOLICITUD);
  DBMS_OUTPUT.PUT_LINE(' TRG_AU_EMI_CLIENTE : EMI_MUTATING CODIGO_RIESGO    = ' ||
                       t_newcli.CODIGO_RIESGO);

  DELETE FROM EMI_MUTATING WHERE table_name = 'EMI_CLIENTE_UPDATE';

  -- Datos del Cliente
  SELECT MARCA_APLICACION,
         ROL,
         DESC_ROL,
         FECHA_DILIGENCIAMIENTO,
         TIPDOC_CODIGO,
         DESC_TIPDOC,
         NUMERO_DOCUMENTO,
         FECHA_EXPEDICION,
         DIVPOL_CODIGO_EXPEDIDO_EN,
         LUGAR_EXPEDICION,
         DESC_LUGAR_EXP,
         PRIMER_NOMBRE,
         SEGUNDO_NOMBRE,
         PRIMER_APELLIDO,
         SEGUNDO_APELLIDO,
         FECHA_NACIMIENTO,
         EDAD_TARIFA,
         EDAD_EXTEN,
         DIVPOL_CODIGO_NACIDO_EN,
         LUGAR_NACIMIENTO,
         DESC_LUGAR_NAC,
         NACIONALIDAD,
         SEXO,
         ESTADO_CIVIL,
         DESC_ESTADO_CIVIL,
         AFI_SECUENCIA,
         AFI_DESCRIPCION,
         NUMERO_HIJOS,
         DIRECCION_RESIDENCIA,
         DIVPOL_CODIGO_RESIDENCIA,
         CIUDAD_RESIDENCIA,
         DESC_LUGAR_RES,
         TELEFONO_RESIDENCIA,
         NO_DE_CELULAR,
         FAX,
         EMAIL,
         CONTACTAR_EN,
         TIPO_ACTIVIDAD,
         COD_PROFESION,
         PROFESION,
         OCUPACION_ACTUAL,
         CLA_OCUPACION_ACTUAL,
         DESC_OCUPACION,
         ACTIVIDAD_ECONOMICA,
         DESC_ACTIVIDAD_ECONOMICA,
         EMPRESA_TRABAJA,
         CARGO,
         DIRECCION_TRABAJO,
         DIVPOL_CODIGO_TRABAJO,
         CIUDAD_TRABAJO,
         DESC_LUGAR_TRAB,
         TELEFONO,
         FAX_OFICINA,
         SERVIDOR_PUBLICO,
         MANEJA_RECURSOS_PUBLICOS,
         PUBLICAMENTE_EXPUESTA,
         VINCULO_PERSONA_RECONOCIDA,
         PRIMER_NOMBRE_REL_PEP,
         SEGUNDO_NOMBRE_REL_PEP,
         PRIMER_APELLIDO_REL_PEP,
         SEGUNDO_APELLIDO_REL_PEP,
         num_id_familiar_o_socio_pep,
         parentesco_familiar_socio_pep,
         cargo_familiar_socio_pep,
         FECHA_ESTADOS_FINANCIEROS,
         vlr_total_activos,
         vlr_total_pasivos,
         vlr_total_ingresos,
         vlr_total_egresos,
         total_patrimonio,
         MANEJA_MONEDA_EXTRANJERA,
         MONEDA_EXTRANJERA,
         OPERACIONES_INTERNACIONALES,
         TIPO_OPERACION_INTERNACIONAL,
         posee_prod_financieros_ext,
         tipo_producto,
         NRO_CUENTA_MONEDA_EXTRANJERA,
         BANCO_O_ENTIDAD,
         monto,
         DIVPOL_PAIS_CUENTA,
         PAIS_DE_LA_CUENTA,
         DESC_PAIS_EXT,
         DIVPOL_CIUDAD_CUENTA,
         CIUDAD_DE_LA_CUENTA,
         DESC_CIUDAD_EXT,
         moneda,
         FECHA_FATCA,
         CLIENTE_RECALCITRANTE,
         CLIENTE_EXTRANJERO,
         CIUDADANIA_EXTRANJERA,
         RESIDENCIA_EXTRANJERA,
         PAIS_RESIDENCIA,
         DESC_PAIS_RESIDENCIA,
         DIRECCION_EXTRANJERA,
         ESTADO_EXTRANJERO,
         DESC_ESTADO_EXTRANJERO,
         COD_POSTAL_EXTRANJERO,
         TELEFONO_EXTRANJERO,
         VIAJA_USA,
         CLIENTE_EXENTO_REPORTE,
         OBLIGADO_TRIBUTAR,
         CLIENTE_TRIBUTANTE,
         PAIS_TRIBUTACION,
         DESC_PAIS_TRIBUTACION,
         NUM_IDENTIFICACION_TRIBUTARIA,
         PAIS_DIFERENTE,
         PAIS_RESIDENCIA_LEGAL,
         PAIS_RESIDENCIA_ACTUAL,
         DESC_PAIS_DIFERENTE,
         DESC_PAIS_RESIDENCIA_ACTUAL,
         MOTIVO_ESTADIA,
         USUARIO_CREACION,
         FECHA_CREACION,
         USUARIO_TRANSACCION,
         FECHA_TRANSACCION
    INTO t_newcli.MARCA_APLICACION,
         t_newcli.ROL,
         t_newcli.DESC_ROL,
         t_newcli.FECHA_DILIGENCIAMIENTO,
         t_newcli.TIPDOC_CODIGO,
         t_newcli.DESC_TIPDOC,
         t_newcli.NUMERO_DOCUMENTO,
         t_newcli.FECHA_EXPEDICION,
         t_newcli.DIVPOL_CODIGO_EXPEDIDO_EN,
         t_newcli.LUGAR_EXPEDICION,
         t_newcli.DESC_LUGAR_EXP,
         t_newcli.PRIMER_NOMBRE,
         t_newcli.SEGUNDO_NOMBRE,
         t_newcli.PRIMER_APELLIDO,
         t_newcli.SEGUNDO_APELLIDO,
         t_newcli.FECHA_NACIMIENTO,
         t_newcli.EDAD_TARIFA,
         t_newcli.EDAD_EXTEN,
         t_newcli.DIVPOL_CODIGO_NACIDO_EN,
         t_newcli.LUGAR_NACIMIENTO,
         t_newcli.DESC_LUGAR_NAC,
         t_newcli.NACIONALIDAD,
         t_newcli.SEXO,
         t_newcli.ESTADO_CIVIL,
         t_newcli.DESC_ESTADO_CIVIL,
         t_newcli.AFI_SECUENCIA,
         t_newcli.AFI_DESCRIPCION,
         t_newcli.NUM_HIJOS,
         t_newcli.DIRECCION_RESIDENCIA,
         t_newcli.DIVPOL_CODIGO_RESIDENCIA,
         t_newcli.CIUDAD_RESIDENCIA,
         t_newcli.DESC_LUGAR_RES,
         t_newcli.TELEFONO_RESIDENCIA,
         t_newcli.NO_DE_CELULAR,
         t_newcli.FAX,
         t_newcli.EMAIL,
         t_newcli.CONTACTAR_EN,
         t_newcli.TIPO_ACTIVIDAD,
         t_newcli.COD_PROFESION,
         t_newcli.PROFESION,
         t_newcli.OCUPACION_ACTUAL,
         t_newcli.CLA_OCUPACION_ACTUAL,
         t_newcli.DESC_OCUPACION,
         t_newcli.ACTIVIDAD_ECONOMICA,
         t_newcli.DESC_ACTIVIDAD_ECONOMICA,
         t_newcli.EMPRESA_TRABAJA,
         t_newcli.CARGO,
         t_newcli.DIRECCION_TRABAJO,
         t_newcli.DIVPOL_CODIGO_TRABAJO,
         t_newcli.CIUDAD_TRABAJO,
         t_newcli.DESC_LUGAR_TRAB,
         t_newcli.TELEFONO,
         t_newcli.FAX_OFICINA,
         t_newcli.SERVIDOR_PUBLICO,
         t_newcli.MANEJA_RECURSOS_PUBLICOS,
         t_newcli.PUBLICAMENTE_EXPUESTA,
         t_newcli.VINCULO_PERSONA_RECONOCIDA,
         t_newcli.PRIMER_NOMBRE_REL_PEP,
         t_newcli.SEGUNDO_NOMBRE_REL_PEP,
         t_newcli.PRIMER_APELLIDO_REL_PEP,
         t_newcli.SEGUNDO_APELLIDO_REL_PEP,
         t_newcli.NUM_ID_SOCIO_PEP,
         t_newcli.PARENTESCO_SOCIO_PEP,
         t_newcli.CARGO_SOCIO_PEP,
         t_newcli.FECHA_ESTADOS_FINANCIEROS,
         t_newcli.TOTAL_ACTIVOS,
         t_newcli.TOTAL_PASIVOS,
         t_newcli.TOTAL_INGRESOS,
         t_newcli.TOTAL_EGRESOS,
         t_newcli.TOTAL_PATRIMONIO,
         t_newcli.MANEJA_MONEDA_EXTRANJERA,
         t_newcli.MONEDA_EXTRANJERA,
         t_newcli.OPERACIONES_INTERNACIONALES,
         t_newcli.TIPO_OPERACION_INTERNACIONAL,
         t_newcli.POSEE_PRODUCTOS,
         t_newcli.TIPO_PRODUCTO,
         t_newcli.NRO_CUENTA_MONEDA_EXTRANJERA,
         t_newcli.BANCO_O_ENTIDAD,
         t_newcli.MONTO,
         t_newcli.DIVPOL_PAIS_CUENTA,
         t_newcli.PAIS_DE_LA_CUENTA,
         t_newcli.DESC_PAIS_EXT,
         t_newcli.DIVPOL_CIUDAD_CUENTA,
         t_newcli.CIUDAD_DE_LA_CUENTA,
         t_newcli.DESC_CIUDAD_EXT,
         t_newcli.MONEDA,
         t_newcli.FECHA_FATCA,
         t_newcli.CLIENTE_RECALCITRANTE,
         t_newcli.CLIENTE_EXTRANJERO,
         t_newcli.CIUDADANIA_EXTRANJERA,
         t_newcli.RESIDENCIA_EXTRANJERA,
         t_newcli.PAIS_RESIDENCIA,
         t_newcli.DESC_PAIS_RESIDENCIA,
         t_newcli.DIRECCION_EXTRANJERA,
         t_newcli.ESTADO_EXTRANJERO,
         t_newcli.DESC_ESTADO_EXTRANJERO,
         t_newcli.COD_POSTAL_EXTRANJERO,
         t_newcli.TELEFONO_EXTRANJERO,
         t_newcli.VIAJA_USA,
         t_newcli.CLIENTE_EXENTO_REPORTE,
         t_newcli.OBLIGADO_TRIBUTAR,
         t_newcli.CLIENTE_TRIBUTANTE,
         t_newcli.PAIS_TRIBUTACION,
         t_newcli.DESC_PAIS_TRIBUTACION,
         t_newcli.NUM_IDENTIFICACION_TRIBUTARIA,
         t_newcli.PAIS_DIFERENTE,
         t_newcli.PAIS_RESIDENCIA_LEGAL,
         t_newcli.PAIS_RESIDENCIA_ACTUAL,
         t_newcli.DESC_PAIS_DIFERENTE,
         t_newcli.DESC_PAIS_RESIDENCIA_ACTUAL,
         t_newcli.MOTIVO_ESTADIA,
         t_newcli.USUARIO_CREACION,
         t_newcli.FECHA_CREACION,
         t_newcli.USUARIO_TRANSACCION,
         t_newcli.FECHA_TRANSACCION
    FROM EMI_CLIENTE
   WHERE NUMERO_SOLICITUD = t_newcli.NUMERO_SOLICITUD
     AND CODIGO_RIESGO = t_newcli.CODIGO_RIESGO;

   --Man 9720 Ajuste en actualización de naturales
   IF t_newcli.OCUPACION_ACTUAL < 5 THEN
      t_newcli.CLA_OCUPACION_ACTUAL := 'V';
   END IF;


  DBMS_OUTPUT.PUT_LINE(' TRG_AU_EMI_CLIENTE: Antes de llamar =>pkg_emi_cliente.actualizar_naturales  usaurio modifica -> ' ||
                       t_newcli.USUARIO_TRANSACCION);
  DBMS_OUTPUT.PUT_LINE(' TRG_AU_EMI_CLIENTE :Antes de llamar =>pkg_emi_cliente.actualizar_naturale   PRIMER_NOMBRE  ->' ||
                       t_newcli.PRIMER_NOMBRE);
  Pkg_Emi_Cliente.actualizar_naturales(t_newcli);
  DBMS_OUTPUT.PUT_LINE('TRG_AU_EMI_CLIENTE :Despues de llamar =>pkg_emi_cliente.actualizar_naturales TRG_AU_EMI_CLIENTE');
  IF t_newcli.P_SQLERR <> 0 THEN
    RAISE_APPLICATION_ERROR(-20525,
                            'Error  Cliente' || t_newcli.p_sqlerr ||
                            ' Fallo' || t_newcli.p_sqlerrm);
  END IF;

  /*EXCEPTION WHEN OTHERS THEN
          DBMS_OUTPUT.PUT_LINE('ERROR EN TRG_AU_EMI_CLIENTE>'||SQLCODE);
          DBMS_OUTPUT.PUT_LINE('  NUMERO_SOLICITUD = '||  t_newcli.NUMERO_SOLICITUD );
          DBMS_OUTPUT.PUT_LINE('  CODIGO_RIESGO    = '||  t_newcli.CODIGO_RIESGO );

          DBMS_OUTPUT.PUT_LINE('MENSAJE=>'||SQLERRM);
          RAISE_APPLICATION_ERROR (-20525,'Error  TRG_AU_EMI_CLIENTE'||t_newcli.p_sqlerr ||' Fallo'||t_newcli.p_sqlerrm);
  */
END;
/
