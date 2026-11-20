-- Notas enriquecidas (WYSIWYG).
--
-- `contenido_texto` sigue siendo la fuente de verdad del texto visible y el
-- límite de 5000 caracteres. `contenido_rico` guarda el Delta de Quill para
-- conservar negrita, cursiva y subrayado sin exponer símbolos Markdown.
--
-- Es nullable para mantener compatibilidad con notas antiguas (que siguen
-- usando Markdown dentro de `contenido_texto`) y con las versiones anteriores
-- de la app (que mostrarán el texto plano).

alter table public.elementos
  add column contenido_rico jsonb;

comment on column public.elementos.contenido_rico is
  'Delta JSON de notas enriquecidas (solo tipo texto); null en notas legacy y medios.';

alter table public.elementos
  add constraint elementos_rico_solo_texto check (
    contenido_rico is null or tipo = 'texto'
  );

alter table public.elementos
  add constraint elementos_rico_objeto check (
    contenido_rico is null or jsonb_typeof(contenido_rico) = 'object'
  );

-- Hace que PostgREST vea la nueva columna sin esperar al refresco periódico.
notify pgrst, 'reload schema';
