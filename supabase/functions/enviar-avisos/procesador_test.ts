import { assertEquals } from "jsr:@std/assert@1";
import { atenderAvisos, procesarLote, type DependenciasAvisos, type FilaAviso } from "./procesador.ts";
import type { ResultadoEnvioFcm } from "./fcm.ts";

const CAPSULA = "c1000000-0000-0000-0000-0000000000c1";
const USUARIO = "u1000000-0000-0000-0000-0000000000a1";

type AvisoMemoria = FilaAviso & {
  estado: "pendiente" | "enviada" | "fallida";
  reclamado: boolean;
  ultimoError: string | null;
};

type EntregaMemoria = {
  notificacionId: string;
  token: string;
  estado: "enviada" | "fallida" | "invalida";
  intentos: number;
};

function mundo(opciones?: {
  avisos?: AvisoMemoria[];
  tokens?: string[];
  fcm?: (token: string) => ResultadoEnvioFcm;
}) {
  const avisos = opciones?.avisos ?? [];
  const tokens = new Set(opciones?.tokens ?? []);
  const entregas: EntregaMemoria[] = [];
  const envios: string[] = [];
  const borrados: string[] = [];
  let correos = 0;

  const reclamar = (lote: number): Promise<FilaAviso[]> => {
    const libres = avisos
      .filter((aviso) => aviso.estado === "pendiente" && !aviso.reclamado)
      .slice(0, lote);
    for (const aviso of libres) aviso.reclamado = true;
    return Promise.resolve(libres.map((aviso) => ({ ...aviso })));
  };

  const deps: DependenciasAvisos = {
    llaveCron: "llave-correcta",
    reclamar,
    tituloReferencia: (fila) => {
      if (fila.tipo === "capsula_liberada" && fila.referencia_id === CAPSULA) {
        return Promise.resolve("Viaje al río");
      }
      return Promise.resolve(null);
    },
    tokensDe: () => Promise.resolve([...tokens]),
    entregasDe: (id) =>
      Promise.resolve(
        entregas
          .filter((entrega) => entrega.notificacionId === id)
          .map((entrega) => ({
            token: entrega.token,
            estado: entrega.estado,
            intentos: entrega.intentos,
          })),
      ),
    guardarEntrega: (args) => {
      const previa = entregas.find((entrega) =>
        entrega.notificacionId === args.notificacionId && entrega.token === args.token
      );
      if (previa) {
        previa.estado = args.estado;
        previa.intentos = args.intentos;
      } else {
        entregas.push({
          notificacionId: args.notificacionId,
          token: args.token,
          estado: args.estado,
          intentos: args.intentos,
        });
      }
      return Promise.resolve();
    },
    borrarToken: (token) => {
      tokens.delete(token);
      borrados.push(token);
      return Promise.resolve();
    },
    cerrar: (pedido) => {
      const aviso = avisos.find((fila) => fila.id === pedido.id);
      if (!aviso) return Promise.resolve();
      aviso.estado = pedido.estado;
      aviso.intentos = pedido.intentos;
      aviso.ultimoError = pedido.ultimoError;
      if (pedido.liberarReclamo) aviso.reclamado = false;
      return Promise.resolve();
    },
    enviarPush: (args) => {
      envios.push(args.token);
      const resultado = opciones?.fcm?.(args.token) ?? { ok: true, status: 200, codigo: null, detalle: "" };
      return Promise.resolve(resultado);
    },
    enviarCorreo: () => {
      correos++;
      return Promise.resolve();
    },
  };

  return { avisos, tokens, entregas, envios, borrados, deps, get correos() { return correos; } };
}

function avisoPush(id: string, extra?: Partial<AvisoMemoria>): AvisoMemoria {
  return {
    id,
    canal: "push",
    tipo: "capsula_liberada",
    usuario_id: USUARIO,
    correo_destino: null,
    referencia_id: CAPSULA,
    titulo: "Tienes una cápsula nueva",
    cuerpo: "Una cápsula del tiempo acaba de abrirse para ti.",
    intentos: 0,
    estado: "pendiente",
    reclamado: false,
    ultimoError: null,
    ...extra,
  };
}

Deno.test("llave inválida o ausente responde 401 y no reclama", async () => {
  let reclamos = 0;
  const base = mundo();
  base.deps.reclamar = () => {
    reclamos++;
    return Promise.resolve([]);
  };
  const sinLlave = await atenderAvisos(
    new Request("https://capsoul.test/enviar-avisos", { method: "POST" }),
    base.deps,
  );
  const mala = await atenderAvisos(
    new Request("https://capsoul.test/enviar-avisos", {
      method: "POST",
      headers: { "x-llave-cron": "otra" },
    }),
    base.deps,
  );
  assertEquals(sinLlave.status, 401);
  assertEquals(mala.status, 401);
  assertEquals(reclamos, 0);
});

