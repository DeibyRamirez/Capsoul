/** Fallback Deezer: preview MP3 de 30 s cuando Spotify no devuelve preview_url. */

export const DEEZER_TIMEOUT_MS = 3000;
export const MAX_FALLBACKS_DEEZER = 5;

export interface PistaDeezer {
  id?: number;
  link?: string;
  title?: string;
  preview?: string;
  artist?: { name?: string };
}

export interface ResultadoPreviewDeezer {
  previewUrl: string;
  deezerTrackUrl: string;
}

export function normalizarTextoMusica(texto: string): string {
  return texto
    .toLowerCase()
    .normalize("NFD")
    .replace(/\p{M}/gu, "")
    .replace(/\([^)]*\)|\[[^\]]*\]/g, "")
    .replace(/[^a-z0-9\s]/g, " ")
    .replace(/\s+/g, " ")
    .trim();
}

function enlacePistaDeezer(pista: PistaDeezer): string | null {
  const link = pista.link?.trim();
  if (link) return link;
  if (pista.id != null) return `https://www.deezer.com/track/${pista.id}`;
  return null;
}

/** Elige la pista Deezer con preview que mejor coincide con título/artista. */
export function elegirPreviewDeezer(
  pistas: PistaDeezer[],
  titulo: string,
  artista: string,
): ResultadoPreviewDeezer | null {
  const tituloNorm = normalizarTextoMusica(titulo);
  const artistaNorm = normalizarTextoMusica(artista.split(",")[0] ?? artista);
  let mejor: { preview: string; deezerTrackUrl: string; puntaje: number } | null =
    null;

  for (const pista of pistas) {
    const preview = pista.preview?.trim();
    if (!preview) continue;
    const deezerTrackUrl = enlacePistaDeezer(pista);
    if (!deezerTrackUrl) continue;
    const tituloPista = normalizarTextoMusica(pista.title ?? "");
    const artistaPista = normalizarTextoMusica(pista.artist?.name ?? "");
    let puntaje = 0;
    if (tituloNorm && tituloPista.includes(tituloNorm)) puntaje += 3;
    else if (tituloNorm && tituloNorm.includes(tituloPista)) puntaje += 2;
    if (tituloNorm === tituloPista) puntaje += 4;
    if (artistaNorm && artistaPista.includes(artistaNorm)) puntaje += 2;
    if (artistaNorm === artistaPista) puntaje += 2;
    if (puntaje < 2) continue;
    if (!mejor || puntaje > mejor.puntaje) {
      mejor = { preview, deezerTrackUrl, puntaje };
    }
  }

  if (mejor) {
    return { previewUrl: mejor.preview, deezerTrackUrl: mejor.deezerTrackUrl };
  }
  const primeraConPreview = pistas.find((p) => p.preview?.trim());
  if (!primeraConPreview?.preview?.trim()) return null;
  const deezerTrackUrl = enlacePistaDeezer(primeraConPreview);
  if (!deezerTrackUrl) return null;
  return {
    previewUrl: primeraConPreview.preview!.trim(),
    deezerTrackUrl,
  };
}

export async function buscarPreviewDeezer(
  artista: string,
  titulo: string,
): Promise<ResultadoPreviewDeezer | null> {
  const q = `${artista} ${titulo}`.trim();
  if (!q) return null;
  const url =
    `https://api.deezer.com/search?q=${encodeURIComponent(q)}&limit=5`;
  const control = new AbortController();
  const temporizador = setTimeout(() => control.abort(), DEEZER_TIMEOUT_MS);
  try {
    const respuesta = await fetch(url, { signal: control.signal });
    if (!respuesta.ok) {
      console.error("Deezer preview:", respuesta.status, await respuesta.text());
      return null;
    }
    const datos = await respuesta.json();
    const pistas = (datos.data ?? []) as PistaDeezer[];
    return elegirPreviewDeezer(pistas, titulo, artista);
  } catch (e) {
    if (e instanceof Error && e.name !== "AbortError") {
      console.error("Deezer preview:", e.message);
    }
    return null;
  } finally {
    clearTimeout(temporizador);
  }
}
