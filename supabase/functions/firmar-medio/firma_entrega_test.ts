// Pruebas de firmar-medio: `deno test supabase/functions/firmar-medio`.
// Las firmas se comparan con el SDK oficial de Cloudinary (solo en pruebas).
import { v2 as cloudinary } from "npm:cloudinary@2.11.0";
import {
  type Credenciales,
  ErrorSolicitud,
  type FilaMedio,
  firmarMedios,
  MAXIMO_IDS,
  SEGUNDOS_VALIDEZ,
  urlDescargaPrivada,
  urlMiniaturaFirmada,
  validarSolicitud,
} from "./firma_entrega.ts";

const CREDENCIALES: Credenciales = {
  cloudName: "nube-prueba",
  apiKey: "1234567890",
  apiSecret: "secreto-de-prueba",
};

cloudinary.config({
  cloud_name: CREDENCIALES.cloudName,
  api_key: CREDENCIALES.apiKey,
  api_secret: CREDENCIALES.apiSecret,
  secure: true,
  analytics: false,
});

const ID = "0b9c3a5e-6a5f-4e7a-9f39-6f2a1d6c9a11";
const PUBLIC_ID = "capsoul/5f0e8c1e-2a7b-4c41-8d9e-1b2c3d4e5f60";

function afirmar(condicion: unknown, mensaje: string): void {
  if (!condicion) throw new Error(mensaje);
}

function codigoDe(fn: () => unknown): string | null {
  try {
    fn();
    return null;
  } catch (e) {
    return e instanceof ErrorSolicitud ? e.codigo : "otro";
  }
}

Deno.test("valida la lista de ids", () => {
  afirmar(validarSolicitud({ elemento_ids: [ID, ID.toUpperCase()] }).length === 1, "sin repetidos");
  afirmar(codigoDe(() => validarSolicitud({ elemento_ids: [] })) === "solicitud_invalida", "vacía");
  afirmar(codigoDe(() => validarSolicitud({ elemento_ids: ["x"] })) === "solicitud_invalida", "uuid");
  afirmar(codigoDe(() => validarSolicitud(null)) === "solicitud_invalida", "null");
  const demasiados = Array.from(
    { length: MAXIMO_IDS + 1 },
    (_, i) => `00000000-0000-4000-8000-${String(i).padStart(12, "0")}`,
  );
  afirmar(codigoDe(() => validarSolicitud({ elemento_ids: demasiados })) === "solicitud_invalida", "máximo");
});

Deno.test("la URL de descarga coincide con private_download_url del SDK", async () => {
  const expiresAt = 1_791_000_000;
  const delSdk = cloudinary.utils.private_download_url(PUBLIC_ID, "mp4", {
    resource_type: "video",
    type: "authenticated",
    expires_at: expiresAt,
  });
  const timestamp = Number(new URL(delSdk).searchParams.get("timestamp"));
  const nuestra = await urlDescargaPrivada(CREDENCIALES, PUBLIC_ID, "mp4", "video", expiresAt, timestamp);
  const a = new URL(delSdk);
  const b = new URL(nuestra);
  afirmar(a.origin + a.pathname === b.origin + b.pathname, `ruta: ${a.pathname} vs ${b.pathname}`);
  for (const clave of ["public_id", "format", "type", "expires_at", "timestamp", "api_key", "signature"]) {
    afirmar(
      a.searchParams.get(clave) === b.searchParams.get(clave),
      `${clave}: ${a.searchParams.get(clave)} vs ${b.searchParams.get(clave)}`,
    );
  }
});

Deno.test("la miniatura firmada coincide con cloudinary.url del SDK", async () => {
  const foto = cloudinary.url(`${PUBLIC_ID}.jpg`, {
    resource_type: "image",
    type: "authenticated",
    sign_url: true,
    version: 1759500000,
    transformation: [{ crop: "limit", width: 480, quality: "auto" }],
  });
  const nuestraFoto = await urlMiniaturaFirmada(CREDENCIALES, PUBLIC_ID, "image", 1759500000);
  afirmar(foto === nuestraFoto, `foto:\n${foto}\n${nuestraFoto}`);

  const video = cloudinary.url(`${PUBLIC_ID}.jpg`, {
    resource_type: "video",
    type: "authenticated",
    sign_url: true,
    version: 1759500000,
    transformation: [{ start_offset: 0, crop: "limit", width: 480, quality: "auto" }],
  });
  const nuestroVideo = await urlMiniaturaFirmada(CREDENCIALES, PUBLIC_ID, "video", 1759500000);
  afirmar(video === nuestroVideo, `video:\n${video}\n${nuestroVideo}`);
});

Deno.test("firma solo medios: omite notas y filas incompletas", async () => {
  const filas: FilaMedio[] = [
    {
      id: "foto",
      tipo: "foto",
      cloudinary_public_id: PUBLIC_ID,
      cloudinary_tipo_recurso: "image",
      cloudinary_version: 1,
      formato: "JPG",
    },
    {
      id: "audio",
      tipo: "audio",
      cloudinary_public_id: PUBLIC_ID,
      cloudinary_tipo_recurso: "video",
      cloudinary_version: null,
      formato: null,
    },
    {
      id: "nota",
      tipo: "texto",
      cloudinary_public_id: null,
      cloudinary_tipo_recurso: null,
      cloudinary_version: null,
      formato: null,
    },
  ];
  const ahora = 1_791_000_000;
  const medios = await firmarMedios(filas, CREDENCIALES, ahora);
  afirmar(medios.map((m) => m.id).join(",") === "foto,audio", "ids");
  afirmar(medios[0].url_miniatura?.includes("/image/authenticated/s--") === true, "miniatura foto");
  afirmar(new URL(medios[0].url).searchParams.get("format") === "jpg", "formato en minúsculas");
  afirmar(medios[1].url_miniatura === null, "audio sin miniatura");
  afirmar(new URL(medios[1].url).searchParams.get("format") === "m4a", "formato por defecto");
  afirmar(
    medios[0].expira_en === new Date((ahora + SEGUNDOS_VALIDEZ) * 1000).toISOString(),
    "expira en 1 h",
  );
});