Deno.test("el lote nombra la cápsula y un segundo pase no duplica", async () => {
  const primero = avisoPush("n1");
  const segundo = avisoPush("n2", {
    referencia_id: "c1000000-0000-0000-0000-0000000000c2",
  });
  const estado = mundo({
    avisos: [primero, segundo],
    tokens: ["token-ok"],
  });
  const cuerpos: string[] = [];
  const enviar = estado.deps.enviarPush;
  estado.deps.enviarPush = async (args) => {
    cuerpos.push(args.cuerpo);
    assertEquals(args.data.ruta, `capsoul://capsula/${args.data.capsula_id}`);
    assertEquals(args.data.capsula_id.length > 0, true);
    return await enviar(args);
  };

  const r1 = await procesarLote(estado.deps);
  const r2 = await procesarLote(estado.deps);
  assertEquals(r1, { procesadas: 2, enviadas: 2, fallidas: 0 });
  assertEquals(r2, { procesadas: 0, enviadas: 0, fallidas: 0 });
  assertEquals(estado.envios, ["token-ok", "token-ok"]);
  assertEquals(cuerpos[0], "«Viaje al río» ya se puede abrir.");
  assertEquals(primero.estado, "enviada");
  assertEquals(segundo.estado, "enviada");
});

Deno.test("dos reclamos a la vez no envían el mismo aviso dos veces", async () => {
  const estado = mundo({
    avisos: [avisoPush("n1")],
    tokens: ["token-ok"],
  });
  const [a, b] = await Promise.all([
    procesarLote(estado.deps),
    procesarLote(estado.deps),
  ]);
  const procesadas = a.procesadas + b.procesadas;
  assertEquals(procesadas, 1);
  assertEquals(estado.envios.length, 1);
});

Deno.test("un token UNREGISTERED se borra y no se reintenta", async () => {
  const aviso = avisoPush("n1");
  const estado = mundo({
    avisos: [aviso],
    tokens: ["token-malo", "token-ok"],
    fcm: (token) => {
      if (token === "token-malo") {
        return {
          ok: false,
          status: 404,
          codigo: "UNREGISTERED",
          detalle: "UNREGISTERED",
        };
      }
      return { ok: true, status: 200, codigo: null, detalle: "" };
    },
  });
  const r1 = await procesarLote(estado.deps);
  assertEquals(r1.enviadas, 1);
  assertEquals(estado.borrados, ["token-malo"]);
  assertEquals(estado.tokens.has("token-malo"), false);
  assertEquals(
    estado.entregas.find((entrega) => entrega.token === "token-malo")?.estado,
    "invalida",
  );

  estado.envios.length = 0;
  aviso.estado = "pendiente";
  aviso.reclamado = false;
  const r2 = await procesarLote(estado.deps);
  assertEquals(r2.procesadas, 1);
  assertEquals(estado.envios.includes("token-malo"), false);
  assertEquals(estado.envios.includes("token-ok"), false);
});

Deno.test("el reintento parcial solo vuelve a enviar el token que falló", async () => {
  const aviso = avisoPush("n1");
  let falla = true;
  const estado = mundo({
    avisos: [aviso],
    tokens: ["token-ok", "token-lento"],
    fcm: (token) => {
      if (token === "token-lento" && falla) {
        return { ok: false, status: 503, codigo: "UNAVAILABLE", detalle: "no disponible" };
      }
      return { ok: true, status: 200, codigo: null, detalle: "" };
    },
  });

  const r1 = await procesarLote(estado.deps);
  assertEquals(r1.enviadas, 0);
  assertEquals(r1.fallidas, 1);
  assertEquals(aviso.estado, "pendiente");
  assertEquals(aviso.reclamado, false);
  assertEquals(aviso.intentos, 1);
  assertEquals(estado.envios.filter((token) => token === "token-ok").length, 1);
  assertEquals(estado.envios.filter((token) => token === "token-lento").length, 1);

  falla = false;
  estado.envios.length = 0;
  const r2 = await procesarLote(estado.deps);
  assertEquals(r2.enviadas, 1);
  assertEquals(estado.envios, ["token-lento"]);
  assertEquals(aviso.estado, "enviada");
});

Deno.test("el mismo id dos veces en el lote solo se envía una vez", async () => {
  const aviso = avisoPush("n1");
  const estado = mundo({ avisos: [aviso], tokens: ["token-ok"] });
  estado.deps.reclamar = () => Promise.resolve([{ ...aviso }, { ...aviso }]);
  const resumen = await procesarLote(estado.deps);
  assertEquals(resumen.procesadas, 1);
  assertEquals(estado.envios.length, 1);
});

Deno.test("el correo sigue saliendo por Resend y no por FCM", async () => {
  const aviso = avisoPush("correo-1", {
    canal: "correo",
    usuario_id: null,
    correo_destino: "externo@capsoul.app",
  });
  const estado = mundo({ avisos: [aviso], tokens: ["token-ok"] });
  const resumen = await procesarLote(estado.deps);
  assertEquals(resumen.enviadas, 1);
  assertEquals(estado.correos, 1);
  assertEquals(estado.envios.length, 0);
  assertEquals(aviso.estado, "enviada");
});
