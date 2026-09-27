import 'package:ai_teacher/core/assignment/data/trial_booking_repository.dart';
import 'package:ai_teacher/ui/home/widget/trial_lesson_card.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

Widget appWithTrial(TrialBooking? booking) => ProviderScope(
  overrides: [trialBookingProvider.overrideWith((ref) async => booking)],
  child: const MaterialApp(home: Scaffold(body: TrialLessonCard())),
);

void main() {
  test('booking API data selects only the upcoming trial lesson', () async {
    final dio = Dio(BaseOptions(baseUrl: 'http://localhost:8000/api/'));
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          expect(options.path, 'lesson-booking/my');
          handler.resolve(
            Response(
              requestOptions: options,
              data: [
                {
                  'id': 'regular',
                  'isTrial': false,
                  'startsAt': DateTime.now()
                      .add(const Duration(hours: 1))
                      .toIso8601String(),
                  'durationMin': 30,
                },
                {
                  'id': 'chosen-trial',
                  'isTrial': true,
                  'startsAt': DateTime.now()
                      .add(const Duration(hours: 2))
                      .toIso8601String(),
                  'durationMin': 30,
                  'mentorName': 'Test mentor',
                },
              ],
            ),
          );
        },
      ),
    );
    final booking = await TrialBookingRepository(dio).getUpcomingTrial();
    expect(booking?.id, 'chosen-trial');
    expect(booking?.mentorName, 'Test mentor');
  });

  testWidgets('scheduled trial appears and explains when entry opens', (
    tester,
  ) async {
    final booking = TrialBooking(
      id: 'trial-1',
      startsAt: DateTime.now().add(const Duration(hours: 2)),
      durationMin: 30,
      mentorName: 'Test mentor',
    );
    await tester.pumpWidget(appWithTrial(booking));
    await tester.pump();

    expect(find.text('Demo darsingiz tayyor'), findsOneWidget);
    expect(find.text('Dars vaqtini ko‘rish'), findsOneWidget);
    expect(find.textContaining('Test mentor'), findsOneWidget);

    await tester.tap(find.text('Dars vaqtini ko‘rish'));
    await tester.pumpAndSettle();
    expect(find.text('Dars eshigi hali ochilmadi'), findsOneWidget);
    expect(find.textContaining('10 daqiqa oldin'), findsOneWidget);
  });

  testWidgets('entry action appears in the ten-minute window', (tester) async {
    final booking = TrialBooking(
      id: 'trial-2',
      startsAt: DateTime.now().add(const Duration(minutes: 9)),
      durationMin: 30,
      mentorName: 'Test mentor',
    );
    await tester.pumpWidget(appWithTrial(booking));
    await tester.pump();
    expect(find.text('Darsga kirish'), findsOneWidget);
  });

  testWidgets('no trial booking means no trial card', (tester) async {
    await tester.pumpWidget(appWithTrial(null));
    await tester.pump();
    expect(find.text('Demo darsingiz tayyor'), findsNothing);
  });
}
