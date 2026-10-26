/** Lógica pura del despacho de notificaciones (pruebas sin red). */

export type CanalNotificacion = "push" | "correo";

export type FilaNotificacion = {
  id: string;
  canal: CanalNotificacion;
  usuario_id: string | null;
  correo_destino: string | null;
  titulo: string;
  cuerpo: string;
  intentos: number;
};

export type ResultadoDespacho = "enviada" | "fallida" | "omitida";

export type EstadoCierre = "enviada" | "pendiente" | "fallida";

export type CierreAviso = {
  estado: EstadoCierre;
  intentos: number;
  liberarReclamo: boolean;
  ultimoError: string | null;
};

/** Header que envía pg_cron. verify_jwt está apagado: esta llave es la puerta. */
export const ENCABEZADO_LLAVE_CRON = "x-llave-cron";

const MAX_INTENTOS = 5;

export function puedeReintentar(intentos: number): boolean {
  return intentos < MAX_INTENTOS;
}

/** Decide si la fila tiene destino válido para el canal. */
export function destinoValido(fila: FilaNotificacion): boolean {
  if (fila.canal === "push") return fila.usuario_id != null;
  if (fila.canal === "correo") {
    const correo = fila.correo_destino?.trim();
    return correo != null && correo.length > 3 && correo.includes("@");
  }
  return false;
}

export function resultadoSinDestino(fila: FilaNotificacion): ResultadoDespacho {
  return destinoValido(fila) ? "omitida" : "fallida";
}

/**
 * Cierra el aviso según lo que pasó con cada token.
 * Un token ya enviado no se vuelve a contar como fallo.
 * Sin dispositivos se reintenta: el usuario puede registrar uno después.
 * Si todos los tokens eran inválidos, no queda nada que reintentar.
 */
export function decidirCierre(entrada: {
  intentos: number;
  enviados: number;
  invalidos: number;
  fallos: number;
  sinTokens: boolean;
  error: string | null;
}): CierreAviso {
  const falloTransporte = entrada.fallos > 0 || entrada.sinTokens;
  if (!falloTransporte && entrada.enviados > 0) {
    return {
      estado: "enviada",
      intentos: entrada.intentos,
      liberarReclamo: false,
      ultimoError: null,
    };
  }
  if (!falloTransporte && entrada.invalidos > 0) {
    return {
      estado: "fallida",
      intentos: entrada.intentos + 1,
      liberarReclamo: false,
      ultimoError: entrada.error,
    };
  }
  const intentos = entrada.intentos + 1;
  if (puedeReintentar(intentos)) {
    return {
      estado: "pendiente",
      intentos,
      liberarReclamo: true,
      ultimoError: entrada.error,
    };
  }
  return {
    estado: "fallida",
    intentos,
    liberarReclamo: false,
    ultimoError: entrada.error,
  };
}

/** Comparación en tiempo constante. Llave vacía nunca autoriza. */
export function compararLlave(recibida: string | null, esperada: string): boolean {
  if (!esperada) return false;
  const encoder = new TextEncoder();
  const izquierda = encoder.encode(recibida ?? "");
  const derecha = encoder.encode(esperada);
  const largo = Math.max(izquierda.length, derecha.length);
  let diferencia = izquierda.length === derecha.length ? 0 : 1;
  for (let i = 0; i < largo; i++) {
    diferencia |= (izquierda[i] ?? 0) ^ (derecha[i] ?? 0);
  }
  return diferencia === 0;
}
