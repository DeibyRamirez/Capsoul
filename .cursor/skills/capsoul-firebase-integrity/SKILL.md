---
name: capsoul-firebase-integrity
description: >-
  Use when designing Auth, Firestore/Storage rules, capsule unlock integrity, or
  Capsoul security-sensitive data paths.
---
# Capsoul Firebase integrity

Use when designing Auth, Firestore rules, Storage rules, capsule unlock logic, privacy, or any security-sensitive Capsoul data path.

## Threat model (MVP)
- Locked media and capsule fields must not leak before `unlockDate`
- Recipients and trusted persons must only see what privacy allows
- Client apps are hostile: never trust UI checks alone

## Hard rules
1. Security Rules are the source of truth. UI countdown/lock is UX only.
2. Capsule documents store `unlockDate`, `status`, `ownerId`, `recipientIds`, `privacy`. Rules must deny media/content reads while locked for non-owners (and often even for owners if product requires sealed until date — follow product decision; default: sealed content unreadable until unlock for everyone except server-side Functions if needed).
3. Prefer writing sealed media to Storage paths gated by the same unlock condition; do not rely on obscurity of URLs.
4. Auth: all user-owned writes require `request.auth != null` and `request.auth.uid` matching owner (or explicit member role).
5. Never embed service account keys or admin SDKs in the Flutter app.
6. Validate shapes in rules (`keys().hasOnly(...)`, typed fields) to stop mass-assignment.
7. Time: compare unlock with `request.time` in rules; do not trust a client-sent `isUnlocked` boolean.
8. Cloud Functions may perform privileged unlock/notify work; document which paths are client vs admin.

## Review checklist
- Rules deny premature Storage download of locked media
- Rules deny premature Firestore read of sealed payload fields
- Indexes exist for planned queries
- FCM topics/tokens cannot escalate to other users' capsules
