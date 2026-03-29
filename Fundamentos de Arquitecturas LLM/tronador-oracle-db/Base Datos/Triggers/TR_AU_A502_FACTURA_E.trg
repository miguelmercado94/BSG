CREATE OR REPLACE trigger TR_AU_A502_FACTURA_E
  after update of estado on A502_FACTURA_E
  referencing new as new old as old
  for each row

/*****************************************************************
Fecha creación: 18/07/2022
Autor         : Edison Vega - SB
objeto        : a502_typ_factura_e_recepcion
descripcion   : Trigger para insertar los eventos de recepción
                de facturas en la tabla A502_FACTURA_E_RECEPCION 
                para el segundo y tercer evento de recepción.
Proyecto:     : Resolucion 0085              
creado por    : Edison Vega - sb
fecha crea    : 18/07/2022
mod por       : -
fecha mod     : -
******************************************************************/

  declare

    l_resultado          number(1, 0);
    l_consecutivo_evento number(15,0);
    l_secuencia_evento   number(15,0);

    l_mca_existe_evento_uno         varchar2(2) := 'N';
    l_mca_existe_evento_dos         varchar2(2) := 'N';
    l_mca_existe_evento_tres_acep   varchar2(2) := 'N';
    l_mca_existe_evento_tres_rech   varchar2(2) := 'N';
    l_mca_existe_evento_cuatro_fve  varchar2(2) := 'N';
    l_mca_existe_evento_cuatro_tde  varchar2(2) := 'N';

    l_mca_tiempo_valido_correccion  varchar2(2) := 'N';
    
    l_codigo_evento_cuatro          varchar2(2) := null;
   
    l_datos_factura_e_recepcion     a502_typ_factura_e_recepcion;

  begin

    if (:old.estado = :new.estado) then
      return;
    end if;

    l_consecutivo_evento := null;

    if (:new.tipo_doc = 'INVOIC') AND (:new.tipo_factura = 'FE') then    

      if(:new.estado in ('3','5')) then

        pck_factura_e_recepcion.prc_check_existe_evento(:new.secuencia, pck_factura_e_recepcion.c_cod_evento_uno, null, l_mca_existe_evento_uno);
        pck_factura_e_recepcion.prc_check_existe_evento(:new.secuencia, pck_factura_e_recepcion.c_cod_evento_dos, null, l_mca_existe_evento_dos);

        /*
          Si no existe el evento 2, lo inserta
        */
        if(l_mca_existe_evento_uno = 'S' and l_mca_existe_evento_dos = 'N') then

          pck_factura_e_recepcion.prc_obtener_consecutivo_dian(pck_factura_e_recepcion.c_cod_evento_dos, l_consecutivo_evento);

          l_datos_factura_e_recepcion := new a502_typ_factura_e_recepcion();
          
          l_datos_factura_e_recepcion.codigo                      := null;
          l_datos_factura_e_recepcion.secuencia_factura_e         := :new.secuencia;
          l_datos_factura_e_recepcion.nro_evento_dian             := l_consecutivo_evento + 1;
          l_datos_factura_e_recepcion.codigo_evento               := pck_factura_e_recepcion.c_cod_evento_dos;
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

        /*
          Cuando actualizan la factura a Devuelto al proveedor - estado 3
        */
        if(:new.estado = '3') then

          pck_factura_e_recepcion.prc_check_existe_evento(:new.secuencia, pck_factura_e_recepcion.c_cod_evento_dos, null, l_mca_existe_evento_dos);
          pck_factura_e_recepcion.prc_check_existe_evento(:new.secuencia, pck_factura_e_recepcion.c_cod_evento_tres_rechazado, null, l_mca_existe_evento_tres_rech);

          /*
            Si no existe el evento 3B, lo genera e inserta
          */
          if(l_mca_existe_evento_dos = 'S' and l_mca_existe_evento_tres_rech = 'N') then
            
            pck_factura_e_recepcion.prc_obtener_consecutivo_dian(pck_factura_e_recepcion.c_cod_evento_tres_rechazado, l_consecutivo_evento);

            l_datos_factura_e_recepcion := new a502_typ_factura_e_recepcion();
            
            l_datos_factura_e_recepcion.codigo                      := null;
            l_datos_factura_e_recepcion.secuencia_factura_e         := :new.secuencia;
            l_datos_factura_e_recepcion.nro_evento_dian             := l_consecutivo_evento + 1;
            l_datos_factura_e_recepcion.codigo_evento               := pck_factura_e_recepcion.c_cod_evento_tres_rechazado;
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

        elsif(:new.estado = '5') then 

          pck_factura_e_recepcion.prc_check_existe_evento(:new.secuencia, pck_factura_e_recepcion.c_cod_evento_dos, null, l_mca_existe_evento_dos);
          pck_factura_e_recepcion.prc_check_existe_evento(:new.secuencia, pck_factura_e_recepcion.c_cod_evento_tres_aceptado, null, l_mca_existe_evento_tres_acep);

          /*
            Si no existe el evento 3A, lo genera e inserta
          */
          if(l_mca_existe_evento_dos = 'S' and l_mca_existe_evento_tres_acep = 'N') then
            
            pck_factura_e_recepcion.prc_obtener_consecutivo_dian(pck_factura_e_recepcion.c_cod_evento_tres_aceptado, l_consecutivo_evento);

            l_datos_factura_e_recepcion := new a502_typ_factura_e_recepcion();
            
            l_datos_factura_e_recepcion.codigo                      := null;
            l_datos_factura_e_recepcion.secuencia_factura_e         := :new.secuencia;
            l_datos_factura_e_recepcion.nro_evento_dian             := l_consecutivo_evento + 1;
            l_datos_factura_e_recepcion.codigo_evento               := pck_factura_e_recepcion.c_cod_evento_tres_aceptado;
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

        end if;
        
      /*
        Cuando actualizan la factura a Pagada con endoso - estado 14
      */
      elsif(:new.estado = '14') then 
      
      	begin
          select decode(e.tipo_endoso, 
                        'TRANSFERENCIA_DERECHOS_ECONOMICOS',
                        pck_factura_e_recepcion.c_cod_evento_cuatro_pago_tde, 
                        pck_factura_e_recepcion.c_cod_evento_cuatro_pago_fve)
            into l_codigo_evento_cuatro
            from a502_endoso_factura_e e
           where e.id_factura = :new.secuencia;
        exception
        when others then
          return;
        end;
        
        pck_factura_e_recepcion.prc_check_existe_evento(:new.secuencia, pck_factura_e_recepcion.c_cod_evento_tres_aceptado, null, l_mca_existe_evento_tres_acep);
        pck_factura_e_recepcion.prc_check_existe_evento(:new.secuencia, pck_factura_e_recepcion.c_cod_evento_cuatro_pago_fve, null, l_mca_existe_evento_cuatro_fve);  
        pck_factura_e_recepcion.prc_check_existe_evento(:new.secuencia, pck_factura_e_recepcion.c_cod_evento_cuatro_pago_tde, null, l_mca_existe_evento_cuatro_tde);
        
        /*
          Si no existe ningun evento 4, lo inserta
        */
        if(l_mca_existe_evento_tres_acep = 'S' and l_mca_existe_evento_cuatro_fve = 'N' and l_mca_existe_evento_cuatro_tde = 'N') then

          pck_factura_e_recepcion.prc_obtener_consecutivo_dian(l_codigo_evento_cuatro, l_consecutivo_evento);

          l_datos_factura_e_recepcion := new a502_typ_factura_e_recepcion();
          
          l_datos_factura_e_recepcion.codigo                      := null;
          l_datos_factura_e_recepcion.secuencia_factura_e         := :new.secuencia;
          l_datos_factura_e_recepcion.nro_evento_dian             := l_consecutivo_evento + 1;
          l_datos_factura_e_recepcion.codigo_evento               := l_codigo_evento_cuatro;
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
      
      
      end if;
      
      /*
        Si es una factura que se devolvio al proveedor (estado 3) por error y debe volver a procesarse
        no se inserta el evento 2, se elimina el registro de eventos rechazados siempre y cuando siga 
        en pendiente de envio al notificador se actualizan los consecutivos de 3B para que no queden 
        numeros sin usar en el consecutivo de envio a la DIAN.
      */
      if(:new.estado != '3' and :old.estado = '3') then

        /*
          Valida que aun no hayan pasado 36 horas despues de notificar el 
          evento dos para esa factura, o que no se haya enviado el evento 2 aun
        */
        begin
          select 'S'
            into l_mca_tiempo_valido_correccion
            from a502_factura_e_recepcion fer
          where fer.codigo_evento = pck_factura_e_recepcion.c_cod_evento_dos
            and fer.secuencia_factura_e = :new.secuencia
            and fer.codigo_estado_proceso = 'TE'
            and fer.fecha_estado_proceso + 1.5 > sysdate
          union
          select 'S'
            from a502_factura_e_recepcion fer
          where fer.codigo_evento = pck_factura_e_recepcion.c_cod_evento_dos
            and fer.secuencia_factura_e = :new.secuencia
            and fer.codigo_estado_proceso = 'PE';
          
        exception
        when no_data_found then
          l_mca_tiempo_valido_correccion := 'N';
        when others then
          l_mca_tiempo_valido_correccion := 'N';
        end;

        /*
          Valida que el evento 3 de rechazo siga en PE 
        */
        begin
          select codigo, nro_evento_dian
            into l_secuencia_evento, l_consecutivo_evento
            from a502_factura_e_recepcion fer
          where fer.codigo_evento = pck_factura_e_recepcion.c_cod_evento_tres_rechazado
            and fer.secuencia_factura_e = :new.secuencia
            and fer.codigo_estado_proceso = 'PE';
        exception
        when no_data_found then
          l_consecutivo_evento := null;
        when others then
          l_consecutivo_evento := null;
        end;

        if(l_consecutivo_evento is not null and l_mca_tiempo_valido_correccion = 'S') then
          
          /*
            Borramos el evento para que no se envie (Despues de esta eliminación
            quedan solo como minimo 36 horas para pasar a aceptado tacitamente)
          */
          delete from a502_factura_e_recepcion fer 
           where fer.nro_evento_dian = l_consecutivo_evento
             and fer.codigo = l_secuencia_evento
             and fer.codigo_estado_proceso = 'PE';

        end if;
      end if;
    end if;
  
end tr_aiu_a502_factura_e;
/
