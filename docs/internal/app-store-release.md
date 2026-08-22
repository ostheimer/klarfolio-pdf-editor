# Mac App Store Release Notes

## Current Release Path

Klarfolio PDF Editor is still a SwiftPM-first macOS app. The repository now has the minimum
local artifacts needed for an App Store packaging pass:

- `Packaging/KlarfolioPDFEditor.entitlements`
- `script/build_app_bundle.sh`
- `script/package_app_store.sh`
- `Sources/KlarfolioPDFEditor/Resources/AppIcon.icns`
- `.github/workflows/macos-ci.yml`
- `docs/internal/manual-qa.md`
- `docs/internal/app-store-metadata.md`
- `docs/external/privacy.md` (Entwurf; noch nicht öffentlich)

The local debug bundle can be built and sandbox-signed ad hoc:

```bash
./script/build_and_run.sh --verify
```

Local runs use the separate bundle ID `at.ostheimer.klarfoliopdf.debug` so the
development bundle cannot replace the installed App Store bundle as the default
PDF handler. Release and App Store bundles use `at.ostheimer.klarfoliopdf`.

The App Store package script requires Apple distribution certificates in the
login keychain:

```bash
APP_STORE_APP_IDENTITY="3rd Party Mac Developer Application: Example Team" \
APP_STORE_INSTALLER_IDENTITY="3rd Party Mac Developer Installer: Example Team" \
APP_VERSION=0.1.0 \
APP_BUILD=1 \
./script/package_app_store.sh
```

The output package is written to `dist/AppStore/Klarfolio-PDF-Editor-<version>-<build>.pkg`.

Current product metadata:

- Product name: `Klarfolio PDF Editor`
- Bundle ID: `at.ostheimer.klarfoliopdf`
- Suggested subtitle: `PDFs lesen und annotieren`
- Positioning: free PDF editing on macOS, local and without an account

Prepared store text, keywords, review notes, and screenshot guidance are maintained in [`app-store-metadata.md`](app-store-metadata.md). The manual test protocol and evidence requirements are maintained in [`manual-qa.md`](manual-qa.md). Both must be reconciled with the final signed build before submission.

## Continuous Integration

GitHub Actions runs the workflow on macOS 15 with Xcode 16.4 and on the current macOS 26 runner with Xcode 26.6 for pushes, pull requests, and manual dispatches. This covers both the minimum toolchain line and current PDFKit behavior while the app's deployment target remains macOS 14. Each matrix job resolves dependencies, builds debug and release configurations, runs `swift test`, checks all repository shell scripts with `bash -n`, validates the source entitlements and static website, assembles an unsigned temporary debug app bundle, and asserts key `Info.plist` fields. The workflow deliberately does not create a signed `.pkg` or upload anything; distribution identities remain a local release responsibility.

The package declares Swift tools 6.0 because the test suite uses Swift Testing; use Xcode 16 or newer. A local `xcode-select` setting that points only to Command Line Tools can fail to discover the Swift-Testing framework even when private runtime files are present. This is an environment defect, not a reason to omit tests: select a full Xcode installation before normal local testing, for example:

```bash
sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer
swift test --parallel
```

## Apple Requirements To Verify

- Upload the app with Xcode or Transporter.
- Mac App Store builds need a unique bundle ID, marketing version, and build
  string in the app bundle.
- The app uses App Sandbox and user-selected read/write file access.
- For this app, avoid broad Downloads/Documents/Pictures entitlements unless a
  reviewable feature requires them. Open and save panels should grant the
  required user-selected file access.
- A public privacy policy URL is required for macOS apps. Apple also requires the privacy practices declared in App Store Connect to remain accurate. See [Manage app privacy](https://developer.apple.com/help/app-store-connect/manage-app-information/manage-app-privacy/).

Relevant Apple docs:

- https://developer.apple.com/documentation/xcode/packaging-mac-software-for-distribution
- https://developer.apple.com/documentation/security/accessing-files-from-the-macos-app-sandbox
- https://developer.apple.com/documentation/bundleresources/entitlements/com.apple.security.files.user-selected.read-write
- https://developer.apple.com/help/app-store-connect/manage-builds/upload-builds/

## Remaining Before Submission

- Install Apple signing identities for Mac App Store distribution.
- Register the final bundle ID in Certificates, Identifiers & Profiles.
- Create the App Store Connect app record.
- Run and archive the complete [manual QA pass](manual-qa.md) on the final sandboxed, release-signed build.
- Select a public support URL and publish the completed privacy policy at a public HTTPS URL. The current local [privacy draft](../external/privacy.md) is not publishable until the responsible entity and contact details are supplied.
- Verify the in-app privacy notice under `Hilfe > Datenschutz …` against the completed public privacy policy and final build.
- Enter the prepared [store metadata](app-store-metadata.md), then verify screenshots, privacy answers and age rating against the final binary in App Store Connect.
- Upload with Transporter or Xcode and resolve processing warnings before App
  Review submission.
