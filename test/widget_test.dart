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
}
