import { assertEquals, assertRejects } from "jsr:@std/assert@1";

import {
  acotarLimite,
  buscarEnDeezer,
  ErrorBusquedaDeezer,
  LIMITE_MAX,
  mapearPistaDeezer,
  mapearResultadosDeezer,
  urlBusquedaDeezer,
} from "./deezer.ts";

const pistaCompleta = {
  id: 3135556,
  title: "Harder, Better, Faster, Stronger",
  link: "https://www.deezer.com/track/3135556",
  preview: "https://cdns-preview.dzcdn.net/stream/c-1.mp3",
  artist: { name: "Daft Punk" },
  album: {
    title: "Discovery",
    cover: "https://cdn.example/cover.jpg",
    cover_big: "https://cdn.example/big.jpg",
    cover_medium: "https://cdn.example/medium.jpg",
  },
};

Deno.test("mapearPistaDeezer conserva el formato y marca proveedor deezer", () => {
  const resultado = mapearPistaDeezer(pistaCompleta);
  assertEquals(resultado, {
    proveedor: "deezer",
    idExterno: "3135556",
    titulo: "Harder, Better, Faster, Stronger",
    artista: "Daft Punk",
    previewUrl: "https://cdns-preview.dzcdn.net/stream/c-1.mp3",
    previewProveedor: "deezer",
    enlaceDeezer: "https://www.deezer.com/track/3135556",
    urlCompleta: "https://www.deezer.com/track/3135556",
    uriProfundo: "deezer://www.deezer.com/track/3135556",
    portadaUrl: "https://cdn.example/medium.jpg",
  });
});

Deno.test("mapearPistaDeezer construye enlace y deep link desde el id", () => {
  const resultado = mapearPistaDeezer({
    id: "99",
    title: "T",
    artist: { name: "A" },
    preview: "  https://cdn.example/t.mp3  ",
  });
  assertEquals(resultado?.enlaceDeezer, "https://www.deezer.com/track/99");
  assertEquals(resultado?.urlCompleta, "https://www.deezer.com/track/99");
  assertEquals(resultado?.uriProfundo, "deezer://www.deezer.com/track/99");
  assertEquals(resultado?.previewUrl, "https://cdn.example/t.mp3");
  assertEquals(resultado?.portadaUrl, null);
});

Deno.test("mapearPistaDeezer sin preview deja previewProveedor en null", () => {
  const resultado = mapearPistaDeezer({
    id: 1,
    title: "T",
    artist: { name: "A" },
    preview: "  ",
    album: { cover: "https://cdn.example/cover.jpg" },
  });
  assertEquals(resultado?.previewUrl, null);
  assertEquals(resultado?.previewProveedor, null);
  assertEquals(resultado?.portadaUrl, "https://cdn.example/cover.jpg");
});

Deno.test("mapearPistaDeezer descarta pistas incompletas", () => {
  assertEquals(mapearPistaDeezer({ title: "T", artist: { name: "A" } }), null);
  assertEquals(mapearPistaDeezer({ id: 1, artist: { name: "A" } }), null);
  assertEquals(mapearPistaDeezer({ id: 1, title: "T" }), null);
  assertEquals(mapearPistaDeezer({ id: -1, title: "T", artist: { name: "A" } }), null);
});

Deno.test("mapearResultadosDeezer omite filas inválidas y conserva el orden", () => {
  const resultados = mapearResultadosDeezer([
    { id: 1, title: "Una", artist: { name: "A" } },
    null,
    "no-es-pista",
    { title: "sin id" },
    { id: 2, title: "Dos", artist: { name: "B" }, preview: "https://cdn.example/b.mp3" },
  ]);
  assertEquals(resultados.map((p) => p.idExterno), ["1", "2"]);
  assertEquals(resultados[1]?.previewProveedor, "deezer");
});

