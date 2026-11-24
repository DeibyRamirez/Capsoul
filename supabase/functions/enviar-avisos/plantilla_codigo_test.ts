import { assertEquals } from "jsr:@std/assert@1";
import { armarCorreoCodigoHerencia } from "./plantilla_codigo.ts";

Deno.test("el correo del código incluye el código, el título y escapa HTML", () => {
  const correo = armarCorreoCodigoHerencia({
    codigo: "123456",
    tituloHerencia: "Reloj <de> familia",
    propietarioNombre: "Ana & José",
    expiraEn: new Date().toISOString(),
  });

  assertEquals(correo.asunto.includes("Reloj <de> familia"), true);
  assertEquals(correo.html.includes("123456"), true);
  assertEquals(correo.html.includes("Reloj &lt;de&gt; familia"), true);
  assertEquals(correo.html.includes("Ana &amp; José"), true);
  assertEquals(correo.html.includes("Reloj <de> familia"), false);
  assertEquals(correo.texto.includes("123456"), true);
  assertEquals(correo.texto.includes("20 minutos"), true);
});
