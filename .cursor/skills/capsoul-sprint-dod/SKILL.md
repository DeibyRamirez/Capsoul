---
name: capsoul-sprint-dod
description: >-
  Use when starting a Capsoul story, splitting sprint work, or checking
  Definition of Done before demo.
---
# Capsoul sprint DoD

Use when starting a Capsoul user story, splitting work, or checking if a sprint item is demoable.

## Roles
- Product Owner (THE CHEIVIZ): value and acceptance
- Scrum Master / peer (Capsoul bot): prioritizes, clarifies stories, reviews DoD
- Flutter senior + engineers: implement

## Story shape
1. User story with acceptance criteria in Spanish product language
2. Technical notes only where they unblock (paths, rules, packages)
3. Out of scope called out (especially phase 2 Legal/marketplace/map)

## Definition of Done (general)
- Acceptance criteria met on a real device or emulator
- `flutter analyze` clean for touched code
- No broken nav or placeholder crashes
- Theme/nav still match Capsoul UI skill
- Security-sensitive paths considered if data is involved
- Demo notes ready for sprint review

## Sprint 1 specific (cimientos)
1. `flutter create capsoul --org com.capsoul --platforms=android,ios`
2. Feature folder structure present
3. Capsoul theme applied
4. Bottom nav 5 zones; `+` opens Create selector
5. FlutterFire configure + `firebase_core` init without crash
6. Tab placeholders; Home greeting mock + dome slot
Auth UI is Sprint 2 — do not expand S1 into Auth.

## Handoff
When DoD is met, notify Capsoul for review and unlock of the next sprint focus.
