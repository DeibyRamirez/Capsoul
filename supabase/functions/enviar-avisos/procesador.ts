/** Orquesta un lote: reclamo, plantilla, envío por token y cierre. */

import {
  compararLlave,
  decidirCierre,
  destinoValido,
  type CanalNotificacion,
  type FilaNotificacion,
} from "./despacho.ts";
import { tokenInvalido, type ResultadoEnvioFcm } from "./fcm.ts";
import { armarContenido } from "./plantillas.ts";

export const LOTE_AVISOS = 25;

export type FilaAviso = {
  id: string;
  canal: CanalNotificacion;
  tipo: string;
  usuario_id: string | null;
  correo_destino: string | null;
  referencia_id: string;
  titulo: string;
  cuerpo: string;
  intentos: number;
};

export type EntregaConocida = {
  token: string;
  estado: "pendiente" | "enviada" | "fallida" | "invalida";
  intentos: number;
};

export type CierrePedido = {
  id: string;
  estado: "enviada" | "pendiente" | "fallida";
  intentos: number;
  ultimoError: string | null;
  liberarReclamo: boolean;
};

export type DependenciasAvisos = {
  llaveCron: string;
  reclamar: (lote: number) => Promise<FilaAviso[]>;
  tituloReferencia: (fila: FilaAviso) => Promise<string | null>;
  tokensDe: (usuarioId: string) => Promise<string[]>;
  entregasDe: (notificacionId: string) => Promise<EntregaConocida[]>;
  guardarEntrega: (args: {
    notificacionId: string;
    token: string;
    estado: "enviada" | "fallida" | "invalida";
    intentos: number;
    ultimoError: string | null;
  }) => Promise<void>;
  borrarToken: (token: string) => Promise<void>;
  cerrar: (pedido: CierrePedido) => Promise<void>;
  enviarPush: (args: {
    token: string;
    titulo: string;
    cuerpo: string;
    data: Record<string, string>;
  }) => Promise<ResultadoEnvioFcm>;
  enviarCorreo: (destino: string, titulo: string, cuerpo: string) => Promise<void>;
};

export type ResumenLote = {
  procesadas: number;
  enviadas: number;
  fallidas: number;
};

function json(cuerpo: unknown, status: number): Response {
  return new Response(JSON.stringify(cuerpo), {
    status,
    headers: { "Content-Type": "application/json" },
  });
}

function comoFila(fila: FilaAviso): FilaNotificacion {
  return {
    id: fila.id,
    canal: fila.canal,
    usuario_id: fila.usuario_id,
    correo_destino: fila.correo_destino,
    titulo: fila.titulo,
    cuerpo: fila.cuerpo,
    intentos: fila.intentos,
  };
}

function mensajeDe(error: unknown): string {
  const texto = error instanceof Error ? error.message : String(error);
  return texto.slice(0, 500);
}

export async function atenderAvisos(
  solicitud: Request,
  deps: DependenciasAvisos,
): Promise<Response> {
  if (solicitud.method !== "POST") {
    return json({ codigo: "metodo_no_permitido" }, 405);
  }
  const recibida = solicitud.headers.get("x-llave-cron");
  if (!compararLlave(recibida, deps.llaveCron)) {
    return json({ codigo: "no_autorizado" }, 401);
  }
  try {
    const resumen = await procesarLote(deps);
    return json(resumen, 200);
  } catch (error) {
    return json({ codigo: "error_interno", mensaje: mensajeDe(error) }, 500);
  }
}

