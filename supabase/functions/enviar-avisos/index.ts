// Capsoul · Edge Function enviar-avisos (DEV-100)
// Lee notificaciones pendientes y despacha push (FCM) o correo (Resend).
// Secretos: SUPABASE_SERVICE_ROLE_KEY (automático), FCM_* o GOOGLE_SERVICE_ACCOUNT_JSON,
// RESEND_API_KEY, RESEND_FROM (opcional).

import { createClient } from "npm:@supabase/supabase-js@2.117.2";
import {
  destinoValido,
  puedeReintentar,
  type FilaNotificacion,
} from "./despacho.ts";

const LOTE = 25;

function leerEntorno(nombre: string): string {
  const valor = Deno.env.get(nombre);
  if (!valor) throw new Error(`Falta la variable de entorno ${nombre}`);
  return valor;
}

async function enviarCorreoResend(
  destino: string,
  titulo: string,
  cuerpo: string,
): Promise<void> {
  const apiKey = Deno.env.get("RESEND_API_KEY");
  if (!apiKey) throw new Error("RESEND_API_KEY no configurada");
  const desde = Deno.env.get("RESEND_FROM") ?? "Capsoul <avisos@capsoul.app>";
  const respuesta = await fetch("https://api.resend.com/emails", {
    method: "POST",
    headers: {
      Authorization: `Bearer ${apiKey}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify({
      from: desde,
      to: [destino],
      subject: titulo,
      text: cuerpo,
    }),
  });
  if (!respuesta.ok) {
    const texto = await respuesta.text();
    throw new Error(`Resend ${respuesta.status}: ${texto}`);
  }
}

async function enviarPushFcm(
  supabase: ReturnType<typeof createClient>,
  usuarioId: string,
  titulo: string,
  cuerpo: string,
): Promise<void> {
  const { data: dispositivos, error } = await supabase
    .from("dispositivos_push")
    .select("token_fcm")
    .eq("usuario_id", usuarioId);
  if (error) throw error;
  const tokens = (dispositivos ?? [])
    .map((fila) => fila.token_fcm as string)
    .filter((t) => t.length > 10);
  if (tokens.length === 0) {
    throw new Error("Sin tokens FCM para el usuario");
  }
  const serverKey = Deno.env.get("FCM_SERVER_KEY");
  if (!serverKey) {
    throw new Error("FCM_SERVER_KEY no configurada (legacy HTTP para cron)");
  }
  for (const token of tokens) {
    const respuesta = await fetch("https://fcm.googleapis.com/fcm/send", {
      method: "POST",
      headers: {
        Authorization: `key=${serverKey}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        to: token,
        notification: { title: titulo, body: cuerpo },
      }),
    });
    if (!respuesta.ok) {
      const texto = await respuesta.text();
      throw new Error(`FCM ${respuesta.status}: ${texto}`);
    }
  }
}

async function marcar(
  supabase: ReturnType<typeof createClient>,
  id: string,
  estado: "enviada" | "fallida",
  intentos: number,
  ultimoError: string | null,
): Promise<void> {
  const cambios: Record<string, unknown> = {
    estado,
    intentos,
    ultimo_error: ultimoError,
  };
  if (estado === "enviada") cambios.enviada_en = new Date().toISOString();
  const { error } = await supabase.from("notificaciones").update(cambios).eq("id", id);
  if (error) throw error;
}

Deno.serve(async (solicitud: Request): Promise<Response> => {
  if (solicitud.method !== "POST") {
    return new Response(JSON.stringify({ codigo: "metodo_no_permitido" }), {
      status: 405,
    });
  }
  try {
    const url = leerEntorno("SUPABASE_URL");
    const serviceKey = leerEntorno("SUPABASE_SERVICE_ROLE_KEY");
    const supabase = createClient(url, serviceKey);

    const { data: pendientes, error: lectura } = await supabase
      .from("notificaciones")
      .select("id, canal, usuario_id, correo_destino, titulo, cuerpo, intentos")
      .eq("estado", "pendiente")
      .order("creado_en", { ascending: true })
      .limit(LOTE);
    if (lectura) throw lectura;

    let enviadas = 0;
    let fallidas = 0;

    for (const fila of pendientes ?? []) {
      const notificacion = fila as FilaNotificacion;
      if (!destinoValido(notificacion)) {
        await marcar(
          supabase,
          notificacion.id,
          "fallida",
          notificacion.intentos + 1,
          "Destino inválido para el canal",
        );
        fallidas++;
        continue;
      }
      try {
        if (notificacion.canal === "correo") {
          await enviarCorreoResend(
            notificacion.correo_destino!.trim(),
            notificacion.titulo,
            notificacion.cuerpo,
          );
        } else {
          await enviarPushFcm(
            supabase,
            notificacion.usuario_id!,
            notificacion.titulo,
            notificacion.cuerpo,
          );
        }
        await marcar(supabase, notificacion.id, "enviada", notificacion.intentos, null);
        enviadas++;
      } catch (error) {
        const mensaje = error instanceof Error ? error.message : String(error);
        const nuevosIntentos = notificacion.intentos + 1;
        const estado = puedeReintentar(nuevosIntentos) ? "pendiente" : "fallida";
        const { error: updateError } = await supabase
          .from("notificaciones")
          .update({
            estado,
            intentos: nuevosIntentos,
            ultimo_error: mensaje,
          })
          .eq("id", notificacion.id);
        if (updateError) throw updateError;
        fallidas++;
      }
    }

    return new Response(
      JSON.stringify({ procesadas: (pendientes ?? []).length, enviadas, fallidas }),
      { status: 200, headers: { "Content-Type": "application/json" } },
    );
  } catch (error) {
    const mensaje = error instanceof Error ? error.message : String(error);
    return new Response(JSON.stringify({ codigo: "error_interno", mensaje }), {
      status: 500,
    });
  }
});
