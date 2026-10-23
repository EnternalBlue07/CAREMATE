---
name: CAREMATE
description: Medical-grade assistive robotics and clinical medication management companion
colors:
  primary: "#0D9488"
  primary-dark: "#0F766E"
  primary-accent: "#14B8A6"
  primary-light: "#CCFBF1"
  status-scheduled: "#3B82F6"
  status-command-sent: "#8B5CF6"
  status-dispensed: "#10B981"
  status-acknowledged: "#059669"
  status-failed: "#EF4444"
  status-warning: "#F59E0B"
  status-unknown: "#6B7280"
  neutral-bg: "#F8FAFC"
  neutral-surface: "#FFFFFF"
  neutral-border: "#E2E8F0"
  neutral-text: "#0F172A"
  neutral-muted: "#64748B"
  dark-bg: "#0B1320"
  dark-surface: "#152238"
  dark-border: "#1E293B"
  dark-text: "#FFFFFF"
  dark-muted: "#94A3B8"
typography:
  display:
    fontFamily: "Outfit, system-ui, sans-serif"
    fontSize: "32px"
    fontWeight: 700
    lineHeight: 1.2
    letterSpacing: "-0.02em"
  headline:
    fontFamily: "Outfit, system-ui, sans-serif"
    fontSize: "24px"
    fontWeight: 700
    lineHeight: 1.25
    letterSpacing: "-0.01em"
  title:
    fontFamily: "Outfit, system-ui, sans-serif"
    fontSize: "18px"
    fontWeight: 600
    lineHeight: 1.3
    letterSpacing: "0em"
  body:
    fontFamily: "Inter, system-ui, sans-serif"
    fontSize: "15px"
    fontWeight: 400
    lineHeight: 1.5
    letterSpacing: "0.01em"
  label:
    fontFamily: "Inter, system-ui, sans-serif"
    fontSize: "12px"
    fontWeight: 600
    lineHeight: 1.3
    letterSpacing: "0.02em"
rounded:
  xs: "4px"
  sm: "8px"
  md: "12px"
  lg: "16px"
  xl: "20px"
  full: "9999px"
spacing:
  xs: "4px"
  sm: "8px"
  md: "16px"
  lg: "20px"
  xl: "24px"
  xxl: "32px"
components:
  button-primary:
    backgroundColor: "{colors.primary}"
    textColor: "{colors.neutral-surface}"
    rounded: "{rounded.md}"
    padding: "14px 24px"
    height: "48px"
  button-primary-hover:
    backgroundColor: "{colors.primary-dark}"
    textColor: "{colors.neutral-surface}"
    rounded: "{rounded.md}"
    padding: "14px 24px"
    height: "48px"
  button-secondary:
    backgroundColor: "transparent"
    textColor: "{colors.primary}"
    rounded: "{rounded.md}"
    padding: "14px 24px"
    height: "48px"
  button-danger:
    backgroundColor: "{colors.status-failed}"
    textColor: "{colors.neutral-surface}"
    rounded: "{rounded.md}"
    padding: "14px 24px"
    height: "48px"
  card-surface:
    backgroundColor: "{colors.neutral-surface}"
    textColor: "{colors.neutral-text}"
    rounded: "{rounded.lg}"
    padding: "16px 16px"
  chip-status:
    backgroundColor: "{colors.primary-light}"
    textColor: "{colors.primary-dark}"
    rounded: "{rounded.full}"
    padding: "6px 12px"
---

# Design System: CAREMATE

## Overview

**Creative North Star: "The Reassuring Clinical Companion"**

CAREMATE bridges physical robotics and clinical pharmacotherapy for elderly patients and remote caregivers. The visual language balances hospital-grade clinical authority with the warmth and emotional reassurance required in a domestic living space. It replaces cold utilitarianism with soothing deep teals, slate neutrals, crisp typography, and high-visibility physical states.

The interface prioritizes cognitive ease for older adults while providing dense, actionable telemetry for caregivers. Every visual state corresponds to verified physical hardware reality: scheduled doses are visually distinct from command transmission, mechanical dispensing is never conflated with ingestion, and simulated data is unmistakably distinguished from real BLE vitals.

**Key Characteristics:**
- **Clinical Calm:** Deep medical teal (`#0D9488`) anchors primary interactive workflows, instilling confidence without alarm fatigue.
- **Truthful State Encodings:** Distinct, non-overlapping semantic status colors for every phase of medication delivery.
- **Dignified Accessibility:** High legibility via Google Fonts `Outfit` and `Inter`, with enforced 48×48 dp touch minimums and high-contrast fallbacks.
- **Surface Restraint:** Flat surfaces with subtle 1 dp structural borders, reserving luminous glow effects exclusively for live hardware connectivity.

## Colors

The CAREMATE palette is anchored in clinical teal, balanced by neutral slate surfaces and a strict semantic safety scale.

