# SIL logo pack

Mark: concept 1d, "Three strokes". S, I and L as rising bars; the last bar turns into an L.
Colours: black #0A0A0C, white #FFFFFF. Type in lockups: Schibsted Grotesk 600 + Martian Mono 400.

## Folders
- mark/        Symbol only. SVG + PNG at 512 / 1024 / 2048 in four versions:
               white-transparent, black-transparent, white-on-black, black-on-white
- lockup/      Symbol + SIL wordmark, with and without the tagline. Same four versions.
               SVGs have the fonts embedded, so they render anywhere.
- app-store/ios/      AppIcon-1024 (primary), Light, Dark, Tinted, plus every legacy size in sizes/
- app-store/ios/liquid-glass/   Layers for Icon Composer (iOS 26 Liquid Glass)
- app-store/android/  Play Store icon 512, adaptive icon layers 432, feature graphic 1024x500
- web/         favicon.ico / .svg / 16 / 32 / 48, apple-touch-icon, PWA 192 / 512 / maskable, OG image 1200x630
- social/      Profile images 1080 + 400, X header, LinkedIn banner, YouTube banner, Facebook cover (dark + light)

## iOS 18 (Xcode asset catalog)
AppIcon set, single size 1024:
- Any Appearance -> app-store/ios/AppIcon-1024.png
- Dark           -> app-store/ios/AppIcon-Dark-1024.png   (transparent; iOS adds the dark backdrop)
- Tinted         -> app-store/ios/AppIcon-Tinted-1024.png (grayscale; iOS applies the user's tint)
Don't round the corners or add transparency to the Any icon; the App Store and iOS apply the mask.

## iOS 26 Liquid Glass (Icon Composer)
1. New icon in Icon Composer. Set the background fill to #0A0A0C (or drop in liquid-glass/0-background.svg).
2. Add liquid-glass/1-mark.svg as one layer, or the three files in liquid-glass/strokes/ as three layers in one group.
   Three layers give each stroke its own depth and specular edge.
3. Leave Liquid Glass on. Composer generates Default, Dark, Clear and Tinted from these layers.
   The mark is pure white, which is what the tinted and clear modes need.
4. Export the .icon file into the Xcode project and set it as the app icon.

## Android (adaptive icon)
res/mipmap-anydpi-v26/ic_launcher.xml
  <adaptive-icon>
    <background android:drawable="@drawable/ic_launcher_background"/>   <!-- adaptive-background-432.png -->
    <foreground android:drawable="@drawable/ic_launcher_foreground"/>   <!-- adaptive-foreground-432.png -->
    <monochrome android:drawable="@drawable/ic_launcher_monochrome"/>   <!-- adaptive-monochrome-432.png, themed icons -->
  </adaptive-icon>
The mark sits inside the 66dp safe zone.

## Web <head>
  <link rel="icon" href="/favicon.ico" sizes="48x48">
  <link rel="icon" href="/favicon.svg" type="image/svg+xml">
  <link rel="apple-touch-icon" href="/apple-touch-icon-180.png">
  <link rel="manifest" href="/site.webmanifest">   <!-- icon-192, icon-512, icon-maskable-512 (purpose: maskable) -->
  <meta property="og:image" content="/og-image-1200x630-dark.png">

## Usage
- Clear space: at least the width of one stroke on every side of the mark.
- Minimum size: 16 px for the mark (favicons use a heavier stroke), 80 px wide for the lockup.
- Keep the strokes square-ended. Don't round, outline, rotate or recolour individual strokes.
