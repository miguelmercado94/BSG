CREATE OR REPLACE TRIGGER trg_reg_sun_biu
  BEFORE INSERT ON reg_sun
  FOR EACH ROW
DECLARE
  -- local variables here
BEGIN

  :new.analisis_t1       := nvl(:new.analisis_t1, '               ');
  :new.analisis_t2       := nvl(:new.analisis_t2, '               ');
  :new.analisis_t3       := nvl(:new.analisis_t3, '               ');
  :new.analisis_t4       := nvl(:new.analisis_t4, '               ');
  :new.analisis_t5       := nvl(:new.analisis_t5, '               ');
  :new.analisis_t6       := nvl(:new.analisis_t6, '               ');
  :new.analisis_t7       := nvl(:new.analisis_t7, '               ');
  :new.analisis_t8       := nvl(:new.analisis_t8, '               ');
  :new.analisis_t9       := nvl(:new.analisis_t9, '               ');
  :new.analisis_t10      := nvl(:new.analisis_t10, '               ');
  :new.CODIGO_CUENTA     := NVL(:new.CODIGO_CUENTA, '               ');
  :new.PERIODO_CONTABLE  := NVL(:new.PERIODO_CONTABLE, '       ');
  :new.FECHA_TRANSACC    := NVL(:new.FECHA_TRANSACC, '        ');
  :new.BLANCO_1          := NVL(:new.BLANCO_1, '  ');
  :new.TIPO_REGISTRO     := NVL(:new.TIPO_REGISTRO, ' ');
  :new.FUENTE            := NVL(:new.FUENTE, '  ');
  :new.NUMERO_DIARIO     := NVL(:new.NUMERO_DIARIO, '     ');
  :new.LINEA             := NVL(:new.LINEA, '     ');
  :new.BLANCO_2          := NVL(:new.BLANCO_2, '  ');
  :new.IMPORTE           := NVL(:new.IMPORTE, '0');
  :new.CARGO_ABONO       := NVL(:new.CARGO_ABONO, ' ');
  :new.INDIC_ASIGNACION  := NVL(:new.INDIC_ASIGNACION, ' ');
  :new.TIPO_DIARIO       := NVL(:new.TIPO_DIARIO, '     ');
  :new.FUENTE_DIARIO     := NVL(:new.FUENTE_DIARIO, '     ');
  :new.REFER_TRANSACC    := NVL(:new.REFER_TRANSACC, '               ');
  :new.DESCRIPCION       := NVL(:new.DESCRIPCION,
                                '                         ');
  :new.FECHA_ENTRADA     := NVL(:new.FECHA_ENTRADA, '        ');
  :new.PERIODO_ENTRADA   := NVL(:new.PERIODO_ENTRADA, '       ');
  :new.FECHA_VENCTO      := NVL(:new.FECHA_VENCTO, '        ');
  :new.REFER_PAG_ASIGNA  := NVL(:new.REFER_PAG_ASIGNA, '               ');
  :new.FECHA_PAG_ASIGNA  := NVL(:new.FECHA_PAG_ASIGNA, '        ');
  :new.PERIO_PAG_ASIGNA  := NVL(:new.PERIO_PAG_ASIGNA, '       ');
  :new.INDIC_ACTIVO      := NVL(:new.INDIC_ACTIVO, ' ');
  :new.CODIG_ACTIVO      := NVL(:new.CODIG_ACTIVO, '          ');
  :new.SUBCO_ACTIVO      := NVL(:new.SUBCO_ACTIVO, '     ');
  :new.CODIGO_CONVERSION := NVL(:new.CODIGO_CONVERSION, '     ');
  :new.TASA_CONVERSION   := NVL(:new.TASA_CONVERSION, '0');
  :new.OTRO_IMPORTE      := NVL(:new.OTRO_IMPORTE, '0');
  :new.NUME_DECIMALES    := NVL(:new.NUME_DECIMALES, '2');
  :new.ID_OPERADOR_1     := NVL(:new.ID_OPERADOR_1, '   ');
  :new.ID_OPERADOR_2     := NVL(:new.ID_OPERADOR_2, '   ');
  :new.ID_OPERADOR_3     := NVL(:new.ID_OPERADOR_3, '   ');
  :new.REVER_SIG_PERIOD  := NVL(:new.REVER_SIG_PERIOD, ' ');
  :new.TEXTO_ENCADENADO  := NVL(:new.TEXTO_ENCADENADO, ' ');
  :new.BANDERA_PRELIMIN  := NVL(:new.BANDERA_PRELIMIN, ' ');
  :new.BANDERA_USO       := NVL(:new.BANDERA_USO, ' ');

END trg_msj_datossolicitud_biu;
/
