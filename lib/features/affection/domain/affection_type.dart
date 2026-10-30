enum AffectionType {
  warmHug(
    'Warm hug',
    'As long as you need.',
    'Hold to hug a little longer',
    'Everyday',
    'hug',
  ),
  cheekKiss(
    'Cheek kiss',
    'A little kiss, just for you.',
    'Tap the heart to kiss back',
    'Everyday',
    'kiss',
  ),
  foreheadKiss(
    'Forehead kiss',
    'You’re safe with me.',
    'Tap for one more kiss',
    'Everyday',
    'kiss',
  ),
  holdingHands(
    'Hold hands',
    'Wherever we go, together.',
    'Swipe to take a little walk',
    'Everyday',
    'hands',
  ),
  headPat(
    'Head pats',
    'You’re doing so well.',
    'Tap for another head pat',
    'Playful',
    'pat',
  ),
  noseBoop(
    'Nose boop',
    'Boop. You’re my favorite.',
    'Tap to boop; three taps boop back',
    'Playful',
    'boop',
  ),
  cuddleTime(
    'Cuddle time',
    'My favorite place is beside you.',
    'Tap to tuck in the blanket',
    'Cozy',
    'cuddle',
  ),
  goodnightKiss(
    'Goodnight kiss',
    'Meet me in our dreams.',
    'Tap the lamp to dim the room',
    'Cozy',
    'sleep',
  ),
  sleepTogether(
    'Sleep together',
    'Stay a little longer.',
    'Tap to move closer; swipe to wake up',
    'Cozy',
    'sleep',
  ),
  blowingKisses(
    'Blowing kisses',
    'Catch a little love.',
    'Tap the floating heart to catch it',
    'Everyday',
    'kiss',
  ),
  flowerSurprise(
    'A little flower',
    'Something beautiful for you.',
    'Tap to make the flower bloom',
    'Surprises',
    'flower',
  ),
  comfortHug(
    'Comfort hug',
    'You don’t have to carry it alone.',
    'Hold to stay; tap to hug again',
    'Comfort',
    'hug',
  ),
  wipeAwayTears(
    'Dry your tears',
    'I’m right here.',
    'Tap the little tear to wipe it away',
    'Comfort',
    'tear',
  ),
  happyDance(
    'Happy dance',
    'You make my heart dance.',
    'Tap to change our dance steps',
    'Playful',
    'dance',
  ),
  piggybackRide(
    'Piggyback ride',
    'I’ve got you.',
    'Swipe to go on a little adventure',
    'Playful',
    'ride',
  ),
  playfulTickle(
    'Tiny tickles',
    'Your laugh is my favorite.',
    'Tap to tickle; Stop is always here',
    'Playful',
    'tickle',
  ),
  iMissYou(
    'I miss you',
    'Even under different skies.',
    'Tap the moon to read your note',
    'Comfort',
    'moon',
  ),
  heartDelivery(
    'Heart delivery',
    'Handle with love.',
    'Tap the heart to read your note',
    'Surprises',
    'heart',
  ),
  goodMorning(
    'Good morning',
    'My favorite hello.',
    'Tap the sun to brighten the room',
    'Everyday',
    'sun',
  ),
  surpriseBox(
    'A tiny surprise',
    'A little something, just because.',
    'Tap to unwrap your surprise',
    'Surprises',
    'gift',
  ),
  highFive(
    'High five',
    'Look at you go!',
    'Tap when our paws meet',
    'Playful',
    'hands',
  ),
  spinningHug(
    'Spinning hug',
    'You make my world go round.',
    'Tap for another gentle spin',
    'Playful',
    'hug',
  ),
  shyConfession(
    'A shy confession',
    'It’s always been you.',
    'Tap the heart to read your note',
    'Surprises',
    'heart',
  ),
  underOneUmbrella(
    'One umbrella',
    'A little closer, rain or shine.',
    'Tap the umbrella to move closer',
    'Comfort',
    'rain',
  );

  const AffectionType(
    this.title,
    this.message,
    this.gesture,
    this.category,
    this.scene,
  );
  final String title, message, gesture, category, scene;
  static AffectionType parse(String value) => values.firstWhere(
    (v) => v.name == value,
    orElse: () =>
        throw const FormatException('This moment needs a newer app version.'),
  );
}

enum BearCharacter {
  brown,
  white;

  BearCharacter get other => this == brown ? white : brown;
  static BearCharacter parse(Object? value) => values.firstWhere(
    (e) => e.name == value,
    orElse: () =>
        throw const FormatException('This bear could not be recognized.'),
  );
}

enum BearEmotion { happy, shy, surprised, sleepy, sad }

enum AffectionVariant { gentle, shy, playful }

enum SceneTheme {
  cozyRoom,
  flowerGarden,
  moonlitNight,
  rainyWindow,
  starryBedroom,
  pastelPinkRoom;

  String get label => switch (this) {
    cozyRoom => 'Cozy room',
    flowerGarden => 'Flower garden',
    moonlitNight => 'Moonlit night',
    rainyWindow => 'Rainy window',
    starryBedroom => 'Starry bedroom',
    pastelPinkRoom => 'Blush room',
  };
}
