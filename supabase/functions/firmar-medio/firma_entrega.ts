// Capsoul · lógica pura de firmar-medio (sin red): validación de la solicitud y firma de
// las URLs de entrega de Cloudinary para recursos type=authenticated.

export const MAXIMO_IDS = 60;

/** Segundos de validez de la URL del original (Download API). */
export const SEGUNDOS_VALIDEZ = 60 * 60;

/**
 * Transformación de la miniatura: la del eager de firmar-subida, con los parámetros en el
 * orden canónico del SDK de Cloudinary (alfabético; `so_` va primero en video).
 */
export const TRANSFORMACION_MINIATURA: Record<"image" | "video", string> = {
  image: "c_limit,q_auto,w_480",
  video: "c_limit,q_auto,so_0,w_480",
};

const UUID = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

export class ErrorSolicitud extends Error {
  constructor(
    readonly estado: number,
    readonly codigo: string,
    mensaje: string,
  ) {
    super(mensaje);
  }
}

/** Valida `{ elemento_ids: [uuid, ...] }` (1..60, sin repetidos). */
export function validarSolicitud(cuerpo: unknown): string[] {
  if (typeof cuerpo !== "object" || cuerpo === null) {
    throw new ErrorSolicitud(422, "solicitud_invalida", "La solicitud no es válida.");
  }
  const ids = (cuerpo as Record<string, unknown>).elemento_ids;
  if (!Array.isArray(ids) || ids.length === 0 || ids.length > MAXIMO_IDS) {
    throw new ErrorSolicitud(
      422,
      "solicitud_invalida",
      `Envía entre 1 y ${MAXIMO_IDS} recuerdos.`,
    );
  }
  const unicos = new Set<string>();
  for (const id of ids) {
    if (typeof id !== "string" || !UUID.test(id)) {
      throw new ErrorSolicitud(422, "solicitud_invalida", "Algún identificador no es válido.");
    }
    unicos.add(id.toLowerCase());
  }
  return [...unicos];
}

/** Fila de `elementos` que lee la función (con el JWT del usuario; RLS decide). */
export interface FilaMedio {
  id: string;
  tipo: string;
  cloudinary_public_id: string | null;
  cloudinary_tipo_recurso: string | null;
  cloudinary_version: number | null;
  formato: string | null;
}

export interface Credenciales {
  cloudName: string;
  apiKey: string;
  apiSecret: string;
}

export interface MedioFirmado {
  id: string;
  url: string;
  url_miniatura: string | null;
  expira_en: string;
}

const FORMATO_POR_TIPO: Record<string, string> = { foto: "jpg", video: "mp4", audio: "m4a" };

async function sha1(texto: string): Promise<Uint8Array> {
  const resumen = await crypto.subtle.digest("SHA-1", new TextEncoder().encode(texto));
  return new Uint8Array(resumen);
}

function hex(bytes: Uint8Array): string {
  return Array.from(bytes).map((b) => b.toString(16).padStart(2, "0")).join("");
}

function base64Url(bytes: Uint8Array): string {
  let binario = "";
  for (const b of bytes) binario += String.fromCharCode(b);
  return btoa(binario).replace(/\+/g, "-").replace(/\//g, "_");
}

/** Firma de la API (parámetros `k=v` ordenados + secret, SHA-1 hex). */
export async function firmarParametros(
  parametros: Record<string, string>,
  apiSecret: string,
): Promise<string> {
  const cadena = Object.keys(parametros)
    .sort()
    .map((clave) => `${clave}=${parametros[clave]}`)
    .join("&");
  return hex(await sha1(cadena + apiSecret));
}

/**
 * URL temporal del original con la Download API (`private_download_url`): caduca en
 * `expiresAt` (segundos Unix) y solo sirve para ese recurso.
 */
export async function urlDescargaPrivada(
  credenciales: Credenciales,
  publicId: string,
  formato: string,
  tipoRecurso: string,
  expiresAt: number,
  timestamp: number,
): Promise<string> {
  const parametros: Record<string, string> = {
    expires_at: String(expiresAt),
    format: formato,
    public_id: publicId,
    timestamp: String(timestamp),
    type: "authenticated",
  };
  const signature = await firmarParametros(parametros, credenciales.apiSecret);
  const consulta = new URLSearchParams({ ...parametros, signature, api_key: credenciales.apiKey });
  return `https://api.cloudinary.com/v1_1/${credenciales.cloudName}/${tipoRecurso}/download?${consulta}`;
}

/**
 * URL de entrega firmada (`s--firma--`) de la miniatura de 480 px. La firma cubre la
 * transformación y el recurso, así que no se puede pedir otra variante con ella.
 */
export async function urlMiniaturaFirmada(
  credenciales: Credenciales,
  publicId: string,
  tipoRecurso: "image" | "video",
  version: number | null,
): Promise<string> {
  const transformacion = TRANSFORMACION_MINIATURA[tipoRecurso];
  const recurso = `${publicId}.jpg`;
  const firma = base64Url(await sha1(`${transformacion}/${recurso}${credenciales.apiSecret}`))
    .slice(0, 8);
  const partes = [
    `https://res.cloudinary.com/${credenciales.cloudName}/${tipoRecurso}/authenticated`,
    `s--${firma}--`,
    transformacion,
    ...(version ? [`v${version}`] : []),
    recurso,
  ];
  return partes.join("/");
}

/** Firma las URLs de cada fila con medio (las notas y filas incompletas se omiten). */
export async function firmarMedios(
  filas: FilaMedio[],
  credenciales: Credenciales,
  ahoraSegundos: number,
): Promise<MedioFirmado[]> {
  const expiresAt = ahoraSegundos + SEGUNDOS_VALIDEZ;
  const expiraEn = new Date(expiresAt * 1000).toISOString();
  const medios: MedioFirmado[] = [];
  for (const fila of filas) {
    const publicId = fila.cloudinary_public_id;
    const tipoRecurso = fila.cloudinary_tipo_recurso;
    if (!publicId || (tipoRecurso !== "image" && tipoRecurso !== "video")) continue;
    const formato = (fila.formato ?? FORMATO_POR_TIPO[fila.tipo] ?? "").toLowerCase();
    if (!formato) continue;
    const conMiniatura = fila.tipo === "foto" || fila.tipo === "video";
    medios.push({
      id: fila.id,
      url: await urlDescargaPrivada(
        credenciales,
        publicId,
        formato,
        tipoRecurso,
        expiresAt,
        ahoraSegundos,
      ),
      url_miniatura: conMiniatura
        ? await urlMiniaturaFirmada(credenciales, publicId, tipoRecurso, fila.cloudinary_version)
        : null,
      expira_en: expiraEn,
    });
  }
  return medios;
}
