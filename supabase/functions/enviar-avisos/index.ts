// Capsoul · Edge Function enviar-avisos (DEV-100)
// verify_jwt = false: la puerta es el header x-llave-cron (LLAVE_CRON).
// Push: FCM HTTP v1 con cuenta de servicio. Correo: Resend.
// Secretos (nunca en el repo): LLAVE_CRON, FCM_PROJECT_ID, FCM_CLIENT_EMAIL,
// FCM_PRIVATE_KEY, RESEND_API_KEY, RESEND_FROM (opcional),
// SUPABASE_URL y SUPABASE_SERVICE_ROLE_KEY (los inyecta Supabase).

import { createClient, type SupabaseClient } from "npm:@supabase/supabase-js@2.117.2";
import {
  CacheTokenOauth,
  enviarMensajeFcm,
  type CredencialesFcm,
} from "./fcm.ts";
import {
  atenderAvisos,
  type EntregaConocida,
  type FilaAviso,
} from "./procesador.ts";

const cacheOauth = new CacheTokenOauth(() => Math.floor(Date.now() / 1000));

function leerEntorno(nombre: string): string {
  const valor = Deno.env.get(nombre);
  if (!valor) throw new Error(`Falta la variable de entorno ${nombre}`);
  return valor;
}

function credencialesFcm(): CredencialesFcm {
  return {
    projectId: leerEntorno("FCM_PROJECT_ID"),
    clientEmail: leerEntorno("FCM_CLIENT_EMAIL"),
    privateKeyPem: leerEntorno("FCM_PRIVATE_KEY"),
  };
}

function cliente(): SupabaseClient {
  return createClient(
    leerEntorno("SUPABASE_URL"),
    leerEntorno("SUPABASE_SERVICE_ROLE_KEY"),
    { auth: { persistSession: false, autoRefreshToken: false } },
  );
}

function exigir<T>(resultado: { data: T; error: { message: string } | null }): T {
  if (resultado.error) throw new Error(resultado.error.message);
  return resultado.data;
}

function filaDesde(row: Record<string, unknown>): FilaAviso {
  return {
    id: String(row.id),
    canal: row.canal === "correo" ? "correo" : "push",
    tipo: String(row.tipo ?? ""),
    usuario_id: row.usuario_id == null ? null : String(row.usuario_id),
    correo_destino: row.correo_destino == null ? null : String(row.correo_destino),
    referencia_id: String(row.referencia_id ?? ""),
    titulo: String(row.titulo ?? ""),
    cuerpo: String(row.cuerpo ?? ""),
    intentos: Number(row.intentos ?? 0),
  };
}

async function tituloReferencia(
  supabase: SupabaseClient,
  fila: FilaAviso,
): Promise<string | null> {
  const tabla = fila.tipo === "capsula_liberada"
    ? "capsulas"
    : fila.tipo === "reto"
    ? "retos"
    : null;
  if (!tabla || !fila.referencia_id) return null;
  const resultado = await supabase
    .from(tabla)
    .select("titulo")
    .eq("id", fila.referencia_id)
    .maybeSingle();
  const data = exigir(resultado) as { titulo?: unknown } | null;
  const titulo = data?.titulo;
  return typeof titulo === "string" && titulo.trim() !== "" ? titulo.trim() : null;
}

Deno.serve((solicitud: Request) => {
  return atenderAvisos(solicitud, {
    llaveCron: Deno.env.get("LLAVE_CRON") ?? "",
    reclamar: async (lote) => {
      const supabase = cliente();
      const resultado = await supabase.rpc("reclamar_avisos", { p_lote: lote });
      const filas = exigir(resultado) as Record<string, unknown>[] | null;
      return (filas ?? []).map(filaDesde);
    },
    tituloReferencia: (fila) => tituloReferencia(cliente(), fila),
    tokensDe: async (usuarioId) => {
      const resultado = await cliente()
        .from("dispositivos_push")
        .select("token_fcm")
        .eq("usuario_id", usuarioId);
      const filas = exigir(resultado) as { token_fcm: string }[] | null;
      return (filas ?? [])
        .map((fila) => fila.token_fcm)
        .filter((token) => typeof token === "string" && token.length > 10);
    },
    entregasDe: async (notificacionId) => {
      const resultado = await cliente()
        .from("notificacion_entregas")
        .select("token_fcm, estado, intentos")
        .eq("notificacion_id", notificacionId);
      const filas = exigir(resultado) as Record<string, unknown>[] | null;
      return (filas ?? []).map((fila): EntregaConocida => ({
        token: String(fila.token_fcm),
        estado: fila.estado as EntregaConocida["estado"],
        intentos: Number(fila.intentos ?? 0),
      }));
    },
    guardarEntrega: async (args) => {
      const resultado = await cliente()
        .from("notificacion_entregas")
        .upsert({
          notificacion_id: args.notificacionId,
          token_fcm: args.token,
          estado: args.estado,
          intentos: args.intentos,
          ultimo_error: args.ultimoError,
        }, { onConflict: "notificacion_id,token_fcm" });
      exigir(resultado);
    },
    borrarToken: async (token) => {
      const resultado = await cliente()
        .from("dispositivos_push")
        .delete()
        .eq("token_fcm", token);
      exigir(resultado);
    },
    cerrar: async (pedido) => {
      const cambios: Record<string, unknown> = {
        estado: pedido.estado,
        intentos: pedido.intentos,
        ultimo_error: pedido.ultimoError,
      };
      if (pedido.estado === "enviada") cambios.enviada_en = new Date().toISOString();
      if (pedido.liberarReclamo) cambios.reclamado_en = null;
      const resultado = await cliente()
        .from("notificaciones")
        .update(cambios)
        .eq("id", pedido.id);
      exigir(resultado);
    },
    enviarPush: (args) =>
      enviarMensajeFcm({
        credenciales: credencialesFcm(),
        cache: cacheOauth,
        ahoraSegundos: () => Math.floor(Date.now() / 1000),
        fetchImpl: fetch,
        ...args,
      }),
    enviarCorreo: async (destino, titulo, cuerpo) => {
      const apiKey = leerEntorno("RESEND_API_KEY");
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
        throw new Error(`Resend ${respuesta.status}: ${texto.slice(0, 300)}`);
      }
    },
  });
});
