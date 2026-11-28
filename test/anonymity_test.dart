import 'package:clairediary/utils/anonymity.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const google =
      'https://lh3.googleusercontent.com/a/ACg8ocJ-some-face=s96-c';

  test('Google profile photos are detected', () {
    expect(isPersonalPhotoUrl(google), isTrue);
    expect(isPersonalPhotoUrl(kDefaultClairevatarUrls.first), isFalse);
    expect(isPersonalPhotoUrl(''), isFalse);
    expect(isPersonalPhotoUrl(null), isFalse);
  });

  test('safeAvatarUrl swaps Google photos for a stable Clairevatar', () {
    final a = safeAvatarUrl(google);
    expect(kDefaultClairevatarUrls, contains(a));
    expect(safeAvatarUrl(google), a);
    expect(safeAvatarUrl(kDefaultClairevatarUrls[3]), kDefaultClairevatarUrls[3]);
    expect(safeAvatarUrlOrNull(null), isNull);
  });

  test('new sign-ups get a default Clairevatar', () {
    expect(kDefaultClairevatarUrls, contains(randomClairevatarUrl()));
  });
}
