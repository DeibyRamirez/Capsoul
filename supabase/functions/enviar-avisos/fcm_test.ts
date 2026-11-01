import { assertEquals } from "jsr:@std/assert@1";
import {
  AMBITO_FCM,
  CacheTokenOauth,
  codigoErrorFcm,
  cuerpoMensajeFcm,
  enviarMensajeFcm,
  firmarJwtRs256,
  tokenAccesoFcm,
  tokenInvalido,
  type CredencialesFcm,
  type FetchComo,
} from "./fcm.ts";
import { CANAL_AVISOS_ANDROID } from "./plantillas.ts";

function decodificarBase64Url(segmento: string): string {
  const base = segmento.replaceAll("-", "+").replaceAll("_", "/");
  const padding = "=".repeat((4 - (base.length % 4)) % 4);
  return atob(base + padding);
}

function pemDesde(pkcs8: ArrayBuffer): string {
  const bytes = new Uint8Array(pkcs8);
  let binario = "";
  for (const byte of bytes) binario += String.fromCharCode(byte);
  const cuerpo = btoa(binario).replaceAll(/(.{64})/g, "$1\n");
  return `-----BEGIN PRIVATE KEY-----\n${cuerpo}\n-----END PRIVATE KEY-----`;
}

async function credencialesDePrueba(): Promise<{
  credenciales: CredencialesFcm;
  publica: CryptoKey;
}> {
  const par = await crypto.subtle.generateKey(
    {
      name: "RSASSA-PKCS1-v1_5",
      modulusLength: 2048,
      publicExponent: new Uint8Array([1, 0, 1]),
      hash: "SHA-256",
    },
    true,
    ["sign", "verify"],
  );
  const pkcs8 = await crypto.subtle.exportKey("pkcs8", par.privateKey);
  return {
    credenciales: {
      projectId: "capsoul-prueba",
      clientEmail: "avisos@capsoul-prueba.iam.gserviceaccount.com",
      privateKeyPem: pemDesde(pkcs8).replaceAll("\n", "\\n"),
    },
    publica: par.publicKey,
  };
}

Deno.test("el JWT de la cuenta de servicio pide el ámbito de FCM", async () => {
  const { credenciales, publica } = await credencialesDePrueba();
  const ahora = 1_700_000_000;
  const jwt = await firmarJwtRs256({
    clientEmail: credenciales.clientEmail,
    privateKeyPem: credenciales.privateKeyPem,
    ahoraSegundos: ahora,
  });
  const [encabezado, cuerpo, firma] = jwt.split(".");
  const payload = JSON.parse(decodificarBase64Url(cuerpo));
  assertEquals(payload.iss, credenciales.clientEmail);
  assertEquals(payload.scope, AMBITO_FCM);
  assertEquals(payload.aud, "https://oauth2.googleapis.com/token");
  assertEquals(payload.exp, ahora + 3600);
  const cabezas = JSON.parse(decodificarBase64Url(encabezado));
  assertEquals(cabezas.alg, "RS256");
  const firmaBytes = Uint8Array.from(decodificarBase64Url(firma), (c) => c.charCodeAt(0));
  const ok = await crypto.subtle.verify(
    "RSASSA-PKCS1-v1_5",
    publica,
    firmaBytes,
    new TextEncoder().encode(`${encabezado}.${cuerpo}`),
  );
  assertEquals(ok, true);
});

Deno.test("el token OAuth se reutiliza hasta que vence", async () => {
  const { credenciales } = await credencialesDePrueba();
  let ahora = 1_700_000_000;
  let oauth = 0;
  const fetchImpl: FetchComo = (input, init) => {
    const url = String(input);
    if (url.includes("oauth2.googleapis.com")) {
      oauth++;
      const body = String(init?.body ?? "");
      if (!body.includes("grant_type=urn%3Aietf%3Aparams%3Aoauth%3Agrant-type%3Ajwt-bearer") &&
        !body.includes("grant_type=urn:ietf:params:oauth:grant-type:jwt-bearer")) {
        throw new Error(`grant_type inesperado: ${body}`);
      }
      return Promise.resolve(new Response(
        JSON.stringify({ access_token: "ya29.prueba", expires_in: 3600 }),
        { status: 200 },
      ));
    }
    return Promise.resolve(new Response("{}", { status: 200 }));
  };
  const cache = new CacheTokenOauth(() => ahora);
  const primero = await tokenAccesoFcm({
    credenciales,
    cache,
    ahoraSegundos: () => ahora,
    fetchImpl,
  });
  const segundo = await tokenAccesoFcm({
    credenciales,
    cache,
    ahoraSegundos: () => ahora,
    fetchImpl,
  });
  assertEquals(primero, "ya29.prueba");
  assertEquals(segundo, primero);
  assertEquals(oauth, 1);
  ahora += 3600;
  await tokenAccesoFcm({
    credenciales,
    cache,
    ahoraSegundos: () => ahora,
    fetchImpl,
  });
  assertEquals(oauth, 2);
});

