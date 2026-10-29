/** FCM HTTP v1: JWT de cuenta de servicio, token OAuth en caché y envío. */

import { CANAL_AVISOS_ANDROID } from "./plantillas.ts";

export const AMBITO_FCM = "https://www.googleapis.com/auth/firebase.messaging";
export const URL_TOKEN_OAUTH = "https://oauth2.googleapis.com/token";

export type CredencialesFcm = {
  projectId: string;
  clientEmail: string;
  privateKeyPem: string;
};

export type ResultadoEnvioFcm = {
  ok: boolean;
  status: number;
  codigo: string | null;
  detalle: string;
};

export type FetchComo = (
  input: string,
  init?: RequestInit,
) => Promise<Response>;

/** UNREGISTERED e INVALID_ARGUMENT: el token no se vuelve a intentar. */
export function tokenInvalido(codigo: string | null): boolean {
  return codigo === "UNREGISTERED" || codigo === "INVALID_ARGUMENT";
}

export function codigoErrorFcm(cuerpo: unknown): string | null {
  if (!cuerpo || typeof cuerpo !== "object") return null;
  const error = (cuerpo as { error?: unknown }).error;
  if (!error || typeof error !== "object") return null;
  const details = (error as { details?: unknown }).details;
  if (Array.isArray(details)) {
    for (const detalle of details) {
      if (!detalle || typeof detalle !== "object") continue;
      const codigo = (detalle as { errorCode?: unknown }).errorCode;
      if (typeof codigo === "string" && codigo.length > 0) return codigo;
    }
  }
  const estado = (error as { status?: unknown }).status;
  if (typeof estado === "string" && estado.length > 0) return estado;
  return null;
}

export function cuerpoMensajeFcm(args: {
  token: string;
  titulo: string;
  cuerpo: string;
  data: Record<string, string>;
}): { message: Record<string, unknown> } {
  const data: Record<string, string> = {};
  for (const [clave, valor] of Object.entries(args.data)) {
    data[clave] = String(valor);
  }
  return {
    message: {
      token: args.token,
      notification: { title: args.titulo, body: args.cuerpo },
      data,
      android: {
        priority: "HIGH",
        notification: { channel_id: CANAL_AVISOS_ANDROID },
      },
      // iOS queda preparado: FCM lo ignora hasta que haya APNs en el proyecto.
      apns: {
        headers: { "apns-priority": "10" },
        payload: { aps: { sound: "default" } },
      },
    },
  };
}

/** El secreto suele guardar el PEM con saltos de línea escapados. */
export function normalizarPem(pem: string): string {
  return pem.replaceAll("\\n", "\n").trim();
}

function pemAPkcs8(pem: string): ArrayBuffer {
  const limpio = normalizarPem(pem)
    .replace("-----BEGIN PRIVATE KEY-----", "")
    .replace("-----END PRIVATE KEY-----", "")
    .replace(/\s+/g, "");
  const binario = atob(limpio);
  const bytes = new Uint8Array(binario.length);
  for (let i = 0; i < binario.length; i++) bytes[i] = binario.charCodeAt(i);
  return bytes.buffer;
}

function base64Url(bytes: Uint8Array): string {
  let binario = "";
  for (const byte of bytes) binario += String.fromCharCode(byte);
  return btoa(binario).replaceAll("+", "-").replaceAll("/", "_").replaceAll("=", "");
}

export async function firmarJwtRs256(args: {
  clientEmail: string;
  privateKeyPem: string;
  ahoraSegundos: number;
  vigenciaSegundos?: number;
}): Promise<string> {
  const vigencia = args.vigenciaSegundos ?? 3600;
  const encabezado = base64Url(
    new TextEncoder().encode(JSON.stringify({ alg: "RS256", typ: "JWT" })),
  );
  const cuerpo = base64Url(
    new TextEncoder().encode(JSON.stringify({
      iss: args.clientEmail,
      scope: AMBITO_FCM,
      aud: URL_TOKEN_OAUTH,
      iat: args.ahoraSegundos,
      exp: args.ahoraSegundos + vigencia,
    })),
  );
  const firmaSobre = new TextEncoder().encode(`${encabezado}.${cuerpo}`);
  const clave = await crypto.subtle.importKey(
    "pkcs8",
    pemAPkcs8(args.privateKeyPem),
    { name: "RSASSA-PKCS1-v1_5", hash: "SHA-256" },
    false,
    ["sign"],
  );
  const firma = new Uint8Array(
    await crypto.subtle.sign("RSASSA-PKCS1-v1_5", clave, firmaSobre),
  );
  return `${encabezado}.${cuerpo}.${base64Url(firma)}`;
}

/** Guarda el access token hasta un minuto antes de que venza. */
export class CacheTokenOauth {
  #token: string | null = null;
  #venceEn = 0;

  constructor(
    private readonly ahoraSegundos: () => number,
    private readonly margenSegundos = 60,
  ) {}

  leer(): string | null {
    if (!this.#token) return null;
    if (this.ahoraSegundos() >= this.#venceEn - this.margenSegundos) return null;
    return this.#token;
  }

  guardar(token: string, expiraEnSegundos: number): void {
    this.#token = token;
    this.#venceEn = this.ahoraSegundos() + expiraEnSegundos;
  }
}

export async function tokenAccesoFcm(args: {
  credenciales: CredencialesFcm;
  cache: CacheTokenOauth;
  ahoraSegundos: () => number;
  fetchImpl: FetchComo;
}): Promise<string> {
  const vigente = args.cache.leer();
  if (vigente) return vigente;

  const jwt = await firmarJwtRs256({
    clientEmail: args.credenciales.clientEmail,
    privateKeyPem: args.credenciales.privateKeyPem,
    ahoraSegundos: args.ahoraSegundos(),
  });
  const cuerpo = new URLSearchParams({
    grant_type: "urn:ietf:params:oauth:grant-type:jwt-bearer",
    assertion: jwt,
  });
  const respuesta = await args.fetchImpl(URL_TOKEN_OAUTH, {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body: cuerpo.toString(),
  });
  if (!respuesta.ok) {
    const texto = await respuesta.text();
    throw new Error(`OAuth FCM ${respuesta.status}: ${texto.slice(0, 300)}`);
  }
  const json = await respuesta.json() as { access_token?: unknown; expires_in?: unknown };
  if (typeof json.access_token !== "string" || json.access_token.length === 0) {
    throw new Error("OAuth FCM no devolvió access_token");
  }
  const expira = typeof json.expires_in === "number" ? json.expires_in : 3600;
  args.cache.guardar(json.access_token, expira);
  return json.access_token;
}

export async function enviarMensajeFcm(args: {
  credenciales: CredencialesFcm;
  cache: CacheTokenOauth;
  ahoraSegundos: () => number;
  fetchImpl: FetchComo;
  token: string;
  titulo: string;
  cuerpo: string;
  data: Record<string, string>;
}): Promise<ResultadoEnvioFcm> {
  const acceso = await tokenAccesoFcm(args);
  const url =
    `https://fcm.googleapis.com/v1/projects/${args.credenciales.projectId}/messages:send`;
  const respuesta = await args.fetchImpl(url, {
    method: "POST",
    headers: {
      Authorization: `Bearer ${acceso}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify(cuerpoMensajeFcm(args)),
  });
  const texto = await respuesta.text();
  let json: unknown = null;
  try {
    json = JSON.parse(texto);
  } catch {
    json = null;
  }
  return {
    ok: respuesta.ok,
    status: respuesta.status,
    codigo: codigoErrorFcm(json),
    detalle: texto.slice(0, 500),
  };
}
