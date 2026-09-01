import 'package:flutter_test/flutter_test.dart';
import 'package:oasx/modules/home/controllers/dashboard_controller.dart';
import 'package:oasx/modules/home/models/home_workbench_layout.dart';

void main() {
  test('weekly schedule is available in every workbench layout', () {
    expect(
      resolveHomeWorkbenchTabs(HomeWorkbenchLayoutMode.singlePane),
      contains(HomeWorkbenchTab.weeklySchedule),
    );
    expect(
      resolveHomeWorkbenchTabs(HomeWorkbenchLayoutMode.twoPane),
      contains(HomeWorkbenchTab.weeklySchedule),
    );
    expect(
      resolveHomeWorkbenchTabs(HomeWorkbenchLayoutMode.threePane),
      contains(HomeWorkbenchTab.weeklySchedule),
    );
    expect(
      isHomeWorkbenchSidebarTab(HomeWorkbenchTab.weeklySchedule),
      isFalse,
    );
  });

  test('behavior analysis is placed after logs and statistics', () {
    final tabs = resolveHomeWorkbenchTabs(HomeWorkbenchLayoutMode.twoPane);
    expect(tabs.sublist(tabs.length - 3), [
      HomeWorkbenchTab.logs,
      HomeWorkbenchTab.stats,
      HomeWorkbenchTab.behaviorAnalysis,
    ]);
    expect(
      resolveHomeWorkbenchSidebarTabs(HomeWorkbenchLayoutMode.threePane),
      [
        HomeWorkbenchTab.logs,
        HomeWorkbenchTab.stats,
        HomeWorkbenchTab.behaviorAnalysis,
      ],
    );
  });
}
