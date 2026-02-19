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

## 2026-02-18 - Phase 3 Code Review: Critical Bugs & Fixes

**Symptoms:**
- Reports screen loading failure (compile error due to missing variables).
- Navigation crash on Drill-Down (missing import).
- UI crash on Transactions Screen (missing helper method).

**Root Cause:**
1.  **Missing State:** `_expenseData` and `_barData` maps were accidentally deleted from `reports_screen.dart` when adding `_topSpenders`.
2.  **Missing Import:** `transactions_screen.dart` was not imported in `reports_screen.dart`, breaking the `Navigator.push` call.
3.  **Missing Method:** `_buildFilterText()` was referenced in `transactions_screen.dart` but never defined.

**Solution:**
- Restored missing `Map` declarations.
- Added `import 'transactions_screen.dart';`.
- Implemented `_buildFilterText()` to format the filter chip label (e.g., "Food · Feb 1 - Feb 28").
- Removed duplicate `SizedBox` in Reports layout.

**Deprecation Warnings Note:**
- `flutter analyze` flagged `withOpacity` and `value` (in Switch/Checkbox) as deprecated.
- **Meaning:** These features work now but will be removed in future Flutter versions.
- **Action:** Can safely ignore for now, but should eventually migrate to `.withValues(alpha: ...)` and `initialValue`.

## 2026-02-18 - Manual Testing: 4 Bugs Found & Fixed

### Bug 1: Voice Input Freezes on Second Use
**Symptoms:** First voice input works. Re-opening dialog shows stale transcription and red button does nothing.
**Root Cause:** `VoiceService` singleton's `_isListening` flag stayed `true` after dialog dismissal. Guard `if (_isListening) return;` blocked subsequent sessions.
**Solution:** Force-reset via `_speechToText.stop()` before each new session. Added `cancelListening()` call in dialog's `_initialize()`.

**Failed Attempts:** First fix only called `stop()` and checked `_isListening` flag — didn't work because the underlying Android SpeechRecognizer caches its state across sessions.

**Working Solution:** Full re-initialization: set `_isInitialized = false`, call `cancel()` on the speech engine, then `initialize()` fresh before each listen session.

### Bug 5: Manual Form Missing Frequency Selector
**Symptoms:** Manual transaction form showed a "Fixed Cost" switch instead of a recurring frequency dropdown.
**Root Cause:** The form was built with the old `isFixed` boolean model, not the newer `frequency`/`isRecurring` model from the database migration.
**Solution:** Replaced `SwitchListTile('Fixed Cost')` with a `DropdownButtonFormField` offering `None/Daily/Weekly/Monthly/Yearly`. Wired `isRecurring` and `frequency` into the `AppTransaction` constructor.

### Bug 6: No Validation on Empty Amount
**Symptoms:** Pressing 'Add' with a blank amount silently did nothing — no error message shown.
**Root Cause:** The guard `if (amountController.text.isNotEmpty && ...)` silently returned without feedback.
**Solution:** Added explicit validation with red SnackBar prompts for: empty amount, invalid/zero amount, and missing account selection.

### Bug 2: Drill-Down Navigation Not Firing
**Symptoms:** Tapping pie chart slice shows amount badge but no navigation to filtered transactions.
**Root Cause:** `onCategoryTap` (which calls `Navigator.push`) was invoked *inside* `setState()`, causing the framework to silently drop the navigation during build.
**Solution:** Moved `onCategoryTap` outside `setState` using `WidgetsBinding.instance.addPostFrameCallback`.

### Bug 3: CSV Export File Not Findable
**Symptoms:** Export snackbar shows a raw app-private path (`/data/data/com.example.sam/...`) invisible to Files app.
**Root Cause:** Used `getApplicationDocumentsDirectory()` which returns a sandboxed directory.
**Solution:** Save to `/storage/emulated/0/Download/` on Android. Show "Report saved to Downloads 📁" message.

### Bug 4: Recurring Costs UI Missing
**Symptoms:** No visual indication of recurring transactions. "Fixed Costs" label confusing.
**Root Cause:** `transactions_screen.dart` had zero references to `isRecurring`, `frequency`, or `isFixed`.
**Solution:** Added category/account chips and 🔁 recurring badge to transaction cards. Renamed "Exclude Fixed" → "Exclude Recurring" in Reports.
