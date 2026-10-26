-- Capsoul · El autor puede ser destinatario de su propia cápsula (DEV-95).
-- La política de 000009 exigía amistad consigo mismo, y eso no existe.
-- Con esta política, el autor puede insertarse (cápsula «para mí mismo»)
-- o a un amigo. No edita migraciones ya aplicadas.

drop policy if exists capsula_destinatarios_crear on public.capsula_destinatarios;

create policy capsula_destinatarios_crear on public.capsula_destinatarios
  for insert to authenticated
  with check (
    privado.capsula_editable_por_mi(capsula_id)
    and usuario_id is not null
    and (
      usuario_id = (select auth.uid())
      or privado.son_amigos(
        (select c.autor_id from public.capsulas c where c.id = capsula_id),
        usuario_id
      )
    )
  );
