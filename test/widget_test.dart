import 'package:flutter_test/flutter_test.dart';
import 'package:run_rest/models/workout_config.dart';

void main() {
  test('WorkoutConfig default presets smoke test', () {
    expect(WorkoutConfig.defaultPresets.isNotEmpty, true);
    final walk = WorkoutConfig.defaultPresets.first;
    expect(walk.runDuration.inSeconds, 60);
    expect(walk.restDuration.inSeconds, 90);
  });
}
