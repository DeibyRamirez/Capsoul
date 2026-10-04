// Capsoul · Edge Function firmar-subida (Deno).
// Firma una subida directa a Cloudinary (type=authenticated, public_id aleatorio) para el
// usuario autenticado, después de validar tipo, tamaño, duración y cuota de 200 MB.
// Secretos (supabase secrets set, NUNCA en el repo):
//   CLOUDINARY_CLOUD_NAME, CLOUDINARY_API_KEY, CLOUDINARY_API_SECRET
// SUPABASE_URL y SUPABASE_ANON_KEY los inyecta Supabase automáticamente.
// Requiere la migración 20261003000003 (RPC public.mi_uso_medios).

import { createClient } from "npm:@supabase/supabase-js@2.117.2";
import {
  ErrorSolicitud,
  firmarParametros,
  generarPublicId,
  parametrosAFirmar,
  urlSubida,
  validarCuota,
  validarSolicitud,
} from "./limites.ts";

const CABECERAS_CORS = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

function responder(estado: number, cuerpo: unknown): Response {
  return new Response(JSON.stringify(cuerpo), {
    status: estado,
    headers: { ...CABECERAS_CORS, "Content-Type": "application/json; charset=utf-8" },
  });
}

function error(estado: number, codigo: string, mensaje: string): Response {
  return responder(estado, { codigo, mensaje });
}

function leerEntorno(nombre: string): string {
  const valor = Deno.env.get(nombre);
  if (!valor) throw new Error(`Falta la variable de entorno ${nombre}`);
  return valor;
}

Deno.serve(async (solicitud: Request): Promise<Response> => {
  if (solicitud.method === "OPTIONS") return new Response("ok", { headers: CABECERAS_CORS });
  if (solicitud.method !== "POST") {
    return error(405, "metodo_no_permitido", "Método no permitido.");
  }

  let configuracion: { cloudName: string; apiKey: string; apiSecret: string; url: string; anon: string };
  try {
    configuracion = {
      cloudName: leerEntorno("CLOUDINARY_CLOUD_NAME"),
      apiKey: leerEntorno("CLOUDINARY_API_KEY"),
      apiSecret: leerEntorno("CLOUDINARY_API_SECRET"),
      url: leerEntorno("SUPABASE_URL"),
      anon: leerEntorno("SUPABASE_ANON_KEY"),
    };
  } catch (e) {
    console.error(e instanceof Error ? e.message : e);
    return error(500, "configuracion", "La subida no está configurada todavía.");
  }

  // 1. JWT del usuario (además de la verificación de la plataforma, verify_jwt).
  const autorizacion = solicitud.headers.get("Authorization") ?? "";
  if (!autorizacion.startsWith("Bearer ")) {
    return error(401, "no_autenticado", "Inicia sesión para subir archivos.");
  }
  const supabase = createClient(configuracion.url, configuracion.anon, {
    global: { headers: { Authorization: autorizacion } },
    auth: { persistSession: false, autoRefreshToken: false },
  });
  const { data: datosUsuario, error: errorUsuario } = await supabase.auth.getUser(
    autorizacion.slice("Bearer ".length),
  );
  if (errorUsuario || !datosUsuario?.user) {
    return error(401, "no_autenticado", "Tu sesión expiró. Vuelve a iniciar sesión.");
  }

  try {
    // 2. Tipo, tamaño, duración y formato declarados.
    let cuerpo: unknown;
    try {
      cuerpo = await solicitud.json();
    } catch {
      throw new ErrorSolicitud(422, "solicitud_invalida", "La solicitud no es válida.");
    }
    const pedido = validarSolicitud(cuerpo);

    // 3. Cuota de 200 MB (RPC con el JWT del usuario: solo ve su propio uso).
    const { data: uso, error: errorUso } = await supabase.rpc("mi_uso_medios").single();
    if (errorUso || !uso) {
      console.error("mi_uso_medios falló", errorUso?.message);
      return error(500, "cuota_no_disponible", "No pudimos revisar tu espacio. Intenta de nuevo.");
    }
    const { bytes_usados, bytes_limite } = uso as { bytes_usados: number; bytes_limite: number };
    validarCuota(Number(bytes_usados), pedido.bytes, Number(bytes_limite));

    // 4. Firma.
    const timestamp = Math.floor(Date.now() / 1000);
    const parametros = parametrosAFirmar(pedido.tipo, generarPublicId(), timestamp);
    const signature = await firmarParametros(parametros, configuracion.apiSecret);

    return responder(200, {
      url_subida: urlSubida(configuracion.cloudName, pedido.tipo),
      parametros: { ...parametros, api_key: configuracion.apiKey, signature },
    });
  } catch (e) {
    if (e instanceof ErrorSolicitud) return error(e.estado, e.codigo, e.message);
    console.error("firmar-subida: error inesperado", e instanceof Error ? e.message : e);
    return error(500, "error_interno", "No pudimos preparar la subida. Intenta de nuevo.");
  }
});
