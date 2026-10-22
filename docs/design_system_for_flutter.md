# Design.md — Cápsoul App UI Specification

This document outlines the design specifications extracted from the main app mockup (`principal1.jpg`). It is tailored specifically for implementation in **Flutter** using Material 3 principles, custom themes, and modern UI practices.

---

## 1. Design Overview & Theme Mood
* **App Name:** Cápsoul
* **Vibe / Tone:** Emotional, celestial, elegant, trustworthy, and nostalgic.
* **Theme Mode:** Light Mode (with deep royal blue accents and soft ice-blue atmospheric gradients).
* **Core Philosophy:** Glassmorphism and clean card-based layout with soft blue-tinted drop shadows.

---

## 2. Color Palette & Gradients

Define these colors in your `AppColors` class or inside your Flutter `ThemeData`.

### Primary & Neutral Colors
* **Primary (Deep Royal Blue):** `Color(0xFF1B316B)` — Used for primary buttons, active navigation items, main logo text, and borders.
* **Secondary / Accent (Warm Gold):** `Color(0xFFF59E0B)` / `Color(0xFFFDE68A)` — Used for capsule glow effects, stars, and heart icons.
* **Background Base (Ice Blue Gradient Start):** `Color(0xFFE8F1FC)`
* **Background End (Ice Blue Gradient Fade):** `Color(0xFFF5F8FC)`
* **Card Surface (Pure White / Glass):** `Color(0xFFFFFFFF)` with opacity or subtle border `Color(0xFFD6E4F0)`.
* **Text Primary (Dark Navy):** `Color(0xFF111E38)` — Used for main titles and headings.
* **Text Secondary (Muted Blue-Gray):** `Color(0xFF5A6E94)` — Used for subtitles, descriptions, and metadata.

### Background Gradient Implementation (Flutter)
```dart
BoxDecoration backgroundGradient = BoxDecoration(
  gradient: LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFFE2EDF8),
      Color(0xFFF4F8FC),
    ],
  ),
);
```

---

## 3. Typography

* **Primary Font Family (Body & UI):** `Poppins` or `Inter` (Clean modern sans-serif).
* **Logo / Brand Font Family (Headers):** `Playfair Display` or a rounded elegant Serif font.

### Text Styles (`TextTheme` extensions)
* **Logo Title:** 
  * Font: Serif, Bold, Size: `28.0`, Color: `Color(0xFF1B316B)`, Letter Spacing: `1.2`.
* **Subtitle (Header):** 
  * Font: Poppins, Regular, Size: `13.0`, Color: `Color(0xFF5A6E94)`.
* **Section Heading / Card Title:** 
  * Font: Poppins, SemiBold, Size: `16.0`, Color: `Color(0xFF111E38)`.
* **Card Subtitle / Body:** 
  * Font: Poppins, Regular, Size: `12.0`, Color: `Color(0xFF5A6E94)`.
* **Button Text:** 
  * Font: Poppins, Medium, Size: `14.0`, Color: `Color(0xFFFFFFFF)`.

---

## 4. Layout, Components, Margins & Padding

### Global Spacing Rules
* **Screen Padding (Horizontal):** `16.0` to `20.0` dp.
* **Card Border Radius (`BorderRadius`):** `20.0` dp (`BorderRadius.circular(20)`).
* **Card Padding:** `16.0` dp internal padding.
* **Card Elevation & Shadows:**
  ```dart
  BoxShadow cardShadow = BoxShadow(
    color: Color(0x141B316B), // 8% opacity royal blue
    blurRadius: 16.0,
    offset: Offset(0, 6),
  );
  ```

### Specific Components

#### 1. Hero / Main Capsule Banner Card
* **Container:** Stack layout with illustration background and floating text on the right side.
* **CTA Button ("Guardar algo hoy"):**
  * Height: `48.0` dp
  * Background: `Color(0xFF1B316B)` (Primary Blue)
  * Border Radius: Pill shape (`BorderRadius.circular(30)`)
  * Content: Icon (`Icons.add`) + Text ("Guardar algo hoy") in white.
  * Subtitle below button: Center-aligned text `Color(0xFF5A6E94)`, size `12.0`.

#### 2. Feature Cards (2x2 Grid)
* **Grid Delegate:** `SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 16, mainAxisSpacing: 16, childAspectRatio: 0.95)`
* **Card Design:** 
  * Solid white surface with a subtle 1px border (`Color(0xFFE2EAF4)`).
  * Contains an icon badge on the top-left, bold title, subtitle, counter (e.g., "128"), and a small thumbnail image/illustration preview on the bottom right.

#### 3. Bottom Banner Card ("No se trata de tener más tiempo...")
* **Container:** Full-width horizontal card.
* **Background:** Deep rich navy gradient or solid white with deep blue theme (`Color(0xFF132247)` variant or clean white with illustration). Based on the mockup, it has a dark/midnight blue background tone with white text and a glowing jar illustration.
* **Border Radius:** `20.0` dp.

#### 4. Bottom Navigation Bar
* **Style:** Floating customized bottom bar or styled `BottomNavigationBar` / `NavigationBar`.
* **Items:** 
  1. `Inicio` (Home)
  2. `Momento` (Heart icon)
  3. **Central Action Button:** Prominent floating circular primary button (`+`) in royal blue (`Color(0xFF1B316B)`).
  4. `Historia` (Book icon)
  5. `Yo` (Profile icon)
* **Unselected Item Color:** `Color(0xFF6F82A6)`
* **Selected Item Color:** `Color(0xFF1B316B)`

---

## 5. Icons & Assets Mapping

Use standard **Material Icons** or custom SVGs mapped as follows:
* **Notifications (Top Right):** `Icons.notifications_outlined`
* **Inicio:** `Icons.home_outlined` / `Icons.home`
* **Momento:** `Icons.favorite_border` / `Icons.favorite`
* **Action Center:** `Icons.add`
* **Historia:** `Icons.menu_book_outlined` / `Icons.book`
* **Yo (Profile):** `Icons.person_outline` / `Icons.person`
* **Recuerdos Card Icon:** `Icons.photo_camera_outlined` or custom photo icon.
* **Retos Card Icon:** `Icons.flag_outlined`
* **Cápsulas Card Icon:** `Icons.lock_outline`
* **Herencias Card Icon:** `Icons.card_giftcard` or `Icons.redeem`

---

## 6. Flutter Code Boilerplate Suggestions for Agent

Provide these instructions to your code agent:
1. **Theme Setup:** Configure `ThemeData` in `main.dart` with `ColorScheme.fromSeed(seedColor: Color(0xFF1B316B))` and override font families to use `Poppins`.
2. **Custom Widgets:** Create a reusable `CapsuleCard` widget that takes a title, subtitle, count, icon, and optional image widget to cleanly build the 2x2 grid without code duplication.
3. **Scaffold Background:** Ensure all primary screens wrap their body in a `Container` with the background linear gradient.