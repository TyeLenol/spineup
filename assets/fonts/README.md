# SpineUp bundled fonts

SpineUp uses **Fraunces** for expressive headings and **Outfit** for body and interface text. The `.ttf` files in this directory are the static weights used by the app and are bundled as Flutter assets so release builds do not depend on fetching fonts over the network.

Both font families are distributed under the SIL Open Font License 1.1. The corresponding license texts are preserved as `Fraunces-OFL.txt` and `Outfit-OFL.txt`, and `lib/main.dart` registers them with Flutter’s license registry.

The families were obtained from the official Google Fonts sources:

- [Fraunces on Google Fonts](https://fonts.google.com/specimen/Fraunces)
- [Outfit on Google Fonts](https://fonts.google.com/specimen/Outfit)
- [Google Fonts repository: Fraunces](https://github.com/google/fonts/tree/main/ofl/fraunces)
- [Google Fonts repository: Outfit](https://github.com/google/fonts/tree/main/ofl/outfit)

Do not rename the weight suffixes without also checking the `google_fonts` package’s asset matching convention. The application config disables runtime font fetching after these assets are loaded, keeping Android release typography deterministic and offline-safe.
