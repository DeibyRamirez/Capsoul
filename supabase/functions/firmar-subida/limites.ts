// Capsoul · Límites de medios y firma de Cloudinary para la Edge Function firmar-subida.
// Lógica pura (sin red ni secretos) para poder probarla con `deno test`.
// Los valores son los mismos de LimitesMedios (app) y de la migración 000003.

const MB = 1024 * 1024;

export type TipoMedio = "foto" | "video" | "audio";

export interface LimiteTipo {
  /** Tipo de recurso de Cloudinary (el audio se sube como `video`). */
  tipoRecurso: "image" | "video";
  bytesMaximos: number;
  /** Duración máxima en segundos ya con la holgura de 1 s; null si no aplica. */
  duracionMaxima: number | null;
  /** Formatos aceptados (se firman como `allowed_formats`). */
  formatos: string[];
  /** Miniatura generada al subir; null si no hay. */
  eager: string | null;
}

export const LIMITES: Record<TipoMedio, LimiteTipo> = {
  foto: {
    tipoRecurso: "image",
    bytesMaximos: 2 * MB,
    duracionMaxima: null,
    formatos: ["jpg"],
    eager: "c_limit,w_480,q_auto/jpg",
  },
  video: {
    tipoRecurso: "video",
    bytesMaximos: 20 * MB,
    duracionMaxima: 61,
    formatos: ["mp4", "mov"],
    eager: "so_0,c_limit,w_480,q_auto/jpg",
  },
  audio: {
    tipoRecurso: "video",
    bytesMaximos: 3 * MB,
    duracionMaxima: 301,
    formatos: ["m4a", "mp4", "aac"],
    eager: null,
  },
};

export const CUOTA_BYTES_POR_USUARIO = 200 * MB;

export interface SolicitudFirma {
  tipo: TipoMedio;
  bytes: number;
  duracionSegundos: number | null;
  formato: string | null;
}

export class ErrorSolicitud extends Error {
  constructor(
    readonly estado: number,
    readonly codigo: string,
    mensaje: string,
  ) {
    super(mensaje);
  }
}

function formatearMb(bytes: number): string {
  return `${(bytes / MB).toFixed(1).replace(".", ",")} MB`;
}

/** Valida el cuerpo JSON declarado por la app. Lanza [ErrorSolicitud] (422). */
export function validarSolicitud(cuerpo: unknown): SolicitudFirma {
  if (typeof cuerpo !== "object" || cuerpo === null) {
    throw new ErrorSolicitud(422, "solicitud_invalida", "La solicitud no es válida.");
  }
  const datos = cuerpo as Record<string, unknown>;
  const tipo = datos.tipo;
  if (tipo !== "foto" && tipo !== "video" && tipo !== "audio") {
    throw new ErrorSolicitud(422, "tipo_invalido", "Ese tipo de archivo no se puede subir.");
  }
  const limite = LIMITES[tipo];

  const bytes = datos.bytes;
  if (typeof bytes !== "number" || !Number.isInteger(bytes) || bytes <= 0) {
    throw new ErrorSolicitud(422, "solicitud_invalida", "No pudimos leer el tamaño del archivo.");
  }
  if (bytes > limite.bytesMaximos) {
    throw new ErrorSolicitud(
      422,
      "excede_tamano",
      `El archivo pesa ${formatearMb(bytes)} y el máximo es ${formatearMb(limite.bytesMaximos)}.`,
    );
  }

  let duracionSegundos: number | null = null;
  if (limite.duracionMaxima !== null) {
    const duracion = datos.duracion_segundos;
    if (typeof duracion !== "number" || !Number.isFinite(duracion) || duracion <= 0) {
      throw new ErrorSolicitud(422, "solicitud_invalida", "No pudimos leer la duración del archivo.");
    }
    if (duracion > limite.duracionMaxima) {
      throw new ErrorSolicitud(422, "excede_duracion", "La grabación es más larga de lo permitido.");
    }
    duracionSegundos = duracion;
  }

  let formato: string | null = null;
  if (datos.formato !== undefined && datos.formato !== null) {
    if (typeof datos.formato !== "string" || !limite.formatos.includes(datos.formato.toLowerCase())) {
      throw new ErrorSolicitud(422, "formato_invalido", "Ese formato de archivo no se puede subir.");
    }
    formato = datos.formato.toLowerCase();
  }

  return { tipo, bytes, duracionSegundos, formato };
}

/** Lanza [ErrorSolicitud] si el archivo no cabe en la cuota del usuario. */
export function validarCuota(usados: number, nuevos: number, limite = CUOTA_BYTES_POR_USUARIO): void {
  if (usados + nuevos > limite) {
    throw new ErrorSolicitud(
      422,
      "cuota_excedida",
      `Ya usas ${formatearMb(usados)} de ${formatearMb(limite)}; este archivo no cabe.`,
    );
  }
}

/** `public_id` aleatorio, sin datos del usuario (decisión D2). */
export function generarPublicId(): string {
  return `capsoul/${crypto.randomUUID()}`;
}

/** Parámetros que se firman (todos menos file, api_key, resource_type y cloud_name). */
export function parametrosAFirmar(
  tipo: TipoMedio,
  publicId: string,
  timestamp: number,
): Record<string, string> {
  const limite = LIMITES[tipo];
  const parametros: Record<string, string> = {
    allowed_formats: limite.formatos.join(","),
    public_id: publicId,
    timestamp: String(timestamp),
    type: "authenticated",
  };
  if (limite.eager !== null) {
    parametros.eager = limite.eager;
    // Cloudinary no genera eager síncrono para videos grandes.
    if (limite.tipoRecurso === "video") parametros.eager_async = "true";
  }
  return parametros;
}

/**
 * Firma de Cloudinary: parámetros ordenados alfabéticamente como `k=v`
 * unidos con `&`, seguidos del API secret, en SHA-1 hexadecimal.
 */
export async function firmarParametros(
  parametros: Record<string, string>,
  apiSecret: string,
): Promise<string> {
  const cadena = Object.keys(parametros)
    .sort()
    .map((clave) => `${clave}=${parametros[clave]}`)
    .join("&");
  const resumen = await crypto.subtle.digest(
    "SHA-1",
    new TextEncoder().encode(cadena + apiSecret),
  );
  return Array.from(new Uint8Array(resumen))
    .map((b) => b.toString(16).padStart(2, "0"))
    .join("");
}

export function urlSubida(cloudName: string, tipo: TipoMedio): string {
  return `https://api.cloudinary.com/v1_1/${cloudName}/${LIMITES[tipo].tipoRecurso}/upload`;
}
