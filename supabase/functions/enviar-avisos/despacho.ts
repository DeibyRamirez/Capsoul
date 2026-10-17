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
