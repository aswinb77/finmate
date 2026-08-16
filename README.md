# finmate

Finmate — Flutter personal finance app.

## Build & Release (quick)

Android release (locally):

```bash
flutter build apk --release
# or build app bundle (recommended for Play Store)
flutter build appbundle --release
```

Outputs:
- `build/app/outputs/flutter-apk/app-release.apk`
- `build/app/outputs/bundle/release/app-release.aab`

To publish on GitHub Releases (manual):

1. Tag the release:
```bash
git tag -a v1.0.0 -m "v1.0.0"
git push origin --tags
```
2. Create a release and upload the APK (or use the web UI):
```bash
gh release create v1.0.0 build/app/outputs/flutter-apk/app-release.apk \
	-t "v1.0.0" -n "Release notes"
```

Or rely on the included GitHub Actions workflow to build and publish on tag pushes: `.github/workflows/android-release.yml`.

## iOS

Building iOS requires macOS and an Apple Developer account. Use:

```bash
flutter build ipa --release
```

## Important notes

- Firebase config files (`android/app/google-services.json`, `ios/Runner/GoogleService-Info.plist`) are client configs — expected in the repo for local builds. Do not commit private keystores or `key.properties` that contain secrets.
- Signing keys (Android keystore) should be stored securely and not committed. See `android/.gitignore` which already ignores `key.properties`.

## Cleanup (reclaim disk space)

Remove build artifacts locally:

```bash
flutter clean
rm -rf build/ .dart_tool/ android/.gradle ios/Pods
```

## Contributing

Open issues or PRs against this repository. For major changes, open an issue first to discuss.

---
If you need, I can also add instructions to generate signed releases, CI secrets setup, or an AAB publishing workflow.
