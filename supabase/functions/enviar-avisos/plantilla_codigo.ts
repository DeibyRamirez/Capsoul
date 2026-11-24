/** Correo transaccional con el código de acceso a un legado. */

export type DatosCorreoCodigo = {
  codigo: string;
  tituloHerencia: string;
  propietarioNombre: string;
  expiraEn: string;
};

function escaparHtml(texto: string): string {
  return texto
    .replaceAll("&", "&amp;")
    .replaceAll("<", "&lt;")
    .replaceAll(">", "&gt;")
    .replaceAll('"', "&quot;")
    .replaceAll("'", "&#39;");
}

export function armarCorreoCodigoHerencia(datos: DatosCorreoCodigo): {
  asunto: string;
  html: string;
  texto: string;
} {
  const titulo = escaparHtml(datos.tituloHerencia.trim() || "tu legado");
  const propietario = escaparHtml(
    datos.propietarioNombre.trim() || "Alguien",
  );
  const codigo = escaparHtml(datos.codigo);
  const tituloAsunto = (datos.tituloHerencia.trim() || "tu legado").replaceAll(
    /[\r\n]+/g,
    " ",
  );
  const asunto = `Tu código para abrir «${tituloAsunto}»`;

  const texto =
    `Hola.\n\n${datos.propietarioNombre || "Alguien"} abrió «${
      datos.tituloHerencia || "un legado"
    }» en Capsoul y te eligió como persona de confianza.\n\n` +
    `Tu código de acceso es: ${datos.codigo}\n\n` +
    `Ingrésalo en Capsoul para ver el contenido y ayudar a quien recibe la herencia. ` +
    `El código vence en 20 minutos.\n\n` +
    `Si no esperabas este correo, ignóralo.\n\nCapsoul · Pequeñas herencias, grandes recuerdos`;

  const html = `<!DOCTYPE html>
<html lang="es">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>${titulo}</title>
</head>
<body style="margin:0;padding:0;background-color:#F5F7FA;font-family:-apple-system,BlinkMacSystemFont,'Segoe UI',Roboto,Helvetica,Arial,sans-serif;">
  <table role="presentation" width="100%" cellspacing="0" cellpadding="0" border="0" style="background-color:#F5F7FA;">
    <tr>
      <td align="center" style="padding:24px 16px;">
        <table role="presentation" width="100%" cellspacing="0" cellpadding="0" border="0" style="max-width:560px;">
          <tr>
            <td style="background:linear-gradient(180deg,#1B2A4A 0%,#1B2A4A 55%,#3D6B9A 100%);border-radius:20px 20px 0 0;padding:32px 24px;text-align:center;">
              <p style="margin:0 0 8px;font-family:Georgia,'Times New Roman',serif;font-size:28px;font-weight:500;color:#FFFFFF;letter-spacing:1px;">Capsoul</p>
              <p style="margin:0;font-size:14px;font-style:italic;color:rgba(255,255,255,0.85);">Pequeñas herencias, grandes recuerdos</p>
            </td>
          </tr>
          <tr>
            <td style="background-color:#FFFFFF;border-radius:0 0 20px 20px;padding:32px 28px;">
              <h2 style="margin:0 0 16px;font-family:Georgia,'Times New Roman',serif;font-size:22px;font-weight:500;color:#1B2A4A;">Tu código para abrir el legado</h2>
              <p style="margin:0 0 12px;font-size:16px;line-height:1.6;color:#1A1A2E;">${propietario} abrió <strong>«${titulo}»</strong> en Capsoul y te eligió como persona de confianza.</p>
              <p style="margin:0 0 24px;font-size:16px;line-height:1.6;color:#1A1A2E;">Usa este código para ver el contenido y ayudar a quien recibe la herencia. Vence en 20 minutos.</p>
              <table role="presentation" width="100%" cellspacing="0" cellpadding="0" border="0" style="margin:0 0 24px;">
                <tr>
                  <td align="center" style="padding:20px 16px;background-color:#F5F7FA;border:1px solid rgba(107,114,128,0.2);border-radius:16px;">
                    <p style="margin:0;font-family:'Courier New',Courier,monospace;font-size:32px;font-weight:700;letter-spacing:6px;color:#1B2A4A;">${codigo}</p>
                  </td>
                </tr>
              </table>
              <p style="margin:0 0 8px;font-size:13px;line-height:1.5;color:#6B7280;">Si no esperabas este correo, puedes ignorarlo.</p>
              <p style="margin:0;font-size:13px;line-height:1.5;color:#6B7280;">Por seguridad, no compartas este código con nadie.</p>
            </td>
          </tr>
          <tr>
            <td style="padding:20px 8px 0;text-align:center;">
              <p style="margin:0;font-size:12px;line-height:1.5;color:#6B7280;">Capsoul · Pequeñas herencias, grandes recuerdos</p>
            </td>
          </tr>
        </table>
      </td>
    </tr>
  </table>
</body>
</html>`;

  return { asunto, html, texto };
}