export async function procesarLote(deps: DependenciasAvisos): Promise<ResumenLote> {
  const reclamadas = await deps.reclamar(LOTE_AVISOS);
  const vistas = new Set<string>();
  let enviadas = 0;
  let fallidas = 0;

  for (const fila of reclamadas) {
    if (vistas.has(fila.id)) continue;
    vistas.add(fila.id);
    try {
      const estado = await despacharFila(fila, deps);
      if (estado === "enviada") enviadas++;
      else fallidas++;
    } catch (error) {
      fallidas++;
      try {
        await deps.cerrar({
          id: fila.id,
          estado: "pendiente",
          intentos: fila.intentos,
          ultimoError: mensajeDe(error),
          liberarReclamo: true,
        });
      } catch {
        // El reclamo vence a los 5 minutos y otro worker lo retoma.
      }
    }
  }

  return { procesadas: vistas.size, enviadas, fallidas };
}

async function despacharFila(
  fila: FilaAviso,
  deps: DependenciasAvisos,
): Promise<"enviada" | "pendiente" | "fallida"> {
  if (!destinoValido(comoFila(fila))) {
    await deps.cerrar({
      id: fila.id,
      estado: "fallida",
      intentos: fila.intentos + 1,
      ultimoError: "Destino inválido para el canal",
      liberarReclamo: false,
    });
    return "fallida";
  }

  const tituloReferencia = await deps.tituloReferencia(fila);
  const contenido = armarContenido({
    tipo: fila.tipo,
    referenciaId: fila.referencia_id,
    tituloGuardado: fila.titulo,
    cuerpoGuardado: fila.cuerpo,
    tituloReferencia,
  });

  if (fila.canal === "correo") {
    try {
      await deps.enviarCorreo(
        fila.correo_destino!.trim(),
        contenido.titulo,
        contenido.cuerpo,
      );
      await deps.cerrar({
        id: fila.id,
        estado: "enviada",
        intentos: fila.intentos,
        ultimoError: null,
        liberarReclamo: false,
      });
      return "enviada";
    } catch (error) {
      const cierre = decidirCierre({
        intentos: fila.intentos,
        enviados: 0,
        invalidos: 0,
        fallos: 1,
        sinTokens: false,
        error: mensajeDe(error),
      });
      await deps.cerrar({ id: fila.id, ...cierre });
      return cierre.estado;
    }
  }

  const tokens = await deps.tokensDe(fila.usuario_id!);
  const previas = await deps.entregasDe(fila.id);
  const porToken = new Map(previas.map((entrega) => [entrega.token, entrega]));

  let enviados = 0;
  let invalidos = 0;
  let fallos = 0;
  let ultimoError: string | null = null;

  for (const token of tokens) {
    const previa = porToken.get(token);
    if (previa?.estado === "enviada") {
      enviados++;
      continue;
    }
    if (previa?.estado === "invalida") {
      invalidos++;
      continue;
    }
    const resultado = await deps.enviarPush({
      token,
      titulo: contenido.titulo,
      cuerpo: contenido.cuerpo,
      data: contenido.data,
    });
    const intentosToken = (previa?.intentos ?? 0) + 1;
    if (resultado.ok) {
      enviados++;
      await deps.guardarEntrega({
        notificacionId: fila.id,
        token,
        estado: "enviada",
        intentos: intentosToken,
        ultimoError: null,
      });
      continue;
    }
    if (tokenInvalido(resultado.codigo)) {
      invalidos++;
      await deps.borrarToken(token);
      await deps.guardarEntrega({
        notificacionId: fila.id,
        token,
        estado: "invalida",
        intentos: intentosToken,
        ultimoError: resultado.codigo,
      });
      continue;
    }
    fallos++;
    ultimoError = resultado.detalle || resultado.codigo || "FCM rechazó el envío";
    await deps.guardarEntrega({
      notificacionId: fila.id,
      token,
      estado: "fallida",
      intentos: intentosToken,
      ultimoError,
    });
  }

  const cierre = decidirCierre({
    intentos: fila.intentos,
    enviados,
    invalidos,
    fallos,
    sinTokens: tokens.length === 0,
    error: ultimoError ?? (invalidos > 0 ? "Token FCM inválido" : "Sin tokens FCM"),
  });
  await deps.cerrar({ id: fila.id, ...cierre });
  return cierre.estado;
}