### Primary
- **Medical Clinical Teal** (`#0D9488`): The signature brand anchor. Used for primary calls-to-action, active navigation indicators, and verified confirmation states.
- **Deep Marine Teal** (`#0F766E`): Darker companion for hover states, focused outlines, and high-contrast text on mint surfaces.
- **Vibrant Teal Accent** (`#14B8A6`): Lighter teal for dark-mode primary actions, toggles, and live connection telemetry.
- **Mint Surface Light** (`#CCFBF1`): Soft tint for badge backgrounds, active slot highlights, and positive confirmation banners.

### Neutral
- **Slate Canvas Light** (`#F8FAFC`): The clean, glare-free background for daytime clinical reading.
- **Pure White Surface** (`#FFFFFF`): Crisp elevated card surface ensuring contrast against the slate canvas.
- **Structural Border Light** (`#E2E8F0`): Subtle 1 dp hairline defining cards and dividers without heavy shadowing.
- **Deep Slate Body Text** (`#0F172A`): High-contrast primary typographic color (AAA contrast ratio).
- **Muted Slate Subtitle** (`#64748B`): Secondary text for units, timestamps, and secondary metadata.
- **Obsidian Dark Canvas** (`#0B1320`): Deep low-glare background for dark mode and nighttime bedroom use.
- **Navy Slate Card Dark** (`#152238`): Card surface for dark mode with 1 dp `#1E293B` separation border.

### Status Roles (Safety Spectrum)
- **Scheduled Dose Blue** (`#3B82F6`): Awaiting scheduled delivery time; calm and prospective.
- **Command Dispatched Violet** (`#8B5CF6`): BLE command transmitted to ESP32; motor in transit.
- **Dispense Confirmed Emerald** (`#10B981`): Optical IR sensor confirmed physical drop into dispensing tray.
- **Patient Acknowledged Forest** (`#059669`): Patient tapped physical button or phone screen confirming ingestion.
- **Safety Fault Crimson** (`#EF4444`): Motor jam, empty compartment, optical timeout, or emergency SOS alert.
- **Cautionary Amber** (`#F59E0B`): Simulated clinical data badge, upcoming reload reminder, or BLE signal warning.
- **Disconnected Gray** (`#6B7280`): Hardware offline, simulator stopped, or uncalibrated sensor.

### Named Rules
**The Truth In Color Rule.** No action or event may borrow a status color outside its verified stage. Never use Emerald (`#10B981`) for a scheduled or dispatched command until the IR drop sensor fires.
**The Amber Simulation Rule.** Any metric, vitals record, or telemetry packet generated via software simulation rather than physical BLE hardware must bear an Amber cautionary label (`#F59E0B`).

## Typography

**Display Font:** Outfit (fallback: system-ui, -apple-system, sans-serif)  
**Body Font:** Inter (fallback: system-ui, -apple-system, sans-serif)  
**Label/Mono Font:** Inter SemiBold / Outfit Bold

**Character:** Outfit delivers rounded, welcoming geometric clarity with sturdy capitals for titles, while Inter provides neutral, micro-legible clarity at small body sizes with open counters and tall x-height.

### Hierarchy
- **Display** (Bold 700, 32px, line-height 1.2): Screen hero titles and primary time readouts.
- **Headline** (Bold 700, 24px, line-height 1.25): Modal titles, vital sign readings, and major section banners.
- **Title** (SemiBold 600, 18px, line-height 1.3): Card headers, medication names, and drawer section labels.
- **Body** (Regular 400, 15px, line-height 1.5): Clinical instructions, dose descriptions, monograph text (max 65ch).
- **Label** (SemiBold 600, 12px, letter-spacing 0.02em): Status badges, sensor units, timestamps, and navigation bar tabs.

### Named Rules
**The Senior Legibility Rule.** Patient-facing labels and reminders must never render below 14px in body copy and 20px in time titles. Contrast must always meet or exceed WCAG AAA (7.0:1) on patient screens.
**The No-Mystery Metric Rule.** Every numerical reading (heart rate, blood pressure, angle) must explicitly declare its clinical unit (`mmHg`, `bpm`, `%`, `°`) in an adjacent 12px muted label.

## Layout

CAREMATE uses an 8dp spatial grid with a minimum touch floor of 48×48 dp for all interactive elements.

- **Screen Gutters:** 16dp horizontal margins on mobile devices; 24dp on tablets.
- **Card Spacing:** 12dp to 16dp vertical gutters between content cards.
- **Internal Card Padding:** 16dp uniform padding for primary information cards.
- **Responsive Architecture:**
  - Phone (<600dp): Single-column vertical scroll with bottom navigation bar.
  - Tablet / Foldable (≥600dp): Two-column master-detail layout or persistent Navigation Rail with central carousel canvas.
- **Density Stance:** Spacious comfortable density for Patient Companion screens (zero visual clutter); Compact-to-standard density for Caregiver telemetry and clinical monographs.

## Elevation & Depth

CAREMATE is flat-by-default, relying on tonal layering, 1dp structural borders, and purposeful contrast rather than heavy drop shadows.

Depth is conveyed through subtle tonal step-ups:
- Light Mode: Canvas `#F8FAFC` ➔ Card Surface `#FFFFFF` (1dp border `#E2E8F0`).
- Dark Mode: Canvas `#0B1320` ➔ Card Surface `#152238` (1dp border `#1E293B`) ➔ Elevated Modal `#1C2C48`.

