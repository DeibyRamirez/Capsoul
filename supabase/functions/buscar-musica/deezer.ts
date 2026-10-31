/** Búsqueda en la API pública de Deezer (sin token ni secretos de catálogo). */

export const LIMITE_MAX = 10;
export const DEEZER_TIMEOUT_MS = 8_000;
export const URL_BUSQUEDA_DEEZER = "https://api.deezer.com/search";

/** Cuota de la API pública (el mismo código que traduce la app). */
export const CODIGO_CUOTA_DEEZER = 4;

export interface AlbumDeezer {
  title?: string;
  cover_medium?: string;
  cover_big?: string;
  cover?: string;
}

export interface PistaDeezer {
  id?: number | string;
  link?: string;
  title?: string;
  preview?: string;
  artist?: { name?: string };
  album?: AlbumDeezer;
}

/** Mismo contrato que devolvía buscar-musica; el proveedor pasa a ser Deezer. */
export interface ResultadoPista {
  proveedor: "deezer";
  idExterno: string;
  titulo: string;
  artista: string;
  previewUrl: string | null;
  previewProveedor: "deezer" | null;
  enlaceDeezer: string;
  urlCompleta: string;
  uriProfundo: string;
  portadaUrl: string | null;
}

export type CodigoErrorDeezer = "deezer_cuota" | "deezer_error";

const MENSAJE_CUOTA = "Se alcanzó el límite de búsquedas en Deezer. Intenta en unos minutos.";
const MENSAJE_ERROR = "No se pudo buscar en Deezer. Intenta más tarde.";

export class ErrorBusquedaDeezer extends Error {
  readonly codigo: CodigoErrorDeezer;

  constructor(codigo: CodigoErrorDeezer, mensaje: string) {
    super(mensaje);
    this.name = "ErrorBusquedaDeezer";
    this.codigo = codigo;
  }
}

export function acotarLimite(limite: unknown): number {
  const numero = typeof limite === "number"
    ? limite
    : typeof limite === "string" && limite.trim() !== ""
    ? Number(limite)
    : LIMITE_MAX;
  if (!Number.isFinite(numero)) return LIMITE_MAX;
  return Math.min(LIMITE_MAX, Math.max(1, Math.floor(numero)));
}

function texto(valor: unknown): string | null {
  if (typeof valor !== "string") return null;
  const limpio = valor.trim();
  return limpio.length > 0 ? limpio : null;
}

function idTexto(id: unknown): string | null {
  if (typeof id === "number" && Number.isFinite(id)) {
    const entero = Math.trunc(id);
    if (entero < 0) return null;
    return String(entero);
  }
  if (typeof id === "string" && /^\d+$/.test(id.trim())) return id.trim();
  return null;
}

/** Convierte una pista de `/search` al formato de la función. Null si falta id, título o artista. */
export function mapearPistaDeezer(pista: PistaDeezer): ResultadoPista | null {
  const id = idTexto(pista.id);
  const titulo = texto(pista.title);
  const artista = texto(pista.artist?.name);
  if (!id || !titulo || !artista) return null;
  const enlace = texto(pista.link) ?? `https://www.deezer.com/track/${id}`;
  const preview = texto(pista.preview);
  const album = pista.album;
  const portada = texto(album?.cover_medium) ?? texto(album?.cover_big) ?? texto(album?.cover);
  return {
    proveedor: "deezer",
    idExterno: id,
    titulo,
    artista,
    previewUrl: preview,
    previewProveedor: preview ? "deezer" : null,
    enlaceDeezer: enlace,
    urlCompleta: enlace,
    uriProfundo: `deezer://www.deezer.com/track/${id}`,
    portadaUrl: portada,
  };
}

export function mapearResultadosDeezer(pistas: unknown): ResultadoPista[] {
  if (!Array.isArray(pistas)) return [];
  const resultados: ResultadoPista[] = [];
  for (const fila of pistas) {
    if (!fila || typeof fila !== "object") continue;
    const mapeada = mapearPistaDeezer(fila as PistaDeezer);
    if (mapeada) resultados.push(mapeada);
  }
  return resultados;
}

export function urlBusquedaDeezer(consulta: string, limite: number): string {
  const params = new URLSearchParams({
    q: consulta,
    limit: String(limite),
  });
  return `${URL_BUSQUEDA_DEEZER}?${params}`;
}

function codigoErrorCuerpo(datos: unknown): number | null {
  if (!datos || typeof datos !== "object") return null;
  const error = (datos as { error?: unknown }).error;
  if (!error || typeof error !== "object") return null;
  const codigo = (error as { code?: unknown }).code;
  return typeof codigo === "number" ? codigo : null;
}

function datosDeBusqueda(datos: unknown): unknown[] | null {
  if (!datos || typeof datos !== "object") return null;
  const lista = (datos as { data?: unknown }).data;
  return Array.isArray(lista) ? lista : null;
}

export async function buscarEnDeezer(
  consulta: string,
  limite: number,
  opciones?: {
    fetch?: typeof fetch;
    tiempoMs?: number;
  },
): Promise<ResultadoPista[]> {
  const fetcher = opciones?.fetch ?? fetch;
  const tiempoMs = opciones?.tiempoMs ?? DEEZER_TIMEOUT_MS;
  const tope = acotarLimite(limite);
  const control = new AbortController();
  const temporizador = setTimeout(() => control.abort(), tiempoMs);
  try {
    const respuesta = await fetcher(urlBusquedaDeezer(consulta, tope), {
      signal: control.signal,
      headers: { Accept: "application/json" },
    });
    if (respuesta.status === 429) {
      throw new ErrorBusquedaDeezer("deezer_cuota", MENSAJE_CUOTA);
    }
    const textoCuerpo = await respuesta.text();
    let datos: unknown;
    try {
      datos = textoCuerpo ? JSON.parse(textoCuerpo) : null;
    } catch {
      throw new ErrorBusquedaDeezer("deezer_error", MENSAJE_ERROR);
    }
    const codigo = codigoErrorCuerpo(datos);
    if (codigo === CODIGO_CUOTA_DEEZER) {
      throw new ErrorBusquedaDeezer("deezer_cuota", MENSAJE_CUOTA);
    }
    if (codigo != null || !respuesta.ok) {
      console.error("Deezer search:", respuesta.status, codigo);
      throw new ErrorBusquedaDeezer("deezer_error", MENSAJE_ERROR);
    }
    const pistas = datosDeBusqueda(datos);
    if (!pistas) {
      throw new ErrorBusquedaDeezer("deezer_error", MENSAJE_ERROR);
    }
    return mapearResultadosDeezer(pistas);
  } catch (e) {
    if (e instanceof ErrorBusquedaDeezer) throw e;
    if (e instanceof Error && e.name === "AbortError") {
      throw new ErrorBusquedaDeezer("deezer_error", MENSAJE_ERROR);
    }
    console.error("Deezer search:", e instanceof Error ? e.message : e);
    throw new ErrorBusquedaDeezer("deezer_error", MENSAJE_ERROR);
  } finally {
    clearTimeout(temporizador);
  }
}
