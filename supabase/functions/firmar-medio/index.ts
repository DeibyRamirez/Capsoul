// Capsoul · Edge Function firmar-medio (Deno).
// Devuelve URLs temporales para ver los medios (type=authenticated) de los recuerdos que el
// usuario puede ver. La consulta a `elementos` usa el JWT del usuario, así que RLS decide
// qué filas existen para él: lo que no puede ver simplemente no se firma.
// Secretos (supabase secrets set, NUNCA en el repo):
//   CLOUDINARY_CLOUD_NAME, CLOUDINARY_API_KEY, CLOUDINARY_API_SECRET
// SUPABASE_URL y SUPABASE_ANON_KEY los inyecta Supabase automáticamente.

import { createClient } from "npm:@supabase/supabase-js@2.117.2";
import {
  type Credenciales,
  ErrorSolicitud,
  type FilaMedio,
  esSolicitudAvatarPerfil,
  esSolicitudAvataresUsuarios,
  firmarMedios,
  validarAvataresUsuarioIds,
  validarSolicitud,
} from "./firma_entrega.ts";

const CABECERAS_CORS = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

function responder(estado: number, cuerpo: unknown): Response {
  return new Response(JSON.stringify(cuerpo), {
    status: estado,
    headers: {
      ...CABECERAS_CORS,
      "Content-Type": "application/json; charset=utf-8",
      "Cache-Control": "no-store",
    },
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

  let credenciales: Credenciales;
  let url: string;
  let anon: string;
  try {
    credenciales = {
      cloudName: leerEntorno("CLOUDINARY_CLOUD_NAME"),
      apiKey: leerEntorno("CLOUDINARY_API_KEY"),
      apiSecret: leerEntorno("CLOUDINARY_API_SECRET"),
    };
    url = leerEntorno("SUPABASE_URL");
    anon = leerEntorno("SUPABASE_ANON_KEY");
  } catch (e) {
    console.error(e instanceof Error ? e.message : e);
    return error(500, "configuracion", "La entrega de medios no está configurada todavía.");
  }

  // 1. JWT del usuario (además de la verificación de la plataforma, verify_jwt).
  const autorizacion = solicitud.headers.get("Authorization") ?? "";
  if (!autorizacion.startsWith("Bearer ")) {
    return error(401, "no_autenticado", "Inicia sesión para ver tus recuerdos.");
  }
  const supabase = createClient(url, anon, {
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
    let cuerpo: unknown;
    try {
      cuerpo = await solicitud.json();
    } catch {
      throw new ErrorSolicitud(422, "solicitud_invalida", "La solicitud no es válida.");
    }
    if (esSolicitudAvatarPerfil(cuerpo)) {
      const uid = datosUsuario.user.id;
      const { data: fila, error: errorPerfil } = await supabase
        .from("usuarios")
        .select("foto_public_id")
        .eq("id", uid)
        .maybeSingle();
      if (errorPerfil) {
        console.error("firmar-medio: perfil falló", errorPerfil.message);
        return error(500, "lectura_fallida", "No pudimos preparar tu avatar. Intenta de nuevo.");
      }
      const publicId = fila?.foto_public_id;
      if (!publicId || typeof publicId !== "string") {
        return responder(200, { medios: [] });
      }
      const medios = await firmarMedios(
        [
          {
            id: uid,
            tipo: "foto",
            cloudinary_public_id: publicId,
            cloudinary_tipo_recurso: "image",
            cloudinary_version: null,
            formato: "jpg",
          } satisfies FilaMedio,
        ],
        credenciales,
        Math.floor(Date.now() / 1000),
      );
      return responder(200, { medios });
    }

    if (esSolicitudAvataresUsuarios(cuerpo)) {
      const idsUsuario = validarAvataresUsuarioIds(cuerpo);
      const { data: perfiles, error: errorPerfiles } = await supabase
        .from("perfiles_visibles")
        .select("id, foto_public_id")
        .in("id", idsUsuario);
      if (errorPerfiles) {
        console.error("firmar-medio: perfiles_visibles falló", errorPerfiles.message);
        return error(500, "lectura_fallida", "No pudimos preparar los avatares. Intenta de nuevo.");
      }
      const filas: FilaMedio[] = [];
      for (const fila of perfiles ?? []) {
        const uid = fila?.id;
        const publicId = fila?.foto_public_id;
        if (typeof uid !== "string" || typeof publicId !== "string" || !publicId) continue;
        filas.push({
          id: uid,
          tipo: "foto",
          cloudinary_public_id: publicId,
          cloudinary_tipo_recurso: "image",
          cloudinary_version: null,
          formato: "jpg",
        });
      }
      const medios = await firmarMedios(
        filas,
        credenciales,
        Math.floor(Date.now() / 1000),
      );
      return responder(200, { medios });
    }

    const ids = validarSolicitud(cuerpo);

    // 2. Solo las filas que RLS deja ver a este usuario.
    const { data: filas, error: errorFilas } = await supabase
      .from("elementos")
      .select("id, tipo, cloudinary_public_id, cloudinary_tipo_recurso, cloudinary_version, formato")
      .in("id", ids);
    if (errorFilas) {
      console.error("firmar-medio: lectura de elementos falló", errorFilas.message);
      return error(500, "lectura_fallida", "No pudimos preparar tus recuerdos. Intenta de nuevo.");
    }

    // 3. Firma.
    const medios = await firmarMedios(
      (filas ?? []) as FilaMedio[],
      credenciales,
      Math.floor(Date.now() / 1000),
    );
    return responder(200, { medios });
  } catch (e) {
    if (e instanceof ErrorSolicitud) return error(e.estado, e.codigo, e.message);
    console.error("firmar-medio: error inesperado", e instanceof Error ? e.message : e);
    return error(500, "error_interno", "No pudimos preparar tus recuerdos. Intenta de nuevo.");
  }
});
