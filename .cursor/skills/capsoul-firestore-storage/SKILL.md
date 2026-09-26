---
name: capsoul-firestore-storage
description: >-
  Use when implementing Capsoul repositories for Cloud Firestore or Firebase
  Storage (capsules, media, profile, legacy).
---
# Capsoul Firestore Storage

Use when implementing Capsoul repositories that read/write Cloud Firestore or Firebase Storage (capsules, media, profile, legacy).

## Layering
UI → notifier/controller → repository → Firebase SDK.
Never call `FirebaseFirestore` / `FirebaseStorage` from widgets.

## Firestore habits
1. One repository per aggregate (`CapsuleRepository`, `UserRepository`, …).
2. Map docs to typed models with null-safe parsing; fail closed on corrupt docs.
3. Prefer stream listeners for live lists; one-shot gets for detail when enough.
4. Batch/transaction when creating capsule + media metadata must stay consistent.
5. Collection paths stay stable and documented (e.g. `users/{uid}`, `capsules/{id}`).
6. Query only fields you index; plan composite indexes with the query.
7. Paginate with cursors for feeds; avoid unbounded `get()` on large collections.

## Storage habits
1. Path convention: `capsules/{capsuleId}/{mediaId}` (or equivalent documented tree).
2. Upload with content type and reasonable size limits; show progress in UI.
3. Store download metadata in Firestore; do not invent alternate public buckets for sealed media.
4. Delete Storage objects when deleting a capsule (or enqueue cleanup Function).
5. Handle offline/errors: map Firebase exceptions to domain failures the UI can show in Spanish.

## Integrity tie-in
Before any read of sealed media, check product rules and Security Rules assumptions. Client-side “if unlocked” is not enough.

## Done when
- Repository is unit-testable behind an interface
- Errors are typed/handled
- No secrets in client code
- Paths match Security Rules
