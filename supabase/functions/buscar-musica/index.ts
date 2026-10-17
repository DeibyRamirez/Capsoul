// Capsoul · Edge Function buscar-musica (Deno). verify_jwt: true en Supabase.
// Búsqueda de pistas en Spotify (Client Credentials). Secretos:
//   SPOTIFY_CLIENT_ID, SPOTIFY_CLIENT_SECRET

import { createClient } from "npm:@supabase/supabase-js@2.117.2";

import {
  buscarPreviewDeezer,
  MAX_FALLBACKS_DEEZER,
} from "./deezer_preview.ts";

const CABECERAS_CORS = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

// Spotify (development mode, 2026): GET /search acepta limit máx. 10.
const LIMITE_MAX = 10;
const MERCADO_DEFECTO = "CO";

interface SolicitudBuscar {
  consulta?: string;
  limite?: number;
  mercado?: string;
}

interface PistaSpotify {
  id: string;
  name: string;
  preview_url: string | null;
  uri: string;
  external_urls?: { spotify?: string };
  album?: { images?: { url: string }[] };
  artists?: { name: string }[];
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

function normalizarMercado(mercado: string | undefined): string {
  const codigo = (mercado ?? MERCADO_DEFECTO).trim().toUpperCase();
  if (!/^[A-Z]{2}$/.test(codigo)) return MERCADO_DEFECTO;
  return codigo;
}

interface ResultadoPista {
  proveedor: "spotify";
  idExterno: string;
  titulo: string;
  artista: string;
  previewUrl: string | null;
  previewProveedor: "spotify" | "deezer" | null;
  enlaceDeezer: string | null;
  urlCompleta: string;
  uriProfundo: string;
  portadaUrl: string | null;
}

function mapearPista(pista: PistaSpotify): ResultadoPista {
  const artista = pista.artists?.map((a) => a.name).join(", ") ?? "";
  const portada = pista.album?.images?.[0]?.url ?? null;
  const urlCompleta = pista.external_urls?.spotify ?? `https://open.spotify.com/track/${pista.id}`;
  const previewSpotify = pista.preview_url?.trim() || null;
  return {
    proveedor: "spotify",
    idExterno: pista.id,
    titulo: pista.name,
    artista,
    previewUrl: previewSpotify,
    previewProveedor: previewSpotify ? "spotify" : null,
    enlaceDeezer: null,
    urlCompleta,
    uriProfundo: pista.uri,
    portadaUrl: portada,
  };
}

async function enriquecerPreviewsDeezer(resultados: ResultadoPista[]): Promise<void> {
  let fallbacks = 0;
  const pendientes: Promise<void>[] = [];

  for (const pista of resultados) {
    if (pista.previewUrl || fallbacks >= MAX_FALLBACKS_DEEZER) continue;
    fallbacks += 1;
    pendientes.push(
      (async () => {
        const resultado = await buscarPreviewDeezer(pista.artista, pista.titulo);
        if (resultado) {
          pista.previewUrl = resultado.previewUrl;
          pista.previewProveedor = "deezer";
          pista.enlaceDeezer = resultado.deezerTrackUrl;
        }
      })(),
    );
  }

  await Promise.all(pendientes);
}

let tokenCache: { valor: string; expira: number } | null = null;

async function tokenSpotify(clientId: string, clientSecret: string): Promise<string> {
  const ahora = Date.now();
  if (tokenCache && tokenCache.expira > ahora + 60_000) {
    return tokenCache.valor;
  }
  const cuerpo = new URLSearchParams({ grant_type: "client_credentials" });
  const respuesta = await fetch("https://accounts.spotify.com/api/token", {
    method: "POST",
    headers: {
      "Content-Type": "application/x-www-form-urlencoded",
      Authorization: `Basic ${btoa(`${clientId}:${clientSecret}`)}`,
    },
    body: cuerpo,
  });
  if (!respuesta.ok) {
    const cuerpo = await respuesta.text();
    console.error("Spotify token:", respuesta.status, cuerpo);
    if (respuesta.status === 400 || respuesta.status === 401) {
      throw new Error("credenciales_spotify");
    }
    throw new Error("token_spotify");
  }
  const datos = await respuesta.json();
  const token = datos.access_token as string;
  const segundos = (datos.expires_in as number) ?? 3600;
  tokenCache = { valor: token, expira: ahora + segundos * 1000 };
  return token;
}

Deno.serve(async (solicitud: Request): Promise<Response> => {
  if (solicitud.method === "OPTIONS") return new Response("ok", { headers: CABECERAS_CORS });
  if (solicitud.method !== "POST") {
    return error(405, "metodo_no_permitido", "Método no permitido.");
  }

  let spotifyId: string;
  let spotifySecret: string;
  let urlSupabase: string;
  let claveServicio: string;
  try {
    spotifyId = leerEntorno("SPOTIFY_CLIENT_ID").trim();
    spotifySecret = leerEntorno("SPOTIFY_CLIENT_SECRET").trim();
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

  const limite = Math.min(
    LIMITE_MAX,
    Math.max(1, Math.floor(cuerpo.limite ?? LIMITE_MAX)),
  );
  const mercado = normalizarMercado(cuerpo.mercado);

  try {
    const token = await tokenSpotify(spotifyId, spotifySecret);
    const params = new URLSearchParams({
      q: consulta,
      type: "track",
      limit: String(limite),
      market: mercado,
    });
    const respuesta = await fetch(
      `https://api.spotify.com/v1/search?${params}`,
      { headers: { Authorization: `Bearer ${token}` } },
    );
    if (!respuesta.ok) {
      const cuerpoError = await respuesta.text();
      console.error("Spotify search:", respuesta.status, cuerpoError);
      if (respuesta.status === 400) {
        return error(
          502,
          "spotify_parametros",
          "Parámetros de búsqueda no válidos para Spotify. Si persiste, avisa al equipo.",
        );
      }
      if (respuesta.status === 403) {
        return error(
          502,
          "spotify_acceso",
          "Spotify rechazó la búsqueda. La cuenta dueña de la app en Spotify Developer debe tener Premium activo.",
        );
      }
      if (respuesta.status === 429) {
        return error(
          502,
          "spotify_cuota",
          "Se alcanzó el límite de búsquedas en Spotify. Intenta en unos minutos.",
        );
      }
      return error(502, "spotify_error", "No se pudo buscar en Spotify. Intenta más tarde.");
    }
    const datos = await respuesta.json();
    const items = (datos.tracks?.items ?? []) as PistaSpotify[];
    const resultados = items.filter((p) => p.id && p.name).map(mapearPista);
    await enriquecerPreviewsDeezer(resultados);
    return responder(200, { resultados });
  } catch (e) {
    if (e instanceof Error && e.message === "credenciales_spotify") {
      return error(
        502,
        "spotify_credenciales",
        "Spotify rechazó las credenciales del servidor. Revisa Client ID y Secret en el Dashboard de Spotify.",
      );
    }
    if (e instanceof Error && e.message === "token_spotify") {
      return error(502, "spotify_error", "No se pudo conectar con Spotify.");
    }
    console.error(e);
    return error(500, "error_interno", "Error al buscar música.");
  }
});
