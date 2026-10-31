import '../../affection/domain/affection_type.dart';

enum BearTouch { hold, returnAffection, repeat, catchHeart, wake, walk, reveal }

enum BearAnimationEvent {
  started,
  approachComplete,
  contactStarted,
  reactionStarted,
  interactiveHoldStarted,
  interactiveHoldEnded,
  completed,
  cancelled,
}

/// Local playback metadata. Catalog IDs and Firestore payloads stay unchanged.
class BearGestureDefinition {
  const BearGestureDefinition(
    this.touch, {
    this.contactAt = .46,
    this.reactionAt = .52,
    this.inputAt = .68,
    this.repeatFrom,
  });

  final BearTouch touch;
  final double contactAt, reactionAt, inputAt;
  final double? repeatFrom;
  bool get supportsHold => touch == BearTouch.hold;

  static BearGestureDefinition of(AffectionType action) => switch (action) {
    AffectionType.warmHug ||
    AffectionType.comfortHug ||
    AffectionType.cuddleTime => const BearGestureDefinition(BearTouch.hold),
    AffectionType.cheekKiss ||
    AffectionType.foreheadKiss => const BearGestureDefinition(
      BearTouch.returnAffection,
      inputAt: .76,
      repeatFrom: .18,
    ),
    AffectionType.goodnightKiss => const BearGestureDefinition(
      BearTouch.repeat,
      inputAt: .78,
    ),
    AffectionType.holdingHands => const BearGestureDefinition(
      BearTouch.walk,
      inputAt: .46,
    ),
    AffectionType.piggybackRide => const BearGestureDefinition(
      BearTouch.walk,
      contactAt: .50,
      reactionAt: .56,
      inputAt: .56,
    ),
    AffectionType.blowingKisses => const BearGestureDefinition(
      BearTouch.catchHeart,
      contactAt: .66,
      reactionAt: .69,
      inputAt: .38,
    ),
    AffectionType.goodMorning => const BearGestureDefinition(
      BearTouch.wake,
      contactAt: .50,
      reactionAt: .58,
      inputAt: .30,
    ),
    AffectionType.headPat ||
    AffectionType.noseBoop ||
    AffectionType.happyDance ||
    AffectionType.playfulTickle ||
    AffectionType.spinningHug => const BearGestureDefinition(
      BearTouch.repeat,
      repeatFrom: .18,
    ),
    AffectionType.highFive => const BearGestureDefinition(
      BearTouch.repeat,
      inputAt: .24,
      repeatFrom: .18,
    ),
    AffectionType.sleepTogether => const BearGestureDefinition(
      BearTouch.wake,
      contactAt: .50,
      reactionAt: .56,
      inputAt: .50,
    ),
    AffectionType.wipeAwayTears => const BearGestureDefinition(
      BearTouch.repeat,
      inputAt: .30,
    ),
    AffectionType.iMissYou => const BearGestureDefinition(
      BearTouch.reveal,
      contactAt: .63,
      reactionAt: .66,
      inputAt: 0,
    ),
    AffectionType.underOneUmbrella => const BearGestureDefinition(
      BearTouch.repeat,
      contactAt: .50,
      reactionAt: .58,
      inputAt: .50,
    ),
    AffectionType.flowerSurprise ||
    AffectionType.heartDelivery => const BearGestureDefinition(
      BearTouch.reveal,
      contactAt: .53,
      reactionAt: .60,
      inputAt: .45,
    ),
    AffectionType.shyConfession => const BearGestureDefinition(
      BearTouch.reveal,
      contactAt: .63,
      reactionAt: .68,
      inputAt: .63,
    ),
    AffectionType.surpriseBox => const BearGestureDefinition(
      BearTouch.reveal,
      contactAt: .68,
      reactionAt: .70,
      inputAt: .43,
    ),
  };
}
