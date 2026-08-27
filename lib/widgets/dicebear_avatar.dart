import 'package:dicebear_core/dicebear_core.dart' show Avatar, Style;
import 'package:dicebear_styles/croodles.dart';
import 'package:dicebear_styles/lorelei_neutral.dart';
import 'package:dicebear_styles/open_peeps.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class AvatarChoice {
  final String id;
  final String label;

  const AvatarChoice({required this.id, required this.label});
}

class AvatarFeature {
  final String id;
  final String label;
  final String optionKey;
  final List<AvatarChoice> choices;
  final bool canBeNone;
  final bool isColor;

  const AvatarFeature({
    required this.id,
    required this.label,
    required this.optionKey,
    required this.choices,
    this.canBeNone = false,
    this.isColor = false,
  });
}

class AvatarStyleDefinition {
  final String id;
  final String name;
  final String description;
  final String credit;
  final Style style;
  final List<AvatarFeature> features;
  final Map<String, String> defaults;
  final Map<String, List<String>> fixedOptions;

  const AvatarStyleDefinition({
    required this.id,
    required this.name,
    required this.description,
    required this.credit,
    required this.style,
    required this.features,
    required this.defaults,
    this.fixedOptions = const <String, List<String>>{},
  });

  Map<String, Object?> buildOptions({
    required String seed,
    required Map<String, String> selections,
    double? size,
  }) {
    final options = <String, Object?>{'seed': seed};
    if (size != null) options['size'] = size.toInt();
    options.addAll(fixedOptions);

    for (final feature in features) {
      final value = selections[feature.id] ?? defaults[feature.id];
      if (value == null || value == 'none') {
        options['${feature.optionKey}Probability'] = 0;
      } else if (feature.isColor) {
        options[feature.optionKey] = [value];
        options.remove('${feature.optionKey}Probability');
      } else {
        options['${feature.optionKey}Variant'] = value;
        // Force probability to 100 so the chosen component always renders.
        // Style definitions set accessories/glasses at 10–20% by default;
        // leaving that in place means the avatar ignores the user's pick most
        // of the time.
        options['${feature.optionKey}Probability'] = 100;
      }
    }
    return options;
  }
}

