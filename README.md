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

## Purpose and AI-assisted development
I built this app as an experiment in AI-assisted development: to learn how
to guide AI agents and explore their capabilities and limitations when
building a small application.

I made the architectural decisions, organized the code, and chose where
to use external libraries. AI agents generated substantial portions of
the implementation, while I directed the work and wrote or adapted code
where needed, particularly when integrating third-party libraries.

This repository is a portfolio snapshot of that experiment, adapted to
run without production services. It demonstrates my early exploration
of AI-assisted development, rather than a reference implementation of
my current engineering standards.