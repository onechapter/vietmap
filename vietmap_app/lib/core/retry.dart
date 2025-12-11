import 'dart:async';
import 'dart:math';

typedef RetryTask<T> = Future<T> Function();

class ExponentialBackoff {
  final int maxAttempts;
  final Duration baseDelay;
  final Duration maxDelay;

  ExponentialBackoff({
    this.maxAttempts = 5,
    this.baseDelay = const Duration(milliseconds: 400),
    this.maxDelay = const Duration(seconds: 8),
  });

  Future<T> run<T>(RetryTask<T> task) async {
    int attempt = 0;
    while (true) {
      try {
        return await task();
      } catch (e) {
        attempt++;
        if (attempt >= maxAttempts) rethrow;
        final jitter = Random().nextDouble() * 0.4 + 0.8;
        final delay = Duration(
          milliseconds: min(
            (baseDelay.inMilliseconds * pow(2, attempt)).toInt(),
            maxDelay.inMilliseconds,
          ),
        );
        await Future.delayed(Duration(milliseconds: (delay.inMilliseconds * jitter).toInt()));
      }
    }
  }
}

