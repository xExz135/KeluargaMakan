// The current time, as a provider so countdowns (sign-in resend, rate-limit
// waits) can be tested without waiting in real time.

import 'package:flutter_riverpod/flutter_riverpod.dart';

typedef Now = DateTime Function();

final clockProvider = Provider<Now>((ref) => DateTime.now);
