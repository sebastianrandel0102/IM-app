import 'dart:ui';

import '../../../app/theme/app_theme.dart';
import '../../affection/domain/affection_type.dart';

/// Shared vector contours used by the live rig and the editable SVG masters.
/// Coordinates retain the existing app artwork; these are not reference traces.
class BearContour {
  const BearContour(this.commands);
  final List<(String, List<double>)> commands;

  Path get path {
    final result = Path();
    for (final (op, v) in commands) {
      switch (op) {
        case 'M':
          result.moveTo(v[0], v[1]);
        case 'L':
          result.lineTo(v[0], v[1]);
        case 'Q':
          result.quadraticBezierTo(v[0], v[1], v[2], v[3]);
        case 'C':
          result.cubicTo(v[0], v[1], v[2], v[3], v[4], v[5]);
        case 'Z':
          result.close();
      }
    }
    return result;
  }

  String get svg => commands.map((c) => '${c.$1}${c.$2.join(' ')}').join(' ');
}

abstract final class BearArtwork {
  static BearContour head([double profile = 0]) => BearContour([
    ('M', [-54, -28]),
    ('C', [-41, -65, 37, -67, 56 - profile * 9, -27]),
    ('C', [73 - profile * 20, 0, 67 - profile * 12, 43, 39, 51]),
    ('Q', [0, 66, -37, 49]),
    ('C', [-66, 45, -68, 1, -54, -28]),
    ('Z', []),
  ]);

  static BearContour torso({
    double sit = 0,
    double breath = 0,
    double recline = 0,
    double embrace = 0,
  }) => BearContour([
    ('M', [-22, -91 + recline * 22]),
    (
      'Q',
      [-37 - recline * 33, -64 - breath, -29 - recline * 35, -26 + recline * 9],
    ),
    ('Q', [-recline * 20, -13 + sit * 5, 30 + embrace * 8, -27 - recline * 4]),
    ('Q', [37 + embrace * 6, -64 - breath, 19, -92 + recline * 21]),
    ('Z', []),
  ]);

  static BearContour mouth(double x, double smile) => BearContour([
    ('M', [x - 7, 34 - smile * 2]),
    ('Q', [x - 4, 34 + smile * 5, x, 32]),
    ('Q', [x + 4, 34 + smile * 5, x + 8, 34 - smile * 2]),
  ]);

  static String _hex(Color color) =>
      '#${color.toARGB32().toRadixString(16).substring(2).toUpperCase()}';

