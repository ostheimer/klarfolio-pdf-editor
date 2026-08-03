# Mac App Store Release Notes

## Current Release Path

Klarfolio PDF Editor is still a SwiftPM-first macOS app. The repository now has the minimum
local artifacts needed for an App Store packaging pass:

- `Packaging/KlarfolioPDFEditor.entitlements`
- `script/build_app_bundle.sh`
- `script/package_app_store.sh`
- `Sources/KlarfolioPDFEditor/Resources/AppIcon.icns`

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
- Suggested subtitle: `PDFs lesen & bearbeiten`
- Positioning: free PDF editing on macOS, local and without an account

## Apple Requirements To Verify

- The app should be uploaded with Xcode, Transporter, or `altool`.
- Mac App Store builds need a unique bundle ID, marketing version, and build
  string in the app bundle.
- The app uses App Sandbox and user-selected read/write file access.
- For this app, avoid broad Downloads/Documents/Pictures entitlements unless a
  reviewable feature requires them. Open and save panels should grant the
  required user-selected file access.

Relevant Apple docs:

- https://developer.apple.com/documentation/xcode/packaging-mac-software-for-distribution
- https://developer.apple.com/documentation/security/accessing-files-from-the-macos-app-sandbox
- https://developer.apple.com/documentation/bundleresources/entitlements/com.apple.security.files.user-selected.read-write
- https://developer.apple.com/help/app-store-connect/manage-builds/upload-builds/

## Remaining Before Submission

- Install Apple signing identities for Mac App Store distribution.
- Register the final bundle ID in Certificates, Identifiers & Profiles.
- Create the App Store Connect app record.
- Run a manual QA pass on sandboxed release builds.
- Prepare screenshots, support URL, privacy answers, age rating, and app
  description.
- Upload with Transporter or Xcode and resolve processing warnings before App
  Review submission.
