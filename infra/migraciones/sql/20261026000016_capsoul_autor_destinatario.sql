-- Capsoul · El autor puede ser destinatario de su propia cápsula (DEV-95).
-- La política de 000009 exigía amistad consigo mismo, y eso no existe.
-- privado.capsula_editable_por_mi (000001) hoy solo es verdad si el llamador
-- es el autor y la cápsula está en borrador o programada. Aun así, el atajo
-- de «yo mismo» no usa auth.uid(): compara con el autor de la cápsula. Si esa
-- función llegara a dejar editar a otra persona, esa persona no puede
-- apuntarse sin ser amiga del autor. No edita migraciones ya aplicadas.

drop policy if exists capsula_destinatarios_crear on public.capsula_destinatarios;

create policy capsula_destinatarios_crear on public.capsula_destinatarios
  for insert to authenticated
  with check (
    privado.capsula_editable_por_mi(capsula_id)
    and usuario_id is not null
    and (
      usuario_id = (
        select c.autor_id from public.capsulas c where c.id = capsula_id
      )
      or privado.son_amigos(
        (select c.autor_id from public.capsulas c where c.id = capsula_id),
        usuario_id
      )
    )
  );
