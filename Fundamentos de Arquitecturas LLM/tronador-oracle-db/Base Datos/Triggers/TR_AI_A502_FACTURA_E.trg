CREATE OR REPLACE trigger TR_AI_A502_FACTURA_E
  after insert on A502_FACTURA_E
  referencing new as new old as old
  for each row

/*****************************************************************
Fecha creación: 05/07/2022
Autor         : Edison Vega - SB
objeto        : a502_typ_factura_e_recepcion
descripcion   : Trigger para insertar los eventos de recepción
                de facturas en la tabla A502_FACTURA_E_RECEPCION
                para el primer evento de recepcion.
Proyecto:     : Resolucion 0085
creado por    : Edison Vega - sb
fecha crea    : 05/07/2022
mod por       : -
fecha mod     : -
******************************************************************/

  declare

    l_resultado          number(1, 0);
    l_consecutivo_evento number(15,0);
    l_codigo_evento_uno constant a502_factura_e_recepcion.codigo_evento%type := '1';

    l_datos_factura_e_recepcion  a502_typ_factura_e_recepcion;

  begin

    if  (:new.tipo_doc = 'INVOIC') AND (:new.tipo_factura = 'FE') then

      /*
        Genera el ID el consecutivo para el envio del evento
        a la DIAN
      */
      pck_factura_e_recepcion.prc_obtener_consecutivo_dian(l_codigo_evento_uno, l_consecutivo_evento);

      l_datos_factura_e_recepcion := new a502_typ_factura_e_recepcion();

      l_datos_factura_e_recepcion.codigo                      := null;
      l_datos_factura_e_recepcion.secuencia_factura_e         := :new.secuencia;
      l_datos_factura_e_recepcion.nro_evento_dian             := l_consecutivo_evento + 1;
      l_datos_factura_e_recepcion.codigo_evento               := l_codigo_evento_uno;
      l_datos_factura_e_recepcion.fecha_evento                := sysdate;
      l_datos_factura_e_recepcion.codigo_estado_proceso       := 'PE';
      l_datos_factura_e_recepcion.descripcion_estado_proceso  := 'Pendiente envio al notificador';
      l_datos_factura_e_recepcion.fecha_estado_proceso        := sysdate;
      l_datos_factura_e_recepcion.id_transaccion              := null;
      l_datos_factura_e_recepcion.num_envios                  := 0;

      pck_factura_e_recepcion.prc_insert_evento_recepcion(
        l_datos_factura_e_recepcion,
        'TRIGGER',
        l_resultado
      );

    end if;

end tr_aiu_a502_factura_e;
/
