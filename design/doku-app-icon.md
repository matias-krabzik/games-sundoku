# Doku app icon

Chosen design: third square concept, Doku winking and hugging a golden sudoku with 3, 6 and 9, against a teal-blue background. Generated/extracted with the built-in image tool. The opaque background was explicitly requested for this icon.

Master: `assets/images/sundoku-app-icon.png`, opaque RGB, 1024×1024, no baked-in rounded corners. iOS receives opaque square icons; macOS, Windows and legacy Android receive rounded derivatives. Web maskable icons preserve the illustration within the safe area. In-app logos and native launch screens retain the separate hollow-O wordmark, `assets/images/sundoku-logo.png`. This icon changes only the operating-system and browser identity.

Regenerate platform sizes with `python3 tool/generate_brand_assets.py` (Pillow). Linux reads the master from its installed Flutter asset bundle.

## macOS Dock

When the compiled `AppIcon.icns` is correct but `NSRunningApplication.icon` still returns Flutter, refresh only this application's Launch Services registration:

```sh
touch build/macos/Build/Products/Debug/sundoku.app
/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -f "$PWD/build/macos/Build/Products/Debug/sundoku.app"
```

Verified on the running macOS app: the same process returned Flutter before the registration refresh and Doku afterwards. No global icon cache deletion or Dock restart was needed. The native application delegate also loads the bundled icon at launch, but that alone did not refresh the system registration.

Apple documents forced registration updates in [LSRegisterURL](https://developer.apple.com/documentation/coreservices/1446350-lsregisterurl).

## Extraction prompt

Extract and faithfully reproduce ONLY THE RIGHTMOST (third) app icon from the reference comparison sheet as one production-ready square 1024x1024 icon. Preserve exactly the selected character, pose, winking right eye, open brown left eye, smile, golden sun rays, navy hoodie, both hands embracing the tilted golden 3x3 sudoku board with navy digits 3,6,9, teal blue atmospheric background with cream cloud. Do not redesign or change expression or add details. No other two icons and no presentation sheet.
IMPORTANT full bleed square: extend the existing blue background seamlessly into all FOUR CORNERS, removing the ivory outer presentation backdrop, rounded presentation boundary and drop shadow. Output an opaque square image, no pre-rounded corners, no border or padding. The operating systems apply their own icon masks. Keep the complete face and board well within safe margins, with enough blue space around Doku; do not cut off the bottom 9. Preserve EXACTLY 3 rows and 3 columns (nine tiles) and the existing digits 3,6,9 only, no words, captions, labels, brand lettering or watermarks. Same polished soft sculpted 3D illustrated material, visual identity and warm lighting. This is the single chosen reusable app icon artwork, never a complete screen or modal. User explicitly requested WITH background for this icon: use an opaque painted blue background, overriding prior transparency requirements for UI art.