Deno.test("acotarLimite nunca pasa de 10", () => {
  assertEquals(acotarLimite(undefined), LIMITE_MAX);
  assertEquals(acotarLimite(0), 1);
  assertEquals(acotarLimite(3.9), 3);
  assertEquals(acotarLimite(50), 10);
  assertEquals(acotarLimite("3"), 3);
  assertEquals(acotarLimite("50"), 10);
  assertEquals(acotarLimite("  "), 10);
  assertEquals(acotarLimite(Number.NaN), 10);
});

Deno.test("urlBusquedaDeezer pide como máximo el límite acotado", () => {
  const url = new URL(urlBusquedaDeezer("daft punk", 10));
  assertEquals(url.origin + url.pathname, "https://api.deezer.com/search");
  assertEquals(url.searchParams.get("q"), "daft punk");
  assertEquals(url.searchParams.get("limit"), "10");
});

function fetchJson(cuerpo: unknown, estado = 200): typeof fetch {
  return () =>
    Promise.resolve(
      new Response(JSON.stringify(cuerpo), {
        status: estado,
        headers: { "Content-Type": "application/json" },
      }),
    );
}

Deno.test("buscarEnDeezer mapea data, topa el límite en 10 y no pide token", async () => {
  let urlPedida = "";
  const fetchCaptura: typeof fetch = (input, init) => {
    urlPedida = String(input);
    assertEquals(new Headers(init?.headers).get("Authorization"), null);
    return fetchJson({ data: [pistaCompleta] })(input);
  };
  const resultados = await buscarEnDeezer("daft", 50, { fetch: fetchCaptura });
  assertEquals(resultados.length, 1);
  assertEquals(resultados[0]?.proveedor, "deezer");
  assertEquals(resultados[0]?.idExterno, "3135556");
  const url = new URL(urlPedida);
  assertEquals(url.searchParams.get("limit"), "10");
  assertEquals(url.searchParams.get("q"), "daft");
});

Deno.test("buscarEnDeezer traduce la cuota de Deezer", async () => {
  const error = await assertRejects(
    () => buscarEnDeezer("q", 10, { fetch: fetchJson({ error: { code: 4, message: "Quota" } }) }),
    ErrorBusquedaDeezer,
  );
  assertEquals(error.codigo, "deezer_cuota");

  const porHttp = await assertRejects(
    () => buscarEnDeezer("q", 10, { fetch: fetchJson({}, 429) }),
    ErrorBusquedaDeezer,
  );
  assertEquals(porHttp.codigo, "deezer_cuota");
});

Deno.test("buscarEnDeezer falla cerrado ante HTTP, JSON o cuerpo sin data", async () => {
  const http = await assertRejects(
    () => buscarEnDeezer("q", 10, { fetch: fetchJson({ error: { code: 800 } }, 200) }),
    ErrorBusquedaDeezer,
  );
  assertEquals(http.codigo, "deezer_error");

  const invalido: typeof fetch = () => Promise.resolve(new Response("no-json", { status: 200 }));
  const json = await assertRejects(
    () => buscarEnDeezer("q", 10, { fetch: invalido }),
    ErrorBusquedaDeezer,
  );
  assertEquals(json.codigo, "deezer_error");

  const sinData = await assertRejects(
    () => buscarEnDeezer("q", 10, { fetch: fetchJson({ total: 0 }) }),
    ErrorBusquedaDeezer,
  );
  assertEquals(sinData.codigo, "deezer_error");
});

Deno.test("buscarEnDeezer trata el tiempo agotado como error de Deezer", async () => {
  const fetchCuelga: typeof fetch = (_input, init) =>
    new Promise((_resolve, reject) => {
      const abortar = () => {
        const e = new Error("The signal has been aborted");
        e.name = "AbortError";
        reject(e);
      };
      if (init?.signal?.aborted) {
        abortar();
        return;
      }
      init?.signal?.addEventListener("abort", abortar, { once: true });
    });
  const error = await assertRejects(
    () => buscarEnDeezer("q", 10, { fetch: fetchCuelga, tiempoMs: 20 }),
    ErrorBusquedaDeezer,
  );
  assertEquals(error.codigo, "deezer_error");
});