### Shadow Vocabulary
- **Resting Flat** (`none`): Standard state for all dashboard cards, list tiles, and data containers.
- **Subtle Surface Lift** (`box-shadow: 0 4px 12px rgba(15, 23, 42, 0.05)`): Floated bottom sheets and emergency SOS modal dialogs.
- **Active Hardware Halo** (`box-shadow: 0 0 16px rgba(13, 148, 136, 0.25)`): Active dispensing slot and connected robot status badge.

### Named Rules
**The Flat-By-Default Rule.** Surfaces never cast structural drop shadows at rest. Depth is established through 1dp borders (`#E2E8F0` / `#1E293B`).
**The Emergency Elevation Rule.** Only the emergency SOS call sheet and hardware fault dialogs may break the flat surface hierarchy with an overlay barrier and elevated depth.

## Shapes

The form language is gently rounded, modern, and friendly without descending into novelty shapes.

- **Cards & Sheets:** 16dp rounded corners (`border-radius: 16px`).
- **Interactive Controls & Buttons:** 12dp rounded corners (`border-radius: 12px`) with enforced 48dp height minimum.
- **Status Pills & Chips:** Fully pill-shaped (`border-radius: 9999px` / 24dp).
- **Carousel Geometry:** 6-compartment radial ring (360° total, 60° increments: 0°, 60°, 120°, 180°, 240°, 300°). Slots are circular or rounded squares (minimum 50×50 dp touch boundary).

## Components

### Buttons
- **Shape:** 12dp rounded corners (`border-radius: 12px`), minimum height 48dp.
- **Primary:** Medical Teal background (`#0D9488`), white text (`#FFFFFF`), bold 600 Outfit, padding `14px 24px`.
- **Hover / Focus:** Deep Marine Teal (`#0F766E`), subtle 2px teal focus ring (`rgba(13, 148, 136, 0.35)`).
- **Secondary / Outlined:** Transparent background, 1.5dp border `#0D9488`, teal text (`#0D9488`), hover `#CCFBF1` (10% tint).
- **Danger / Emergency:** Crimson Red background (`#EF4444`), white text, 48dp minimum height.

### Chips & Status Badges
- **Style:** Pill shape, 24dp radius, horizontal padding 12dp, vertical padding 6dp.
- **Border:** 1dp border matching the status color with 35% opacity.
- **Typography:** 12px Outfit / Inter Bold, uppercase or capitalized status text with a paired 14px leading icon.

### Cards / Containers
- **Corner Style:** 16dp border radius.
- **Background:** Pure White (`#FFFFFF`) in light mode; Navy Slate (`#152238`) in dark mode.
- **Border:** 1dp structural border (`#E2E8F0` light / `#1E293B` dark).
- **Padding:** 16dp uniform internal padding.

### Inputs & Fields
- **Style:** 12dp rounded corners, 1.5dp border `#E2E8F0`, surface white, padding 14px 16px.
- **Focus:** 2dp border `#0D9488` with subtle 4px ambient teal glow.
- **Error:** 2dp border `#EF4444` with 12px error text beneath.

### Navigation
- **Mobile Bottom Bar:** 64dp height, surface white with 1dp top divider `#E2E8F0`, active icon pill with `#CCFBF1` background and `#0D9488` icon.
- **Tablet Navigation Rail:** 72dp width persistent left rail with vertical tab alignment.

### Signature Component: 6-Slot Radial Carousel Visualizer
- **Structure:** Central servo hub with 6 radial slots spaced at 60° intervals.
- **Active Slot:** Highlighted with `#0D9488` border, subtle cyan pulse, and explicit TalkBack semantic description.
- **Filled Slot:** Dot / pill indicator showing prescribed medication label and pill count.
- **Empty Slot:** Dashed border with muted slate icon and TalkBack accessibility label "Slot N: Empty".

## Do's and Don'ts

### Do:
- **Do** maintain a strict 48×48 dp minimum touch target for all buttons, toggles, and carousel slots.
- **Do** explicitly mark simulated vitals or test telemetries with the Amber "Simulated" badge.
- **Do** use Google Fonts Outfit for headings and Inter for body text to preserve typographic clarity.
- **Do** enforce 1dp hairline borders (`#E2E8F0` / `#1E293B`) for card surfaces rather than fuzzy drop shadows.
- **Do** preserve the strict medication state lifecycle (`SCHEDULED` ➔ `COMMAND_SENT` ➔ `DISPENSE_CONFIRMED` ➔ `ACKNOWLEDGED`).

### Don't:
- **Don't** use generic unbranded blue (`#0000FF`) or plain red (`#FF0000`); use curated tokens `#0D9488`, `#3B82F6`, `#EF4444`.
- **Don't** mark a medication as "Dispensed" simply because the BLE command was dispatched to the robot.
- **Don't** shrink body copy below 14px on senior patient screens.
- **Don't** add gratuitous 3D transforms, bouncy spring animations, or heavy blurs that increase cognitive friction.
- **Don't** invent BLE hardware verification when running in simulation mode.