Deno.test("el mensaje v1 nombra la cápsula y el canal de alta importancia", () => {
  const cuerpo = cuerpoMensajeFcm({
    token: "token-android",
    titulo: "Tienes una cápsula nueva",
    cuerpo: "«Viaje al río» ya se puede abrir.",
    data: {
      tipo: "capsula_liberada",
      capsula_id: "cap-1",
      ruta: "capsoul://capsula/cap-1",
    },
  });
  const mensaje = cuerpo.message;
  const android = mensaje.android as { priority: string; notification: { channel_id: string } };
  const data = mensaje.data as Record<string, string>;
  assertEquals(android.priority, "HIGH");
  assertEquals(android.notification.channel_id, CANAL_AVISOS_ANDROID);
  assertEquals(data.ruta, "capsoul://capsula/cap-1");
  assertEquals(data.capsula_id, "cap-1");
  assertEquals((mensaje.notification as { body: string }).body.includes("Viaje al río"), true);
});

Deno.test("la solicitud de amistad viaja en data, con acciones y sin notification", () => {
  const cuerpo = cuerpoMensajeFcm({
    token: "token-android",
    titulo: "Nueva solicitud de amistad",
    cuerpo: "Ana quiere ser tu amigo en Capsoul.",
    data: {
      tipo: "solicitud_amistad",
      amistad_id: "11111111-2222-3333-4444-555555555555",
      ruta: "capsoul://amigos",
      accion_aceptar: "capsoul://amigos?accion=aceptar&amistad_id=11111111-2222-3333-4444-555555555555",
      accion_rechazar: "capsoul://amigos?accion=rechazar&amistad_id=11111111-2222-3333-4444-555555555555",
    },
  });
  const mensaje = cuerpo.message;
  assertEquals(mensaje.notification, undefined);
  const android = mensaje.android as { priority: string; notification?: unknown };
  assertEquals(android.priority, "HIGH");
  assertEquals(android.notification, undefined);
  const data = mensaje.data as Record<string, string>;
  assertEquals(data.titulo, "Nueva solicitud de amistad");
  assertEquals(data.cuerpo, "Ana quiere ser tu amigo en Capsoul.");
  assertEquals(data.accion_aceptar?.includes("accion=aceptar"), true);
  const apns = mensaje.apns as { payload: { aps: { alert: { title: string } } } };
  assertEquals(apns.payload.aps.alert.title, "Nueva solicitud de amistad");
});

Deno.test("UNREGISTERED se lee del detalle de FCM", () => {
  const codigo = codigoErrorFcm({
    error: {
      code: 404,
      status: "NOT_FOUND",
      details: [{
        "@type": "type.googleapis.com/google.firebase.fcm.v1.FcmError",
        errorCode: "UNREGISTERED",
      }],
    },
  });
  assertEquals(codigo, "UNREGISTERED");
  assertEquals(tokenInvalido(codigo), true);
  assertEquals(tokenInvalido("INVALID_ARGUMENT"), true);
  assertEquals(tokenInvalido("UNAVAILABLE"), false);
});

Deno.test("enviarMensajeFcm usa HTTP v1 y el bearer en caché", async () => {
  const { credenciales } = await credencialesDePrueba();
  const ahora = 1_700_000_000;
  const urls: string[] = [];
  const fetchImpl: FetchComo = (input, init) => {
    const url = String(input);
    urls.push(url);
    if (url.includes("oauth2.googleapis.com")) {
      return Promise.resolve(new Response(
        JSON.stringify({ access_token: "ya29.uno", expires_in: 3600 }),
        { status: 200 },
      ));
    }
    const auth = new Headers(init?.headers).get("Authorization");
    if (auth !== "Bearer ya29.uno") throw new Error(`auth ${auth}`);
    return Promise.resolve(new Response(JSON.stringify({ name: "projects/x/messages/1" }), {
      status: 200,
    }));
  };
  const cache = new CacheTokenOauth(() => ahora);
  const resultado = await enviarMensajeFcm({
    credenciales,
    cache,
    ahoraSegundos: () => ahora,
    fetchImpl,
    token: "tok",
    titulo: "t",
    cuerpo: "c",
    data: { ruta: "capsoul://capsula/1" },
  });
  assertEquals(resultado.ok, true);
  assertEquals(urls.some((url) => url.endsWith("/v1/projects/capsoul-prueba/messages:send")), true);
  assertEquals(urls.some((url) => url.includes("/fcm/send")), false);
});
