// Capsoul · transformaciones eager (subida) y entrega (firmar-medio) deben coincidir
// en recursos authenticated (solo existe el derivado eager guardado).

/** `transformation` en la Download API para la miniatura de foto. */
export const TRANSFORMACION_MINIATURA_FOTO = "c_limit,w_480,q_auto";

/** `transformation` en la Download API para la miniatura de video. */
export const TRANSFORMACION_MINIATURA_VIDEO = "so_0,c_limit,w_480,q_auto";

/** Parámetro `eager` al subir (incluye formato de salida). */
export const EAGER_SUBIDA_FOTO = `${TRANSFORMACION_MINIATURA_FOTO}/jpg`;

export const EAGER_SUBIDA_VIDEO = `${TRANSFORMACION_MINIATURA_VIDEO}/jpg`;
