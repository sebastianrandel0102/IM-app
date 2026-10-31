part of 'bear_choreography.dart';

enum BearInteractionPose {
  standingNeutral,
  standingHappy,
  standingShy,
  standingSad,
  armsOpen,
  reachingForward,
  frontHug,
  sideHug,
  hugHold,
  hugRelease,
  sittingNeutral,
  sittingClose,
  shoulderCuddle,
  sideCuddle,
  sleepingSitting,
  lyingDown,
  sleepingTogether,
  cheekKiss,
  foreheadKiss,
  holdingHands,
  headPat,
  carryingObject,
  piggybackSupport,
  surprised,
}

/// Local pose corrections shared by both existing character designs.
/// Interaction endpoints still need the shared scene-space contact solve.
abstract final class BearPoseLibrary {
  static BearPose create(BearInteractionPose pose) {
    final result = BearPose();
    apply(result, pose);
    return result;
  }

  static void apply(BearPose p, BearInteractionPose pose) {
    switch (pose) {
      case BearInteractionPose.standingNeutral:
        break;
      case BearInteractionPose.standingHappy:
        p.happyEyes = .6;
        p.blush = .3;
      case BearInteractionPose.standingShy:
        p.head = .06;
        p.gaze = -2;
        p.blush = .65;
      case BearInteractionPose.standingSad:
        p.smile = -1;
        p.headY = 7;
        p.ear = -.035;
      case BearInteractionPose.armsOpen:
        p.nearPaw = const Offset(49, -58);
        p.farPaw = const Offset(-49, -56);
      case BearInteractionPose.reachingForward:
        p.nearPaw = const Offset(57, -65);
      case BearInteractionPose.frontHug:
      case BearInteractionPose.sideHug:
      case BearInteractionPose.hugHold:
        p.embrace = 1;
        p.headX = -30;
        p.nearPaw = const Offset(49, -48);
        p.farPaw = const Offset(32, -67);
        p.eyes = pose == BearInteractionPose.hugHold ? 0 : .7;
      case BearInteractionPose.hugRelease:
        p.nearPaw = const Offset(37, -45);
        p.farPaw = const Offset(-38, -45);
      case BearInteractionPose.sittingNeutral:
      case BearInteractionPose.sittingClose:
      case BearInteractionPose.shoulderCuddle:
      case BearInteractionPose.sideCuddle:
      case BearInteractionPose.sleepingSitting:
        p.sit = 1;
        if (pose == BearInteractionPose.shoulderCuddle ||
            pose == BearInteractionPose.sideCuddle) {
          p.head = .10;
          p.headX = -30;
        }
        if (pose == BearInteractionPose.sleepingSitting) p.eyes = 0;
      case BearInteractionPose.lyingDown:
      case BearInteractionPose.sleepingTogether:
        p.recline = 1;
        p.headY = 27;
        p.nearPaw = const Offset(37, -27);
        p.farPaw = const Offset(-25, -28);
        if (pose == BearInteractionPose.sleepingTogether) p.happyEyes = .12;
      case BearInteractionPose.cheekKiss:
      case BearInteractionPose.foreheadKiss:
        p.turn = 1;
        p.pucker = 1;
        p.eyes = 0;
      case BearInteractionPose.holdingHands:
        p.nearPaw = const Offset(58, -54);
      case BearInteractionPose.headPat:
        p.nearPaw = const Offset(38, -102);
      case BearInteractionPose.carryingObject:
        p.nearPaw = const Offset(35, -53);
        p.farPaw = const Offset(-13, -51);
      case BearInteractionPose.piggybackSupport:
        p.sit = .3;
        p.farPaw = const Offset(-38, -64);
      case BearInteractionPose.surprised:
        p.surprise = 1;
        p.mouthOpen = .6;
    }
  }
}
