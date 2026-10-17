import { assertEquals } from "jsr:@std/assert";
import { elegirPreviewDeezer } from "./deezer_preview.ts";

Deno.test("elegirPreviewDeezer prefiere coincidencia de título", () => {
  const resultado = elegirPreviewDeezer(
    [
      {
        title: "Otra canción",
        preview: "https://cdn.example/a.mp3",
        artist: { name: "X" },
        link: "https://www.deezer.com/track/1",
      },
      {
        title: "Manicomio",
        preview: "https://cdn.example/b.mp3",
        artist: { name: "Cosculluela" },
        link: "https://www.deezer.com/track/2",
      },
    ],
    "Manicomio",
    "Cosculluela",
  );
  assertEquals(resultado?.previewUrl, "https://cdn.example/b.mp3");
  assertEquals(resultado?.deezerTrackUrl, "https://www.deezer.com/track/2");
});

Deno.test("elegirPreviewDeezer construye link desde id", () => {
  const resultado = elegirPreviewDeezer(
    [
      {
        id: 99,
        title: "T",
        preview: "https://cdn.example/t.mp3",
        artist: { name: "A" },
      },
    ],
    "T",
    "A",
  );
  assertEquals(resultado?.deezerTrackUrl, "https://www.deezer.com/track/99");
});

Deno.test("elegirPreviewDeezer sin preview devuelve null", () => {
  const resultado = elegirPreviewDeezer(
    [{ title: "T", preview: "", artist: { name: "A" } }],
    "T",
    "A",
  );
  assertEquals(resultado, null);
});
