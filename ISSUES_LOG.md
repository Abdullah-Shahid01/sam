# Issues Log

## 2026-02-16 - Gradle Build Failure: "not a regular file"

**Symptoms:** `flutter run` failed with:
```
java.io.IOException: Cannot snapshot ...\launch_background.xml: not a regular file
```
Error cascaded to `ic_launcher.png`, `styles.xml`, and other files one at a time.

**Root Cause:** 29 files in `android/` had the Windows `ReparsePoint` attribute (symlinks instead of regular files). This is caused by Git's `core.symlinks` configuration — when Git stores small files as symlinks on Windows, Gradle's `mapDebugSourceSetPaths` task cannot snapshot them because Java's `Files.isRegularFile()` returns `false` for reparse points.

**Failed Attempts:**
- `flutter clean` alone — did not fix because the source files themselves were symlinks, not just build artifacts.
- Deleting and recreating individual XML files one at a time — only moved the error to the next symlinked file.

**Solution:**
```powershell
# Read bytes, delete symlink, write bytes back as regular file
Get-ChildItem -Path "android" -Recurse -File |
  Where-Object { $_.Attributes -band [System.IO.FileAttributes]::ReparsePoint } |
  ForEach-Object {
    $content = [System.IO.File]::ReadAllBytes($_.FullName)
    Remove-Item $_.FullName -Force
    [System.IO.File]::WriteAllBytes($_.FullName, $content)
  }
# Then clean Gradle cache and rebuild
Remove-Item -Recurse -Force "android\.gradle"
flutter clean
flutter run
```

**Prevention:**
- Run `git config core.symlinks false` before cloning on Windows
- Or use `git config --global core.symlinks false` system-wide
- If the repo was already cloned with symlinks enabled, run the fix script above

## 2026-02-18 - Navigation Crash: debugLocked assertion

**Symptoms:** App crashes with `navigator.dart: Failed assertion: !debugLocked` when navigating between tabs (e.g., Accounts → Dashboard).

**Root Cause:** `PageRouteBuilder` with `Duration.zero` transitions causes the Navigator to complete the route transition within the same frame, creating a lock conflict when the rebuilt widget tree tries to interact with the Navigator.

**Failed Attempts:**
- Wrapping navigation in `Future.microtask` — did not help because the zero-duration route still completes synchronously within the microtask frame.

**Solution:** Reverted to `MaterialPageRoute` (which has proper async transition timing) and used `WidgetsBinding.instance.addPostFrameCallback` to schedule navigation after the current frame completes.

**Prevention:**
- Never use `Duration.zero` transitions with `PageRouteBuilder` — it creates race conditions with Navigator locks.
- Use `MaterialPageRoute` for tab-style navigation.
