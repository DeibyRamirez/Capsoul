import { assertEquals } from "jsr:@std/assert@1";
import { armarContenido } from "./plantillas.ts";

const AMISTAD = "11111111-2222-3333-4444-555555555555";

Deno.test("solicitud_amistad usa el cuerpo guardado y añade amistad_id", () => {
  const contenido = armarContenido({
    tipo: "solicitud_amistad",
    referenciaId: AMISTAD,
    tituloGuardado: "Nueva solicitud de amistad",
    cuerpoGuardado: "Ana quiere ser tu amigo en Capsoul.",
    tituloReferencia: null,
  });
  assertEquals(contenido.titulo, "Nueva solicitud de amistad");
  assertEquals(contenido.cuerpo, "Ana quiere ser tu amigo en Capsoul.");
  assertEquals(contenido.data, {
    tipo: "solicitud_amistad",
    referencia_id: AMISTAD,
    amistad_id: AMISTAD,
    ruta: "capsoul://amigos",
    titulo: "Nueva solicitud de amistad",
    cuerpo: "Ana quiere ser tu amigo en Capsoul.",
    accion_aceptar: `capsoul://amigos?accion=aceptar&amistad_id=${AMISTAD}`,
    accion_rechazar: `capsoul://amigos?accion=rechazar&amistad_id=${AMISTAD}`,
  });
});

Deno.test("solicitud_amistad sin textos guardados usa el texto genérico", () => {
  const contenido = armarContenido({
    tipo: "solicitud_amistad",
    referenciaId: AMISTAD,
    tituloGuardado: "  ",
    cuerpoGuardado: "",
    tituloReferencia: null,
  });
  assertEquals(contenido.titulo, "Nueva solicitud de amistad");
  assertEquals(contenido.cuerpo, "Alguien quiere ser tu amigo en Capsoul.");
  assertEquals(contenido.data.ruta, "capsoul://amigos");
});
