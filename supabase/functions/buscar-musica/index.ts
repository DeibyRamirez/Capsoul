// Capsoul · Edge Function buscar-musica (Deno). verify_jwt: true en Supabase.
// Búsqueda de pistas en la API pública de Deezer. No usa secretos de catálogo.

import { createClient } from "npm:@supabase/supabase-js@2.117.2";

import { acotarLimite, buscarEnDeezer, ErrorBusquedaDeezer } from "./deezer.ts";

const CABECERAS_CORS = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

interface SolicitudBuscar {
  consulta?: string;
  limite?: number;
  // Se acepta por compatibilidad del cliente. Deezer no filtra por país en /search.
  mercado?: string;
}

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

  let urlSupabase: string;
  let claveServicio: string;
  try {
    urlSupabase = leerEntorno("SUPABASE_URL");
    claveServicio = leerEntorno("SUPABASE_SERVICE_ROLE_KEY");
  } catch (e) {
    console.error(e instanceof Error ? e.message : e);
    return error(500, "configuracion", "La búsqueda de música no está configurada.");
  }

  const autorizacion = solicitud.headers.get("Authorization") ?? "";
  if (!autorizacion.startsWith("Bearer ")) {
    return error(401, "no_autenticado", "Inicia sesión para buscar música.");
  }
  const jwtUsuario = autorizacion.slice("Bearer ".length).trim();
  const supabaseAuth = createClient(urlSupabase, claveServicio, {
    auth: { persistSession: false, autoRefreshToken: false },
  });
  const { data: datosUsuario, error: errorUsuario } = await supabaseAuth.auth.getUser(jwtUsuario);
  if (errorUsuario || !datosUsuario?.user) {
    return error(401, "no_autenticado", "Tu sesión expiró. Vuelve a iniciar sesión.");
  }

  let cuerpo: SolicitudBuscar;
  try {
    cuerpo = await solicitud.json();
  } catch {
    return error(422, "cuerpo_invalido", "El cuerpo debe ser JSON.");
  }

  const consulta = (cuerpo.consulta ?? "").trim();
  if (consulta.length < 1 || consulta.length > 200) {
    return error(422, "consulta_invalida", "Escribe entre 1 y 200 caracteres.");
  }

  const limite = acotarLimite(cuerpo.limite);

  try {
    const resultados = await buscarEnDeezer(consulta, limite);
    return responder(200, { resultados });
  } catch (e) {
    if (e instanceof ErrorBusquedaDeezer) {
      return error(502, e.codigo, e.message);
    }
    console.error(e);
    return error(500, "error_interno", "Error al buscar música.");
  }
});
