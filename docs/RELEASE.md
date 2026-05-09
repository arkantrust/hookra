# 🚀 Release Process

This document describes the full release workflow: versioning, branching, tagging, building, and publishing.

## 1. Bump the Version in `pubspec.yaml`

Flutter version strings follow the format `major.minor.patch+buildNumber`:

```yaml
# pubspec.yaml
version: 1.3.0+42
#        └─────┘ └──┘
#        semver  build number (integer, monotonically increasing)
```

Rules:
- Increment **patch** for bug fixes (`1.2.1`)
- Increment **minor** for new features, reset patch (`1.3.0`)
- Increment **major** for breaking changes, reset minor and patch (`2.0.0`)
- **Always increment the build number** — it must be strictly greater than the previous release. Android uses this, not the semver string, to enforce upgrade order.

Commit the bump to `dev`:

```bash
# Edit pubspec.yaml, then:
git add pubspec.yaml
git commit -m "chore: bump version to 1.3.0+42"
```

## 2. Merge `dev` → `main`

We don't use release branches. `main` is always the release-ready snapshot.

```bash
git checkout main
git pull origin main          # ensure you're up to date
git merge --no-ff dev         # preserve merge commit for traceability
git push origin main
```

> `--no-ff` (no fast-forward) forces a merge commit even if the history is linear.
> This keeps the branch topology explicit in `git log --graph`, which matters for auditing releases.

Verify the merge landed cleanly before proceeding:

```bash
git log --oneline -5
```

## 3. Create and Push the Annotated Tag

Tags must be created on `main` after the merge, never on `dev`.

```bash
git checkout main             # should already be here
git pull origin main          # confirm you're on the merged HEAD

git tag -a v1.3.0 -m "Release v1.3.0"
git push origin v1.3.0
```

Tag naming convention: `v` prefix + semver string matching `pubspec.yaml` (build number excluded — it's an internal artifact detail, not part of the public version identifier).

To verify the tag points to the right commit:

```bash
git show v1.3.0 --stat
```

> ⚠️ Never reuse or force-push a tag (`git tag -f`). If you tagged the wrong commit, delete both the local and remote tag, then re-tag:
> ```bash
> git tag -d v1.3.0
> git push origin --delete v1.3.0
> # fix whatever was wrong, then tag again
> ```

## 4. Build the Artifacts

Switch to `main`, confirm you're on the tagged commit, then build.

```bash
git checkout main
git status    # should be clean, no uncommitted changes
```

# 📦 Building the Android App
This document explains how to build and install the Android version of our Flutter app. (iOS support coming soon.)
## 🛠️ Build Commands
To build release APKs for Android (split by ABI), run:
```bash
flutter build apk --release --split-per-abi
```
This generates multiple APKs in `build/app/outputs/apk/release/`, one for each architecture (e.g., `arm64-v8a`, `armeabi-v7a`, etc.).
> Most modern android devices use `arm64-v8a`.
### Why split by ABI?
* 🔽 **Smaller APKs**: Devices download only what they need, reducing download and install size.
* 🚀 **Better performance**: Minified code and assets = faster app load times.
* 📦 **Avoids fat APKs**: A single APK with all ABIs is large and inefficient.
## 📲 Install on Device
To install the generated APK (e.g., `arm64-v8a`) on your device:
```bash
flutter install --use-application-binary=./build/app/outputs/apk/release/app-arm64-v8a-release.apk
```
> Make sure the connected device matches the target ABI.
## 📚 About App Bundles
[Official Flutter docs on building AABs](https://docs.flutter.dev/deployment/android#build-an-app-bundle)
We currently prefer APKs for direct installs because:
* 🧪 **App Bundles sometimes break**: AABs can introduce issues during Google Play testing or internal QA.
* 🔍 **Harder to test locally**: AABs need Play Store or bundletool to install, which complicates device testing.
We may switch to AABs for Play Store deployment once our CI/CD pipeline covers it reliably.

## 5. Publish to GitHub Releases

Use the GitHub CLI (`gh`). If you don't have it: [cli.github.com](https://cli.github.com).

```bash
gh release create v1.3.0 \
  build/app/outputs/apk/release/app-arm64-v8a-release.apk \
  build/app/outputs/apk/release/app-armeabi-v7a-release.apk \
  build/app/outputs/apk/release/app-x86_64-release.apk \
  --title "v1.3.0" \
  --notes "Release notes here." \
  --verify-tag
```

Flags:
- `--verify-tag` — refuses to create the release if the tag doesn't exist on the remote. Catches the case where you forgot to push the tag.
- `--prerelease` — add this flag for RCs or betas (`v1.3.0-rc.1`).
- `--draft` — creates the release as a draft, letting you review before publishing.

To confirm the release is live:

```bash
gh release view v1.3.0
```

## Release Checklist

- [ ] pubspec.yaml version bumped (semver + build number)
- [ ] Version bump committed and pushed to dev
- [ ] dev merged into main (--no-ff)
- [ ] Annotated tag created on main HEAD
- [ ] Tag pushed to origin
- [ ] Artifacts built from main (clean working tree)
- [ ] GitHub Release created with all APK variants attached
- [ ] Release visible at: https://github.com/<org>/<repo>/releases
