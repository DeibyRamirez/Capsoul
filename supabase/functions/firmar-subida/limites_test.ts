// Pruebas de la lógica de firmar-subida: `deno test supabase/functions/firmar-subida`.
import {
  CUOTA_BYTES_POR_USUARIO,
  ErrorSolicitud,
  firmarParametros,
  generarPublicId,
  parametrosAFirmar,
  urlSubida,
  validarCuota,
  validarSolicitud,
} from "./limites.ts";

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

Deno.test("acepta medios dentro de los límites", () => {
  const foto = validarSolicitud({ tipo: "foto", bytes: 2 * 1024 * 1024, formato: "JPG" });
  afirmar(foto.formato === "jpg" && foto.duracionSegundos === null, "foto");
  const video = validarSolicitud({ tipo: "video", bytes: 1000, duracion_segundos: 60.4, formato: "mp4" });
  afirmar(video.duracionSegundos === 60.4, "video");
  const audio = validarSolicitud({ tipo: "audio", bytes: 2_500_000, duracion_segundos: 300, formato: "m4a" });
  afirmar(audio.tipo === "audio", "audio");
});

Deno.test("rechaza tipo, tamaño, duración y formato fuera de los límites", () => {
  afirmar(codigoDe(() => validarSolicitud(null)) === "solicitud_invalida", "nulo");
  afirmar(codigoDe(() => validarSolicitud({ tipo: "texto", bytes: 1 })) === "tipo_invalido", "texto");
  afirmar(codigoDe(() => validarSolicitud({ tipo: "foto", bytes: 0 })) === "solicitud_invalida", "0 bytes");
  afirmar(codigoDe(() => validarSolicitud({ tipo: "foto", bytes: 1.5 })) === "solicitud_invalida", "decimal");
  afirmar(
    codigoDe(() => validarSolicitud({ tipo: "foto", bytes: 2 * 1024 * 1024 + 1 })) === "excede_tamano",
    "foto grande",
  );
  afirmar(
    codigoDe(() =>
      validarSolicitud({ tipo: "video", bytes: 20 * 1024 * 1024 + 1, duracion_segundos: 10 })
    ) === "excede_tamano",
    "video grande",
  );
  afirmar(
    codigoDe(() => validarSolicitud({ tipo: "audio", bytes: 3 * 1024 * 1024 + 1, duracion_segundos: 10 })) ===
      "excede_tamano",
    "audio grande",
  );
  afirmar(
    codigoDe(() => validarSolicitud({ tipo: "video", bytes: 10 })) === "solicitud_invalida",
    "sin duración",
  );
  afirmar(
    codigoDe(() => validarSolicitud({ tipo: "video", bytes: 10, duracion_segundos: 61.5 })) ===
      "excede_duracion",
    "video largo",
  );
  afirmar(
    codigoDe(() => validarSolicitud({ tipo: "audio", bytes: 10, duracion_segundos: 302 })) ===
      "excede_duracion",
    "audio largo",
  );
  afirmar(
    codigoDe(() => validarSolicitud({ tipo: "foto", bytes: 10, formato: "png" })) === "formato_invalido",
    "png",
  );
});

Deno.test("valida la cuota de 200 MB", () => {
  afirmar(codigoDe(() => validarCuota(CUOTA_BYTES_POR_USUARIO - 10, 10)) === null, "justo");
  afirmar(codigoDe(() => validarCuota(CUOTA_BYTES_POR_USUARIO - 10, 11)) === "cuota_excedida", "excede");
});

Deno.test("parámetros firmados: authenticated, public_id aleatorio y eager", () => {
  const id = generarPublicId();
  afirmar(/^capsoul\/[0-9a-f-]{36}$/.test(id) && id !== generarPublicId(), "public_id");
  const foto = parametrosAFirmar("foto", id, 1);
  afirmar(
    foto.type === "authenticated" && foto.eager === "c_limit,w_480,q_auto/jpg" && !("eager_async" in foto),
    "foto",
  );
  const video = parametrosAFirmar("video", id, 1);
  afirmar(video.eager_async === "true" && video.eager.startsWith("so_0"), "video");
  const audio = parametrosAFirmar("audio", id, 1);
  afirmar(!("eager" in audio) && audio.allowed_formats === "m4a,mp4,aac", "audio");
  afirmar(urlSubida("demo", "audio") === "https://api.cloudinary.com/v1_1/demo/video/upload", "url");
});

Deno.test("firma SHA-1 según el ejemplo de la documentación de Cloudinary", async () => {
  // https://cloudinary.com/documentation/authentication_signatures (ejemplo oficial)
  const firma = await firmarParametros(
    { eager: "w_400,h_300,c_pad|w_260,h_200,c_crop", public_id: "sample_image", timestamp: "1315060510" },
    "abcd",
  );
  afirmar(firma === "bfd09f95f331f558cbd1320e67aa8d488770583e", `firma ${firma}`);
});
