/** Plantillas en español del aviso. El `data.ruta` es el deep link `capsoul://`. */

export const CANAL_AVISOS_ANDROID = "capsoul_avisos";

export type ContenidoAviso = {
  titulo: string;
  cuerpo: string;
  data: Record<string, string>;
};

export type DatosPlantilla = {
  tipo: string;
  referenciaId: string;
  tituloGuardado: string;
  cuerpoGuardado: string;
  tituloReferencia: string | null;
};

function ruta(host: string, id?: string): string {
  if (!id) return `capsoul://${host}`;
  return `capsoul://${host}/${encodeURIComponent(id)}`;
}

/**
 * Arma título, cuerpo y data según el tipo.
 * Cápsula liberada nombra el frasco. El resto queda listo para cuando
 * el evento inserte la fila (amistad, legado, reto).
 */
export function armarContenido(datos: DatosPlantilla): ContenidoAviso {
  const id = datos.referenciaId;
  const nombre = datos.tituloReferencia?.trim() || null;
  const base = {
    tipo: datos.tipo,
    referencia_id: id,
  };

  switch (datos.tipo) {
    case "capsula_liberada": {
      const tituloCapsula = nombre ?? datos.tituloGuardado.trim();
      const identifica = tituloCapsula || id;
      return {
        titulo: "Tienes una cápsula nueva",
        cuerpo: `«${identifica}» ya se puede abrir.`,
        data: { ...base, capsula_id: id, ruta: ruta("capsula", id) },
      };
    }
    case "solicitud_amistad":
      return {
        titulo: "Nueva solicitud de amistad",
        cuerpo: "Alguien quiere ser tu amigo en Capsoul.",
        data: { ...base, ruta: ruta("amigos") },
      };
    case "herencia_liberada":
      return {
        titulo: "Tienes un legado disponible",
        cuerpo: nombre
          ? `«${nombre}» ya se puede ver.`
          : "Una herencia se activó y ya puedes verla.",
        data: { ...base, herencia_id: id, ruta: ruta("herencia", id) },
      };
    case "herencia_en_verificacion":
      return {
        titulo: "¿Sigues ahí?",
        cuerpo: "Abre Capsoul para que tu legado no se active.",
        data: { ...base, herencia_id: id, ruta: ruta("herencia", id) },
      };
    case "reto":
      return {
        titulo: "Tienes un reto",
        cuerpo: nombre
          ? `El reto «${nombre}» te está esperando.`
          : "Tienes un reto nuevo en Capsoul.",
        data: { ...base, reto_id: id, ruta: ruta("reto", id) },
      };
    default:
      return {
        titulo: datos.tituloGuardado,
        cuerpo: datos.cuerpoGuardado,
        data: { ...base, ruta: "capsoul://" },
      };
  }
}
