import 'dart:math';

/// Dear Claire is an anonymous app. Nobody's real face or real name may
/// appear in a profile, session, comment or chat. These helpers keep it so.

/// Default Clairevatars handed out at sign-up.
const List<String> kDefaultClairevatarUrls = [
  "https://firebasestorage.googleapis.com/v0/b/clair-52652/o/ClaireVartar%2Ficons8-walter-white-72.png?alt=media&token=0b791843-76ae-4441-aca6-8a06f9e6fa67",
  "https://firebasestorage.googleapis.com/v0/b/clair-52652/o/ClaireVartar%2Fbear.png?alt=media&token=c5348009-e700-4a5f-ae83-6653e29784d7",
  "https://firebasestorage.googleapis.com/v0/b/clair-52652/o/ClaireVartar%2Fthoughtful_baby.png?alt=media&token=702c1fa9-ed42-4764-ad8e-8a1a21ff9679",
  "https://firebasestorage.googleapis.com/v0/b/clair-52652/o/ClaireVartar%2Ficons8-homer-simpson-72.png?alt=media&token=3461c319-0840-47f0-8025-8773587a6189",
  "https://firebasestorage.googleapis.com/v0/b/clair-52652/o/ClaireVartar%2Ficons8-parrot-72.png?alt=media&token=3cdf21b9-b7da-450e-94e0-c54b4fcba295",
  "https://firebasestorage.googleapis.com/v0/b/clair-52652/o/ClaireVartar%2Ficons8-starfish-72.png?alt=media&token=ad4feba1-ddc3-4354-bc0e-4cef75fb2fbc",
  "https://firebasestorage.googleapis.com/v0/b/clair-52652/o/ClaireVartar%2FYellow_Moon_Emoji.png?alt=media&token=98cd50a5-f2a0-411a-9aef-06fd91d16c52",
  "https://firebasestorage.googleapis.com/v0/b/clair-52652/o/ClaireVartar%2FUpside-Down_Face_Emoji.png?alt=media&token=be8ded7e-4880-490a-9bf7-6a0aef361c1c",
  "https://firebasestorage.googleapis.com/v0/b/clair-52652/o/ClaireVartar%2Ficons8-strawberry-72.png?alt=media&token=ff64370f-939c-46ce-af5e-d220a625ef51",
  "https://firebasestorage.googleapis.com/v0/b/clair-52652/o/ClaireVartar%2FHugging_Face_Emoji.png?alt=media&token=108f537b-2671-4fce-ade8-3618d3665fc6",
  "https://firebasestorage.googleapis.com/v0/b/clair-52652/o/ClaireVartar%2Fpanda_dance.png?alt=media&token=7bd9a4d9-ed60-4736-af74-c19eb7c69d6a",
  "https://firebasestorage.googleapis.com/v0/b/clair-52652/o/ClaireVartar%2Ficons8-iron-man-72(-hdpi).png?alt=media&token=4c7b9989-a762-469b-8386-c1d8daf2c8cc",
];

final Random _random = Random();

/// A random default Clairevatar for a new user.
String randomClairevatarUrl() =>
    kDefaultClairevatarUrls[_random.nextInt(kDefaultClairevatarUrls.length)];

/// Hosts that serve personal profile photos from sign-in providers
/// (Google account photos, mainly). Clairevatars never live on these.
const List<String> _personalPhotoHosts = [
  'googleusercontent.com',
  'ggpht.com',
  'graph.facebook.com',
  'fbcdn.net',
  'pbs.twimg.com',
  'appleid.cdn-apple.com',
];

/// True when [url] points at a personal photo from a sign-in provider.
bool isPersonalPhotoUrl(String? url) {
  if (url == null || url.trim().isEmpty) return false;
  final String host = (Uri.tryParse(url.trim())?.host ?? '').toLowerCase();
  if (host.isEmpty) return false;
  return _personalPhotoHosts.any((h) => host == h || host.endsWith('.$h'));
}

/// Returns [url] unless it is a personal photo, in which case a default
/// Clairevatar is returned instead. The replacement is stable for the same
/// [url], so one person keeps the same stand-in avatar everywhere.
String safeAvatarUrl(String? url) {
  if (!isPersonalPhotoUrl(url)) return url ?? '';
  final int index = url!.codeUnits.fold<int>(0, (a, c) => (a * 31 + c) & 0x7fffffff) %
      kDefaultClairevatarUrls.length;
  return kDefaultClairevatarUrls[index];
}

/// Nullable variant of [safeAvatarUrl] for models whose field may be null.
String? safeAvatarUrlOrNull(String? url) => url == null ? null : safeAvatarUrl(url);

const List<String> _nickAdjectives = [
  'Gentle', 'Quiet', 'Brave', 'Kind', 'Sunny', 'Calm', 'Hopeful', 'Bright',
  'Soft', 'Golden', 'Lucky', 'Cosy', 'Dreamy', 'Sweet', 'Wise', 'Silver',
];
const List<String> _nickNouns = [
  'Moon', 'Petal', 'Sparrow', 'Star', 'River', 'Cloud', 'Rose', 'Breeze',
  'Dove', 'Lily', 'Pearl', 'Robin', 'Meadow', 'Willow', 'Ember', 'Daisy',
];

/// An anonymous nickname such as "Gentle Moon 482", used for Google and
/// Apple sign-ups instead of the account's real name. Users can change it
/// in their profile.
String randomAnonymousNickname() {
  final String adj = _nickAdjectives[_random.nextInt(_nickAdjectives.length)];
  final String noun = _nickNouns[_random.nextInt(_nickNouns.length)];
  return '$adj $noun ${100 + _random.nextInt(900)}';
}
