import { assertEquals } from "jsr:@std/assert@1";
import { destinoValido, puedeReintentar, resultadoSinDestino } from "./despacho.ts";

Deno.test("push requiere usuario_id", () => {
  assertEquals(
    destinoValido({
      id: "1",
      canal: "push",
      usuario_id: null,
      correo_destino: null,
      titulo: "t",
      cuerpo: "c",
      intentos: 0,
    }),
    false,
  );
  assertEquals(
    destinoValido({
      id: "1",
      canal: "push",
      usuario_id: "u",
      correo_destino: null,
      titulo: "t",
      cuerpo: "c",
      intentos: 0,
    }),
    true,
  );
});

Deno.test("correo requiere dirección", () => {
  assertEquals(
    destinoValido({
      id: "1",
      canal: "correo",
      usuario_id: null,
      correo_destino: "a@b.co",
      titulo: "t",
      cuerpo: "c",
      intentos: 0,
    }),
    true,
  );
});

Deno.test("límite de reintentos", () => {
  assertEquals(puedeReintentar(4), true);
  assertEquals(puedeReintentar(5), false);
});

Deno.test("sin destino marca fallida", () => {
  assertEquals(
    resultadoSinDestino({
      id: "1",
      canal: "push",
      usuario_id: null,
      correo_destino: null,
      titulo: "t",
      cuerpo: "c",
      intentos: 0,
    }),
    "fallida",
  );
});