  /// Authoring handoff, generated from runtime contours, with transparent canvas
  /// and independently selectable groups. Not loaded as duplicate runtime art.
  static String masterSvg(BearCharacter bear) {
    final fur = bear == BearCharacter.brown ? _hex(Palette.caramel) : '#FFFDFC';
    final inner = bear == BearCharacter.brown ? '#ECC28B' : '#F4B5C4';
    final ink = _hex(Palette.outline);
    return '''<svg xmlns="http://www.w3.org/2000/svg" xmlns:inkscape="http://www.inkscape.org/namespaces/inkscape" width="1024" height="1024" viewBox="0 0 1024 1024">
<title>Bear With Me — ${bear.name} bear editable master</title>
<desc>Generated from the existing Flutter vector rig. Original reference images were unavailable. Rigid parts, no mesh weights. All coordinates before the root transform match the live rig.</desc>
<g id="BearRoot" transform="translate(512 860) scale(4.2)" stroke="$ink" stroke-width="2.6" stroke-linecap="round" stroke-linejoin="round" fill="$fur">
  <ellipse id="GroundShadow" cx="0" cy="3" rx="36" ry="4" fill="$ink" fill-opacity="0.12" stroke="none"/>
  <g id="HipControl">
    <g id="LeftLeg"><ellipse cx="-15.5" cy="-16" rx="11.5" ry="15"/></g>
    <g id="RightLeg"><ellipse cx="16.5" cy="-16" rx="11.5" ry="15"/></g>
    <g id="LeftFoot"><path d="M-27 -14 Q-28 -1 -15.5 -1 Q-3 -1 -4 -14" stroke-width="2.6"/></g>
    <g id="RightFoot"><path d="M5 -14 Q4 -1 16.5 -1 Q29 -1 28 -14" stroke-width="2.6"/></g>
    <path id="Torso" d="${torso().svg}"/>
    <g id="RightArm" fill="none" stroke-width="18">
      <path id="RightUpperArmOutline" d="M-23 -80 Q-31 -71 -32.3 -60.9"/>
      <path id="RightLowerArmOutline" d="M-32.3 -60.9 Q-33.5 -50.9 -28 -40"/>
      <g stroke="$fur" stroke-width="13.4">
        <path id="RightUpperArm" d="M-23 -80 Q-31 -71 -32.3 -60.9"/>
        <path id="RightLowerArm" d="M-32.3 -60.9 Q-33.5 -50.9 -28 -40"/>
      </g>
      <circle id="RightPaw" cx="-28" cy="-40" r="6.7" fill="$fur" stroke="none"/>
    </g>
    <g id="LeftArm" fill="none" stroke-width="18">
      <path id="LeftUpperArmOutline" d="M23 -80 Q30.7 -70.4 31.7 -60.7"/>
      <path id="LeftLowerArmOutline" d="M31.7 -60.7 Q32.7 -49.9 27 -39"/>
      <g stroke="$fur" stroke-width="13.4">
        <path id="LeftUpperArm" d="M23 -80 Q30.7 -70.4 31.7 -60.7"/>
        <path id="LeftLowerArm" d="M31.7 -60.7 Q32.7 -49.9 27 -39"/>
      </g>
      <circle id="LeftPaw" cx="27" cy="-39" r="6.7" fill="$fur" stroke="none"/>
    </g>
    <g id="HeadControl" transform="translate(0 -113)">
      <g id="LeftEar" transform="translate(-36.5 -38)"><ellipse cy="0" rx="21.5" ry="24"/><ellipse rx="11.5" ry="14" fill="$inner" stroke="none"/></g>
      <g id="RightEar" transform="translate(42.5 -38)"><ellipse rx="21.5" ry="24"/><ellipse rx="11.5" ry="14" fill="$inner" stroke="none"/></g>
      <path id="Head" d="${head().svg}" stroke-width="3.1"/>
      <g fill="${_hex(Palette.pink)}" fill-opacity="${bear == BearCharacter.white ? .545 : .075}" stroke="none">
        <ellipse id="LeftCheek" cx="-22" cy="28" rx="10.5" ry="9"/>
        <ellipse id="RightCheek" cx="40" cy="28" rx="10.5" ry="9"/>
      </g>
      <g id="EyesNeutral" fill="$ink" stroke="none"><ellipse id="LeftEye" cx="-10" cy="16" rx="3" ry="4.5"/><ellipse id="RightEye" cx="28" cy="16" rx="3" ry="4.5"/></g>
      <g id="EyesClosed" display="none" fill="none" stroke-width="2.4"><path d="M-14 14 Q-10 18 -6 14"/><path d="M24 14 Q28 18 32 14"/></g>
      <g id="EyesHappy" display="none" fill="none" stroke-width="2.4"><path d="M-14 17 Q-10 11 -6 17"/><path d="M24 17 Q28 11 32 17"/></g>
      <g id="EyesSleepy" display="none" fill="$ink" stroke="none"><ellipse cx="-10" cy="16" rx="3" ry="1.8"/><ellipse cx="28" cy="16" rx="3" ry="1.8"/></g>
      <g id="EyesSurprised" display="none" fill="$ink" stroke="none"><ellipse cx="-10" cy="16" rx="3" ry="5.5"/><ellipse cx="28" cy="16" rx="3" ry="5.5"/></g>
      ${bear == BearCharacter.brown ? '<ellipse id="Muzzle" cx="9" cy="28" rx="10.5" ry="13.5" fill="#F2D49C" stroke="none"/>' : ''}
      <path id="Nose" d="M5 23 Q9 21 13 23 L9 27 Z" fill="$ink" stroke="none"/>
      <path d="M9 26 L9 31" fill="none" stroke-width="2"/>
      <path id="Mouth" d="${mouth(9, 1).svg}" fill="none" stroke-width="1.9"/>
      <path id="MouthSad" d="${mouth(9, -1).svg}" fill="none" stroke-width="1.9" display="none"/>
      <ellipse id="MouthSurprised" cx="9" cy="35" rx="3.2" ry="4.5" display="none" fill="$ink" stroke="none"/>
      <path id="MouthKiss" d="M7 31 Q16 32 10 35 Q16 38 7 39" fill="none" stroke-width="1.9" display="none"/>
    </g>
  </g>
</g>
</svg>''';
  }
}
