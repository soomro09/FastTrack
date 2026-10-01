import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:fasttrack/main.dart';
import 'package:fasttrack/models/weight_log.dart';
import 'package:fasttrack/models/fasting_log.dart';
import 'package:fasttrack/providers/fasting_provider.dart';
import 'package:fasttrack/ui/widgets/stepped_weight_chart.dart';
import 'package:fasttrack/ui/screens/history_screen.dart';

void main() {
  testWidgets('First launch displays OnboardingScreen questionnaire', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(
      const ProviderScope(
        child: FastingTrackerApp(hasCompletedOnboarding: false),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));

    // Verify Onboarding Screen Step 1 is visible
    expect(find.text('What is your primary goal?'), findsOneWidget);
    expect(find.text('Lose Weight'), findsOneWidget);
    expect(find.text('Maintain Weight'), findsOneWidget);
    expect(find.text('Boost Energy & Detox'), findsOneWidget);
  });

  testWidgets('App loads MainScreen when onboarding is already completed', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({
      'has_completed_onboarding': true,
    });

    await tester.pumpWidget(
      const ProviderScope(
        child: FastingTrackerApp(hasCompletedOnboarding: true),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));

    // Verify that the MainScreen bottom navigation is present
    expect(find.text('Timer'), findsWidgets);
    expect(find.text('Plans'), findsWidgets);
    expect(find.text('History'), findsWidgets);
    expect(find.text('Profile'), findsWidgets);
  });

  testWidgets('SteppedWeightChart renders header, view all, and handles empty and multi-log states', (WidgetTester tester) async {
    // 1. Empty state
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SteppedWeightChart(
            logs: const [],
            onViewAll: () {},
            onAddWeight: () {},
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('Weight'), findsOneWidget);
    expect(find.text('No Weight Entries Yet'), findsOneWidget);

    // 2. Multi-log state (chart drawn)
    final mockLogs = [
      WeightLog(id: 1, weight: 71.2, date: DateTime(2026, 5, 11)),
      WeightLog(id: 2, weight: 69.4, date: DateTime(2026, 5, 12)),
      WeightLog(id: 3, weight: 69.1, date: DateTime(2026, 5, 13)),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SteppedWeightChart(
            logs: mockLogs,
            onViewAll: () {},
            onAddWeight: () {},
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('Weight'), findsOneWidget);
    expect(find.text('view all'), findsOneWidget);
  });

  testWidgets('HistoryScreen renders weekly consistency, stats grid, and sessions', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({
      'user_profile_name': 'Aarav R.',
      'user_member_since': 'Jun 2026',
    });

    final mockLogs = [
      FastingLog(
        id: 1,
        startTime: DateTime.now().subtract(const Duration(hours: 16, minutes: 4)),
        endTime: DateTime.now(),
        targetDurationHours: 16,
        isCompleted: true,
      ),
      FastingLog(
        id: 2,
        startTime: DateTime.now().subtract(const Duration(days: 1, hours: 14, minutes: 22)),
        endTime: DateTime.now().subtract(const Duration(days: 1)),
        targetDurationHours: 14,
        isCompleted: true,
      ),
    ];

    // Set taller test screen size so full scrollable content is visible
    await tester.binding.setSurfaceSize(const Size(800, 1600));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          fastingHistoryProvider.overrideWith((ref) => Future.value(mockLogs)),
        ],
        child: const MaterialApp(
          home: HistoryScreen(),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));

    // Verify Title and Subtitle (Image 1)
    expect(find.text('History'), findsOneWidget);
    expect(find.text('Last 7 days of activity'), findsOneWidget);

    // Verify Weekly Consistency Card (Image 1)
    expect(find.text('WEEKLY CONSISTENCY'), findsOneWidget);

    // Verify 2x2 Stat Cards (Image 1)
    expect(find.text('Total fasts'), findsOneWidget);
    expect(find.text('Total hours'), findsOneWidget);
    expect(find.text('Longest fast'), findsOneWidget);
    expect(find.text('Current streak'), findsOneWidget);

    // Verify Sessions Header & Items (Image 1)
    expect(find.text('Sessions'), findsOneWidget);
    expect(find.text('COMPLETE'), findsWidgets);
    expect(find.text('16:8'), findsOneWidget);
    expect(find.text('14:10'), findsOneWidget);
  });
}