final List<AvatarStyleDefinition> avatarStyleDefinitions = [
  AvatarStyleDefinition(
    id: 'open_peeps',
    name: 'Open Peeps',
    description: 'Sketchy, expressive portraits with a hand-drawn feel.',
    credit: 'Open Peeps by Pablo Stanley · CC0 1.0',
    style: Style.parse(openPeeps),
    features: const [
      AvatarFeature(
        id: 'head',
        label: 'Hair / head',
        optionKey: 'head',
        choices: [
          AvatarChoice(id: 'afro', label: 'Afro'),
          AvatarChoice(id: 'medium1', label: 'Medium'),
          AvatarChoice(id: 'longCurly', label: 'Curly'),
          AvatarChoice(id: 'short3', label: 'Short'),
          AvatarChoice(id: 'twists', label: 'Twists'),
        ],
      ),
      AvatarFeature(
        id: 'expression',
        label: 'Expression',
        optionKey: 'expression',
        choices: [
          AvatarChoice(id: 'calm', label: 'Calm'),
          AvatarChoice(id: 'smile', label: 'Smile'),
          AvatarChoice(id: 'serious', label: 'Steady'),
          AvatarChoice(id: 'lovingGrin1', label: 'Bright'),
          AvatarChoice(id: 'eyesClosed', label: 'Resting'),
        ],
      ),
      AvatarFeature(
        id: 'accessories',
        label: 'Accessory',
        optionKey: 'accessories',
        canBeNone: true,
        choices: [
          AvatarChoice(id: 'glasses', label: 'Glasses'),
          AvatarChoice(id: 'glasses2', label: 'Round'),
          AvatarChoice(id: 'glasses4', label: 'Bold'),
          AvatarChoice(id: 'sunglasses', label: 'Sun'),
        ],
      ),
      AvatarFeature(
        id: 'clothing',
        label: 'Colour',
        optionKey: 'clothingColor',
        choices: [
          AvatarChoice(id: 'ffb5a7', label: 'Coral'),
          AvatarChoice(id: 'b8d8ba', label: 'Sage'),
          AvatarChoice(id: 'cdb4db', label: 'Lavender'),
          AvatarChoice(id: 'f6bd60', label: 'Golden'),
          AvatarChoice(id: 'a9def9', label: 'Sky'),
        ],
        isColor: true,
      ),
    ],
    defaults: {
      'head': 'medium1',
      'expression': 'calm',
      'accessories': 'none',
      'clothing': 'b8d8ba',
    },
    fixedOptions: {
      'skinColor': ['f2d3b1', 'ae5d29', '614335'],
      'inkColor': ['2d2a26'],
      'headContrastColor': ['f7ede2'],
    },
  ),
  AvatarStyleDefinition(
    id: 'croodles',
    name: 'Croodles',
    description: 'Loose ink doodles with a playful, imperfect line.',
    credit: 'Croodles by Vijay Verma · CC BY 4.0',
    style: Style.parse(croodles),
    features: const [
      AvatarFeature(
        id: 'top',
        label: 'Hair / head',
        optionKey: 'top',
        choices: [
          AvatarChoice(id: 'variant01', label: 'Simple'),
          AvatarChoice(id: 'variant05', label: 'Curly'),
          AvatarChoice(id: 'variant10', label: 'Short'),
          AvatarChoice(id: 'variant18', label: 'Soft'),
          AvatarChoice(id: 'variant25', label: 'Playful'),
        ],
      ),
      AvatarFeature(
        id: 'eyes',
        label: 'Eyes',
        optionKey: 'eyes',
        choices: [
          AvatarChoice(id: 'variant01', label: 'Open'),
          AvatarChoice(id: 'variant04', label: 'Bright'),
          AvatarChoice(id: 'variant08', label: 'Kind'),
          AvatarChoice(id: 'variant12', label: 'Steady'),
          AvatarChoice(id: 'variant16', label: 'Round'),
        ],
      ),
      AvatarFeature(
        id: 'mouth',
        label: 'Expression',
        optionKey: 'mouth',
        choices: [
          AvatarChoice(id: 'variant01', label: 'Calm'),
          AvatarChoice(id: 'variant05', label: 'Smile'),
          AvatarChoice(id: 'variant09', label: 'Bright'),
          AvatarChoice(id: 'variant13', label: 'Soft'),
          AvatarChoice(id: 'variant17', label: 'Cheerful'),
        ],
      ),
      AvatarFeature(
        id: 'topColor',
        label: 'Colour',
        optionKey: 'topColor',
        choices: [
          AvatarChoice(id: 'f6bd60', label: 'Golden'),
          AvatarChoice(id: 'b8d8ba', label: 'Sage'),
          AvatarChoice(id: 'ffb5a7', label: 'Coral'),
          AvatarChoice(id: 'cdb4db', label: 'Lavender'),
          AvatarChoice(id: 'a9def9', label: 'Sky'),
        ],
        isColor: true,
      ),
    ],
    defaults: {
      'top': 'variant01',
      'eyes': 'variant01',
      'mouth': 'variant01',
      'topColor': 'f6bd60',
    },
    fixedOptions: {
      'baseColor': ['f2d3b1', 'ae5d29', '614335'],
      'inkColor': ['2d2a26'],
    },
  ),
  AvatarStyleDefinition(
    id: 'lorelei_neutral',
    name: 'Line Face',
    description: 'A calm, minimal line-drawn face for a quieter profile.',
    credit: 'Lorelei Neutral by Lisa Wischofsky · CC0 1.0',
    style: Style.parse(loreleiNeutral),
    features: const [
      AvatarFeature(
        id: 'eyebrows',
        label: 'Brows',
        optionKey: 'eyebrows',
        choices: [
          AvatarChoice(id: 'variant01', label: 'Soft'),
          AvatarChoice(id: 'variant04', label: 'Open'),
          AvatarChoice(id: 'variant07', label: 'Steady'),
          AvatarChoice(id: 'variant10', label: 'Gentle'),
          AvatarChoice(id: 'variant13', label: 'Bold'),
        ],
      ),
      AvatarFeature(
        id: 'eyes',
        label: 'Eyes',
        optionKey: 'eyes',
        choices: [
          AvatarChoice(id: 'variant01', label: 'Open'),
          AvatarChoice(id: 'variant06', label: 'Warm'),
          AvatarChoice(id: 'variant12', label: 'Steady'),
          AvatarChoice(id: 'variant18', label: 'Bright'),
          AvatarChoice(id: 'variant24', label: 'Resting'),
        ],
      ),
      AvatarFeature(
        id: 'mouth',
        label: 'Expression',
        optionKey: 'mouth',
        choices: [
          AvatarChoice(id: 'happy01', label: 'Soft smile'),
          AvatarChoice(id: 'happy05', label: 'Smile'),
          AvatarChoice(id: 'happy09', label: 'Bright'),
          AvatarChoice(id: 'happy13', label: 'Calm'),
          AvatarChoice(id: 'sad01', label: 'Neutral'),
        ],
      ),
      AvatarFeature(
        id: 'glasses',
        label: 'Glasses',
        optionKey: 'glasses',
        canBeNone: true,
        choices: [
          AvatarChoice(id: 'variant01', label: 'Round'),
          AvatarChoice(id: 'variant02', label: 'Square'),
          AvatarChoice(id: 'variant03', label: 'Light'),
          AvatarChoice(id: 'variant05', label: 'Bold'),
        ],
      ),
    ],
    defaults: {
      'eyebrows': 'variant01',
      'eyes': 'variant01',
      'mouth': 'happy01',
      'glasses': 'none',
    },
    fixedOptions: {
      'backgroundColor': ['fff4e8'],
      'eyesColor': ['2d2a26'],
      'mouthColor': ['2d2a26'],
      'noseColor': ['2d2a26'],
    },
  ),
];

AvatarStyleDefinition? avatarStyleDefinitionFor(String id) {
  for (final definition in avatarStyleDefinitions) {
    if (definition.id == id) return definition;
  }
  return null;
}

class DiceBearAvatar extends StatelessWidget {
  final String styleId;
  final String seed;
  final Map<String, String> selections;
  final double size;
  final Widget? fallback;

  const DiceBearAvatar({
    super.key,
    required this.styleId,
    required this.seed,
    this.selections = const <String, String>{},
    this.size = 64,
    this.fallback,
  });

  @override
  Widget build(BuildContext context) {
    final definition = avatarStyleDefinitionFor(styleId);
    if (definition == null) return fallback ?? _defaultFallback();

    try {
      final avatar = Avatar(
        definition.style,
        definition.buildOptions(seed: seed, selections: selections, size: size),
      );
      return SvgPicture.string(
        avatar.svg,
        width: size,
        height: size,
        fit: BoxFit.contain,
        placeholderBuilder: (_) => fallback ?? _defaultFallback(),
      );
    } catch (_) {
      return fallback ?? _defaultFallback();
    }
  }

  Widget _defaultFallback() {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        color: Color(0xFFFFF1E5),
        shape: BoxShape.circle,
      ),
      child: Icon(
        Icons.face_rounded,
        size: size * 0.52,
        color: const Color(0xFFD97855),
      ),
    );
  }
}
