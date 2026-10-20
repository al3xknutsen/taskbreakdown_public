# TaskBreakdown

A Flutter task-tree app with nested subtasks, completion tracking, local
persistence, and optional speech input.

## Portfolio demo

The default build unlocks premium features without initializing Firebase,
mobile ads, or in-app billing from Dart. Task generation inserts a fixed,
clearly labelled sample tree locally; it is **not live AI** and does not depend
on the task text. There are no purchase or receipt-verification requests.

Speech recognition remains optional and device-dependent. The operating
system's speech service may require network access and microphone permission;
the demo does not guarantee offline speech recognition.

Use Flutter 3.27.1 (Dart 3.6.0), the SDK used to validate this snapshot:

```sh
flutter pub get
flutter run
flutter test
```

Select a task and use the robot button to add sample subtasks. Settings also
allows sample generation after speech input. Tasks remain stored on the device.
