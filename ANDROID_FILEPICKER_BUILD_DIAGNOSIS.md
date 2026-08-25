# Android FilePicker Build Diagnosis

## Failure

The device build failed at `GeneratedPluginRegistrant.java` because `com.mr.flutter.plugin.filepicker.FilePickerPlugin` was referenced but not compiled into the Android plugin classpath. Cleaning `.dart_tool`, `build`, `android/.gradle`, and the Gradle build did not change the error, so this was not only a stale local cache.

## Confirmed cause

SpineUp uses Android Gradle Plugin 9.0.1 with Gradle 9.1.0. FilePicker 11.0.3 still contains Android Kotlin source for `FilePickerPlugin`, but its Android Gradle script conditionally avoids applying the legacy Kotlin Gradle Plugin when AGP 9 or later is detected. That leaves the Kotlin source uncompiled while Flutter’s generated Java registrant still references the plugin class.

The FilePicker issue history documents the same `cannot find symbol FilePickerPlugin` failure under AGP 9 and reports that reverting to a Gradle 8.13-era toolchain restores the build [1] [2]. Flutter’s migration guidance confirms that AGP 9 introduces built-in Kotlin support and that legacy Kotlin-plugin assumptions remain a compatibility boundary for plugins during the transition [3].

## Chosen correction

Downgrade the host Android toolchain only from AGP 9.0.1 / Gradle 9.1.0 to AGP 8.13.0 / Gradle 8.13. Keep `file_picker: ^11.0.3` unchanged so the portability feature retains its current Android, Web, and desktop API surface. Under AGP 8.13, FilePicker’s plugin script applies its Kotlin Android plugin and its `FilePickerPlugin` class can be compiled normally.

This is deliberately smaller and safer than replacing FilePicker or rewriting portability. The KGP notices may remain informational under the older AGP line, but they no longer block the Android build. A future upgrade to AGP 9 should wait until every native plugin used by SpineUp has completed the built-in Kotlin migration.

## References

[1]: https://github.com/miguelpruivo/flutter_file_picker/issues/1973 "FilePicker 11.0.0 AGP 9 missing Kotlin plugin issue"

[2]: https://github.com/miguelpruivo/flutter_file_picker/issues/1952 "FilePicker cannot find symbol issue and compatible version discussion"

[3]: https://docs.flutter.dev/release/breaking-changes/migrate-to-built-in-kotlin "Flutter built-in Kotlin migration guidance"
