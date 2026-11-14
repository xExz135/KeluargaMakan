// ACC-01 phone and email input: light client checks before a code is
// requested. The server canonicalizes and decides.
// TEST FIXTURE: not real safety or nutrition data. Numbers and addresses
// are invented.

import 'package:flutter_test/flutter_test.dart';
import 'package:keluargamakan/features/auth/contact_format.dart';
import 'package:keluargamakan_api/api.dart' as api;
import 'package:keluargamakan/features/settings/signed_in_account.dart';

void main() {
  group('ACC-01 Indonesian phone numbers (+62 only, QUESTIONS #61)', () {
    test('ACC-01 "08…" drops the trunk 0 and becomes E.164', () {
      expect(IndonesianPhone.e164('0812 3456 7890'), '+6281234567890');
      expect(IndonesianPhone.e164('0812-3456-7890'), '+6281234567890');
      expect(IndonesianPhone.e164('(0812) 3456 789'), '+628123456789');
    });

    test('ACC-01 numbers typed with +62 or 62 are accepted once', () {
      expect(IndonesianPhone.e164('+62 812 3456 7890'), '+6281234567890');
      expect(IndonesianPhone.e164('6281234567890'), '+6281234567890');
      expect(IndonesianPhone.e164('+62 0812 3456 7890'), '+6281234567890');
      expect(IndonesianPhone.e164('812 3456 7890'), '+6281234567890');
    });

    test('ACC-01 anything that is not an Indonesian mobile number is '
        'refused', () {
      for (final bad in [
        '',
        '0812',
        '021 555 1234',
        '+1 415 555 0100',
        '0812 3456 7890 1234',
        'nomor saya',
      ]) {
        expect(IndonesianPhone.e164(bad), isNull, reason: bad);
      }
    });

    test('ACC-01 the code screen shows the number masked in the middle', () {
      expect(IndonesianPhone.masked('81234567890'), '0812 •••• 7890');
    });
  });

  group('ACC-01 email addresses', () {
    test('ACC-01 a plain address is trimmed and accepted', () {
      expect(EmailAddress.normalized('  nama@contoh.com '), 'nama@contoh.com');
    });

    test('ACC-01 clearly wrong addresses are refused', () {
      for (final bad in ['', 'nama', 'nama@', '@contoh.com', 'a b@c.id']) {
        expect(EmailAddress.normalized(bad), isNull, reason: bad);
      }
      expect(EmailAddress.normalized('nama@contoh'), isNull);
    });

    test('ACC-01 the code screen shows the email masked', () {
      expect(EmailAddress.masked('nama@contoh.com'), 'n•••@contoh.com');
    });
  });

  test('ACC-13 Settings shows the sign-in contact masked, never in full', () {
    api.Account account({String? phone, String? email}) => api.Account(
      id: 'acc-1',
      role: api.AccountRole.manager,
      householdId: 'hh-1',
      phone: phone,
      email: email,
      createdAt: DateTime.utc(2026, 11),
    );
    expect(
      maskedAccountContact(account(phone: '+6281234567890')),
      '0812 •••• 7890',
    );
    expect(
      maskedAccountContact(account(email: 'nama@contoh.com')),
      'n•••@contoh.com',
    );
    expect(maskedAccountContact(account()), isNull);
  });
}
