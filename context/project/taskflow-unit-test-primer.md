# Taskflow Unit Test Primer

A hands-on tutorial for new developers to learn the TDD workflow used in this project. By completing this primer, you will understand how to write tests, implement features, and use the development tools before starting real application development.

## Purpose

This primer is a **learning exercise on a throwaway branch**. You will:

1. Create a temporary feature branch
2. Implement a simple Taskflow component using TDD
3. Verify your development environment works correctly
4. Delete the branch when finished

After completing this primer, you will be ready to develop real features using the same workflow.

## Prerequisites

Before starting, ensure you have:

- [ ] Cloned the project and initialized submodules
- [ ] Installed build tools: `clang`, `cmake` (3.28+), `ninja` or `make`
- [ ] Installed VSCode with C++ TestMate extension
- [ ] Read `context/standards/cpp-tdd.md` (TDD overview)

## What You Will Learn

| Skill | Description |
|-------|-------------|
| TDD Workflow | Red-Green-Refactor cycle with proper commits |
| CMake | Adding source and test files to the build system |
| GoogleTest | Writing and running unit tests |
| Taskflow | Basic task creation and dependencies |
| VSCode | Using Test Explorer for debugging |
| Git | Feature branch workflow |

---

## Step 0: Verify Your Environment

Before creating any files, confirm your environment is working.

### 0.1: Choose TDD Preset

This project provides two TDD presets with sanitizers enabled:

| Preset | Sanitizers | Use Case |
|--------|------------|----------|
| `tdd-tsan` | Thread + UB | **Primary** - Catches race conditions (critical for Taskflow) |
| `tdd-asan` | Address + UB | Alternative - Catches memory errors, includes coverage |

For this primer (and most Taskflow development), use `tdd-tsan` because:
- Taskflow is a parallel programming library
- Race conditions are the most common and subtle bugs
- Thread sanitizer catches issues that would otherwise be intermittent

### 0.2: Configure and Build

**VSCode:**
1. Open the project folder in VSCode
2. If prompted "Select a Configure Preset", choose **"TDD with Thread Sanitizer"** (`tdd-tsan`). VSCode may auto-configure using the first preset - check the Output panel (CMake tab) to confirm `tdd-tsan` was selected.
3. Press `Ctrl+Shift+P` → "CMake: Build", or click **Build** in the bottom status bar

**Terminal:**
```bash
cmake --preset tdd-tsan
cmake --build build-tdd-tsan
```

Expected: Build completes without errors.

### 0.3: Run Existing Tests

**VSCode:**
1. Click Testing icon (beaker) in sidebar
2. Expand the project node to see discovered tests
3. Click play button at top to run all tests

**Terminal:**
```bash
ctest --test-dir build-tdd-tsan --output-on-failure
```

Expected: All existing tests pass with no sanitizer warnings.

### 0.4: Verify VSCode Setup

Verify:
- C++ TestMate extension is installed (check Extensions sidebar)
- Test Explorer shows existing tests (beaker icon in sidebar)
- All tests show green checkmarks after running

If any step fails, resolve the issue before continuing.

### 0.5: Configure TSan Suppressions

ThreadSanitizer may report false positives in Taskflow's internal threading code (specifically in the `pipe` system call used for thread signaling). These are benign and must be suppressed.

**Create suppression file:**

Create a new file `cmake/tsan_suppressions.txt` with one line:

**VSCode:**
1. Right-click the `cmake` folder in Explorer
2. Select "New File"
3. Name it `tsan_suppressions.txt`
4. Add the following content and save:

```
race:pipe
```

**Terminal:**
```bash
echo "race:pipe" > cmake/tsan_suppressions.txt
```

**Update CMakePresets.json:**

Add the `environment` property to the `tdd-tsan` **test** preset (in the `testPresets` array, not `configurePresets`):

```json
{
    "name": "tdd-tsan",
    "configurePreset": "tdd-tsan",
    "output": {
        "outputOnFailure": true,
        "verbosity": "verbose"
    },
    "environment": {
        "TSAN_OPTIONS": "suppressions=${sourceDir}/cmake/tsan_suppressions.txt"
    }
}
```

**Verify suppression works:**

**Terminal:**
```bash
ctest --preset tdd-tsan
```

Expected: Tests pass without TSan warnings about `pipe`.

**Note:** VSCode's C++ TestMate extension reads the test preset environment, so suppressions work automatically when running tests from the Testing sidebar.

**Commit the fix:**

```bash
git add cmake/tsan_suppressions.txt
git add CMakePresets.json
git commit -m "build: Add TSan suppression for Taskflow false positives"
```

**Important:** This suppression is required for any project using Taskflow with ThreadSanitizer. Without it, TSan will report false positives in Taskflow's internal thread signaling code, causing tests to fail even when the application logic is correct.

---

## Step 1: Create Feature Branch

All development happens on feature branches, never directly on the main branch.

**Note:** This primer uses git commands from the terminal. You may use VSCode's Source Control tab at your own discretion.

```bash
git checkout -b feature/primer-exercise
```

Verify you are on the new branch:

```bash
git branch --show-current
```

Expected output: `feature/primer-exercise`

**Note:** In an established project, you would first run `git checkout main && git pull` to ensure you're starting from the latest code. For this primer exercise, we skip that step.

---

## Phase 1: RED - Write Failing Test

In TDD, we write the test first. The test will fail because the implementation does not exist yet.

### 1.1: Create Test File

Create a new file `tests/simple_pipeline_test.cpp`:

```cpp
#include <gtest/gtest.h>

// This header does not exist yet - compilation will fail
#include "mylib/simple_pipeline.hpp"

namespace mylib {
namespace {

// Test naming convention: ClassName_Method_Scenario_ExpectedBehavior
TEST(SimplePipeline, Run_TwoSequentialTasks_ReturnsTwo) {
  // Arrange: Create the pipeline
  SimplePipeline pipeline;

  // Act: Execute the pipeline
  int result = pipeline.Run();

  // Assert: Verify the result
  EXPECT_EQ(result, 2);
}

}  // namespace
}  // namespace mylib
```

### 1.2: Update CMakeLists.txt

Edit `tests/CMakeLists.txt` to include the new test file:

```cmake
# Test executable
add_executable(mylib_tests
    test_mylib.cpp
    simple_pipeline_test.cpp
)

# Link against library and GoogleTest
target_link_libraries(mylib_tests
    PRIVATE
        mylib::mylib
        GTest::gtest_main
)

# Discover tests for CTest
include(GoogleTest)
gtest_discover_tests(mylib_tests
    PROPERTIES
        LABELS "unit"
)
```

### 1.3: Attempt to Build (Expect Failure)

**VSCode:**
1. Press `Ctrl+Shift+P`
2. Type "CMake: Build"
3. Press Enter

**Terminal:**
```bash
cmake --build build-tdd-tsan
```

Expected error:

```
fatal error: 'mylib/simple_pipeline.hpp' file not found
#include "mylib/simple_pipeline.hpp"
         ^~~~~~~~~~~~~~~~~~~~~~~~~~~
```

This is correct. The test references a header that does not exist. In TDD, compile errors count as "red" (failing).

### 1.4: Create Header (Declaration Only)

Create `include/mylib/simple_pipeline.hpp` with the class declaration:

**Warning:** If using VSCode's autocomplete to create the class, it may suggest `simple_pipeline` (matching the filename). The class name must be `SimplePipeline` (PascalCase) per Google C++ Style Guide. File names use `snake_case`, class names use `PascalCase`.

```cpp
#ifndef MYLIB_SIMPLE_PIPELINE_HPP
#define MYLIB_SIMPLE_PIPELINE_HPP

namespace mylib {

class SimplePipeline {
 public:
  int Run();
};

}  // namespace mylib

#endif  // MYLIB_SIMPLE_PIPELINE_HPP
```

### 1.5: Create Implementation Stub

Create `src/simple_pipeline.cpp` with a stub that returns the wrong value:

```cpp
#include "mylib/simple_pipeline.hpp"

namespace mylib {

int SimplePipeline::Run() {
  return 0;  // Intentionally wrong - test will fail
}

}  // namespace mylib
```

### 1.6: Update Library CMakeLists.txt

Edit `src/CMakeLists.txt` to include the new source file:

```cmake
# Library target
add_library(mylib
    mylib.cpp
    simple_pipeline.cpp
)

# Public headers for consumers
target_include_directories(mylib
    PUBLIC
        $<BUILD_INTERFACE:${CMAKE_SOURCE_DIR}/include>
        $<INSTALL_INTERFACE:include>
)

# Link to Taskflow (includes threading automatically)
target_link_libraries(mylib PUBLIC Taskflow::Taskflow)

# Alias for consistent usage
add_library(mylib::mylib ALIAS mylib)
```

### 1.7: Build Again

**VSCode:**
1. Press `Ctrl+Shift+P` → "CMake: Build", or click **Build** in the bottom status bar

**Terminal:**
```bash
cmake --build build-tdd-tsan
```

**Tip:** If switching between VSCode and terminal for building, you may encounter CMake caching issues where changes aren't detected. If the build seems to skip recompilation, delete `build-tdd-tsan/tests` and reconfigure:
```bash
rm -rf build-tdd-tsan/tests
cmake --preset tdd-tsan
cmake --build build-tdd-tsan
```

Expected: Build succeeds (no compile errors).

### 1.8: Run Test (Expect Failure)

**VSCode:**
1. Click Testing icon (beaker) in sidebar
2. Click refresh button to discover new test
3. Find `SimplePipeline.Run_TwoSequentialTasks_ReturnsTwo`
4. Click play button next to it

**Terminal:**

After adding a new test file to `CMakeLists.txt`, you must reconfigure and rebuild:

```bash
cmake --preset tdd-tsan
cmake --build build-tdd-tsan
ctest --test-dir build-tdd-tsan -R SimplePipeline --output-on-failure
```

**Note:** VSCode handles test discovery automatically. Command-line users must reconfigure and rebuild after adding new test files to `CMakeLists.txt`, otherwise `ctest` will report "No tests were found!!" Adding new `TEST()` cases to an existing file only requires a rebuild.

Expected output:

```
    Start 1: SimplePipeline.Run_TwoSequentialTasks_ReturnsTwo
1/1 Test #1: SimplePipeline.Run_TwoSequentialTasks_ReturnsTwo ***Failed

Expected equality of these values:
  result
    Which is: 0
  2
```

**RED PHASE COMPLETE**: The test fails for the right reason (wrong return value).

### 1.9: Commit RED Phase

```bash
git add tests/simple_pipeline_test.cpp
git add tests/CMakeLists.txt
git add include/mylib/simple_pipeline.hpp
git add src/simple_pipeline.cpp
git add src/CMakeLists.txt
git commit -m "Red: Add test for SimplePipeline.Run

Test that SimplePipeline.Run returns 2 after executing two
sequential tasks. Currently fails with return value 0.

Establishes the contract: Run() must create two dependent
tasks and return the count after execution."
```

---

## Phase 2: GREEN - Minimal Implementation

Now we write the minimum code needed to make the test pass. No extra features, no optimization.

### 2.1: Update Header

Replace the contents of `include/mylib/simple_pipeline.hpp` to add the private member:

```cpp
#ifndef MYLIB_SIMPLE_PIPELINE_HPP
#define MYLIB_SIMPLE_PIPELINE_HPP

#include <atomic>

namespace mylib {

class SimplePipeline {
 public:
  SimplePipeline();
  int Run();

 private:
  std::atomic<int> counter_;
};

}  // namespace mylib

#endif  // MYLIB_SIMPLE_PIPELINE_HPP
```

**Tip:** After modifying the header, run a build to refresh VSCode's IntelliSense. Autocomplete will then recognize the new declarations when editing the `.cpp` file.

### 2.2: Update Implementation

Replace the contents of `src/simple_pipeline.cpp` with the Taskflow implementation:

```cpp
#include "mylib/simple_pipeline.hpp"

#include <taskflow/taskflow.hpp>

namespace mylib {

SimplePipeline::SimplePipeline() : counter_(0) {}

int SimplePipeline::Run() {
  tf::Executor executor;
  tf::Taskflow taskflow;

  // Task A increments counter
  auto task_a = taskflow.emplace([this]() {
    counter_.fetch_add(1, std::memory_order_relaxed);
  });

  // Task B increments counter (must run after A)
  auto task_b = taskflow.emplace([this]() {
    counter_.fetch_add(1, std::memory_order_relaxed);
  });

  // Define dependency: A runs before B
  task_a.precede(task_b);

  // Execute and wait for completion
  executor.run(taskflow).wait();

  return counter_.load(std::memory_order_relaxed);
}

}  // namespace mylib
```

### 2.3: Build

**VSCode:**
1. Press `Ctrl+Shift+P` → "CMake: Build"

**Terminal:**
```bash
cmake --build build-tdd-tsan
```

Expected: Build succeeds.

### 2.4: Run Test (Expect Pass)

**VSCode:**
1. Click Testing icon (beaker) in sidebar
2. Click play button next to `SimplePipeline.Run_TwoSequentialTasks_ReturnsTwo`

**Terminal:**
```bash
ctest --test-dir build-tdd-tsan -R SimplePipeline --output-on-failure
```

Expected output:

```
    Start 1: SimplePipeline.Run_TwoSequentialTasks_ReturnsTwo
1/1 Test #1: SimplePipeline.Run_TwoSequentialTasks_ReturnsTwo   Passed    0.01 sec

100% tests passed, 0 tests failed out of 1
```

**GREEN PHASE COMPLETE**: The test passes.

### 2.5: Commit GREEN Phase

```bash
git add include/mylib/simple_pipeline.hpp
git add src/simple_pipeline.cpp
git commit -m "Green: Implement SimplePipeline with Taskflow

Minimal implementation using tf::Executor and tf::Taskflow.
Creates two tasks that increment an atomic counter. Uses
task_a.precede(task_b) to ensure sequential execution.

All tests pass."
```

---

## Phase 3: REFACTOR - Improve Code Quality

With a passing test, we can now improve the code. The test ensures we do not break functionality.

**Important:** Refactoring means restructuring code **without changing its external behavior**. We will only add task names for debugging and documentation comments. Adding new methods like `counter()` would be new functionality, which requires its own TDD cycle (covered in Phase 4).

### 3.1: Identify Improvements

Review the current implementation for refactoring opportunities:

- [ ] No task names for debugging
- [ ] No documentation comments

### 3.2: Update Header

Add documentation comments to `include/mylib/simple_pipeline.hpp` (no new methods):

```cpp
#ifndef MYLIB_SIMPLE_PIPELINE_HPP
#define MYLIB_SIMPLE_PIPELINE_HPP

#include <atomic>

namespace mylib {

/// A simple two-task pipeline demonstrating Taskflow basics.
/// Task A runs before Task B, each incrementing a shared counter.
class SimplePipeline {
 public:
  SimplePipeline();

  /// Execute the pipeline and return the final counter value.
  /// @return Counter value after both tasks complete (always 2 on first run)
  int Run();

 private:
  std::atomic<int> counter_;
};

}  // namespace mylib

#endif  // MYLIB_SIMPLE_PIPELINE_HPP
```

### 3.3: Update Implementation

Add task names to `src/simple_pipeline.cpp` for debugging (chain `.name()` after `emplace()`):

```cpp
#include "mylib/simple_pipeline.hpp"

#include <taskflow/taskflow.hpp>

namespace mylib {

SimplePipeline::SimplePipeline() : counter_(0) {}

int SimplePipeline::Run() {
  tf::Executor executor;
  tf::Taskflow taskflow;

  auto task_a = taskflow.emplace([this]() {
    counter_.fetch_add(1, std::memory_order_relaxed);
  }).name("TaskA");

  auto task_b = taskflow.emplace([this]() {
    counter_.fetch_add(1, std::memory_order_relaxed);
  }).name("TaskB");

  task_a.precede(task_b);
  executor.run(taskflow).wait();

  return counter_.load(std::memory_order_relaxed);
}

}  // namespace mylib
```

### 3.4: Verify Existing Test Still Passes

**VSCode:**
1. Press `Ctrl+Shift+P` → "CMake: Build", or click **Build** in the bottom status bar
2. Click Testing icon → play button next to `SimplePipeline`

**Terminal:**
```bash
cmake --build build-tdd-tsan
ctest --test-dir build-tdd-tsan -R SimplePipeline --output-on-failure
```

Expected: Test still passes. Refactoring must not break existing functionality.

**REFACTOR PHASE COMPLETE**: Code improved with task names and documentation, existing test still passes.

### 3.5: Commit REFACTOR Phase

```bash
git add include/mylib/simple_pipeline.hpp
git add src/simple_pipeline.cpp
git commit -m "Refactor: Add task names and documentation to SimplePipeline

- Added task names (TaskA, TaskB) for Taskflow debugging
- Added documentation comments to class and methods

No behavior changes. Existing test still passes."
```

---

## Phase 4: Add Observability Feature

Now we'll add new functionality (`counter()` and `Reset()` methods) using a proper TDD cycle. This demonstrates how to add features to existing code.

**Note:** Adding new methods is **not refactoring** - it's new functionality that requires RED-GREEN-REFACTOR.

### 4.1: Identify New Feature

We want to add observability to `SimplePipeline`:

- `counter()` - observe counter value without running the pipeline
- `Reset()` - reset counter for reuse

### 4.2: Write Tests First (RED)

Add tests for the new methods to `tests/simple_pipeline_test.cpp`:

```cpp
#include <gtest/gtest.h>
#include "mylib/simple_pipeline.hpp"

namespace mylib {
namespace {

TEST(SimplePipeline, Run_TwoSequentialTasks_ReturnsTwo) {
  // Arrange
  SimplePipeline pipeline;

  // Act
  int result = pipeline.Run();

  // Assert
  EXPECT_EQ(result, 2);
}

TEST(SimplePipeline, counter_BeforeRun_ReturnsZero) {
  // Arrange
  SimplePipeline pipeline;

  // Act
  int result = pipeline.counter();

  // Assert
  EXPECT_EQ(result, 0);
}

TEST(SimplePipeline, counter_AfterRun_ReturnsTwo) {
  // Arrange
  SimplePipeline pipeline;
  pipeline.Run();

  // Act
  int result = pipeline.counter();

  // Assert
  EXPECT_EQ(result, 2);
}

TEST(SimplePipeline, Reset_AfterRun_ClearsCounter) {
  // Arrange
  SimplePipeline pipeline;
  pipeline.Run();

  // Act
  pipeline.Reset();

  // Assert
  EXPECT_EQ(pipeline.counter(), 0);
}

TEST(SimplePipeline, Run_CalledTwice_Accumulates) {
  // Arrange
  SimplePipeline pipeline;

  // Act
  pipeline.Run();
  pipeline.Run();

  // Assert
  EXPECT_EQ(pipeline.counter(), 4);
}

TEST(SimplePipeline, Run_AfterReset_StartsFromZero) {
  // Arrange
  SimplePipeline pipeline;
  pipeline.Run();
  pipeline.Reset();

  // Act
  int result = pipeline.Run();

  // Assert
  EXPECT_EQ(result, 2);
}

}  // namespace
}  // namespace mylib
```

### 4.3: Attempt to Build (Expect Failure)

**VSCode:**
1. Press `Ctrl+Shift+P` → "CMake: Build", or click **Build** in the bottom status bar

**Terminal:**
```bash
cmake --build build-tdd-tsan
```

Expected error:

```
error: no member named 'counter' in 'mylib::SimplePipeline'
error: no member named 'Reset' in 'mylib::SimplePipeline'
```

**RED PHASE**: Tests fail to compile because the methods don't exist yet.

### 4.4: Add Method Declarations and Stubs

Update `include/mylib/simple_pipeline.hpp` to add the declarations:

```cpp
#ifndef MYLIB_SIMPLE_PIPELINE_HPP
#define MYLIB_SIMPLE_PIPELINE_HPP

#include <atomic>

namespace mylib {

/// A simple two-task pipeline demonstrating Taskflow basics.
/// Task A runs before Task B, each incrementing a shared counter.
class SimplePipeline {
 public:
  SimplePipeline();

  /// Execute the pipeline and return the final counter value.
  /// @return Counter value after both tasks complete (always 2 on first run)
  int Run();

  /// Get current counter value without running the pipeline.
  /// @return Current counter value
  int counter() const;

  /// Reset counter to zero for reuse.
  void Reset();

 private:
  std::atomic<int> counter_;
};

}  // namespace mylib

#endif  // MYLIB_SIMPLE_PIPELINE_HPP
```

Update `src/simple_pipeline.cpp` to add stub implementations:

```cpp
#include "mylib/simple_pipeline.hpp"

#include <taskflow/taskflow.hpp>

namespace mylib {

SimplePipeline::SimplePipeline() : counter_(0) {}

int SimplePipeline::Run() {
  tf::Executor executor;
  tf::Taskflow taskflow;

  auto task_a = taskflow.emplace([this]() {
    counter_.fetch_add(1, std::memory_order_relaxed);
  }).name("TaskA");

  auto task_b = taskflow.emplace([this]() {
    counter_.fetch_add(1, std::memory_order_relaxed);
  }).name("TaskB");

  task_a.precede(task_b);
  executor.run(taskflow).wait();

  return counter_.load(std::memory_order_relaxed);
}

int SimplePipeline::counter() const {
  return -1;  // Intentionally wrong - tests will fail
}

void SimplePipeline::Reset() {
  // Intentionally empty - tests will fail
}

}  // namespace mylib
```

### 4.5: Build and Run Tests (Expect Failure)

**VSCode:**
1. Press `Ctrl+Shift+P` → "CMake: Build", or click **Build** in the bottom status bar
2. Click Testing icon → refresh button to discover new tests
3. Click play button to run all tests

**Terminal:**
```bash
cmake --build build-tdd-tsan
ctest --test-dir build-tdd-tsan -R SimplePipeline --output-on-failure
```

Expected: Build succeeds, but new tests fail (counter returns -1, Reset does nothing).

**RED PHASE COMPLETE**: Tests fail for the right reasons.

### 4.6: Commit RED Phase

```bash
git add tests/simple_pipeline_test.cpp
git add include/mylib/simple_pipeline.hpp
git add src/simple_pipeline.cpp
git commit -m "Red: Add tests for counter and Reset methods

Tests for observability feature:
- counter() returns current counter value
- Reset clears counter to zero
- Multiple runs accumulate
- Reset allows fresh start

Currently failing with stub implementations."
```

### 4.7: Implement Methods (GREEN)

Update `src/simple_pipeline.cpp` with correct implementations:

```cpp
int SimplePipeline::counter() const {
  return counter_.load(std::memory_order_relaxed);
}

void SimplePipeline::Reset() {
  counter_.store(0, std::memory_order_relaxed);
}
```

### 4.8: Build and Run Tests (Expect Pass)

**VSCode:**
1. Press `Ctrl+Shift+P` → "CMake: Build", or click **Build** in the bottom status bar
2. Click Testing icon → play button next to `SimplePipeline` to run all 6 tests

**Terminal:**
```bash
cmake --build build-tdd-tsan
ctest --test-dir build-tdd-tsan -R SimplePipeline --output-on-failure
```

Expected output:

```
Test project /path/to/build-tdd-tsan
    Start 1: SimplePipeline.Run_TwoSequentialTasks_ReturnsTwo
1/6 Test #1: SimplePipeline.Run_TwoSequentialTasks_ReturnsTwo   Passed
    Start 2: SimplePipeline.counter_BeforeRun_ReturnsZero
2/6 Test #2: SimplePipeline.counter_BeforeRun_ReturnsZero   Passed
    Start 3: SimplePipeline.counter_AfterRun_ReturnsTwo
3/6 Test #3: SimplePipeline.counter_AfterRun_ReturnsTwo   Passed
    Start 4: SimplePipeline.Reset_AfterRun_ClearsCounter
4/6 Test #4: SimplePipeline.Reset_AfterRun_ClearsCounter   Passed
    Start 5: SimplePipeline.Run_CalledTwice_Accumulates
5/6 Test #5: SimplePipeline.Run_CalledTwice_Accumulates   Passed
    Start 6: SimplePipeline.Run_AfterReset_StartsFromZero
6/6 Test #6: SimplePipeline.Run_AfterReset_StartsFromZero   Passed

100% tests passed, 0 tests failed out of 6
```

**GREEN PHASE COMPLETE**: All tests pass.

### 4.9: Commit GREEN Phase

```bash
git add src/simple_pipeline.cpp
git commit -m "Green: Implement counter and Reset methods

- counter() returns counter value using atomic load
- Reset stores zero to counter using atomic store

All 6 tests pass."
```

**Note:** No refactoring needed for this simple implementation. In more complex cases, you would review the code and refactor if improvements are possible, then commit with a "Refactor:" prefix.

---

## Phase 5: Verify VSCode Integration

Before cleaning up, verify that VSCode Test Explorer works correctly with your tests.

### 5.1: Refresh Test Explorer

1. Open VSCode in the project directory (if not already open)
2. Click the Testing icon in the sidebar (beaker icon)
3. Click the refresh button at the top of Test Explorer

### 5.2: Verify Test Discovery

You should see:

```
mylib_tests
├── SimplePipeline
│   ├── Run_TwoSequentialTasks_ReturnsTwo
│   ├── counter_BeforeRun_ReturnsZero
│   ├── counter_AfterRun_ReturnsTwo
│   ├── Reset_AfterRun_ClearsCounter
│   ├── Run_CalledTwice_Accumulates
│   └── Run_AfterReset_StartsFromZero
└── (other existing tests)
```

### 5.3: Test Features

Try each of these actions:

| Action | How | Expected Result |
|--------|-----|-----------------|
| Run all tests | Click play button at top of Test Explorer | All tests show green checkmarks |
| Run single test | Click play button next to a test name | Only that test runs |
| Run test suite | Click play button next to "SimplePipeline" | All 6 SimplePipeline tests run |
| View output | Click a test, then click output icon | Test output displayed |
| Go to source | Double-click a test name | Editor opens test file at that test |

### 5.4: Test Debugging

1. Set a breakpoint in `src/simple_pipeline.cpp` inside the `Run()` method
2. In Test Explorer, click the debug icon (bug) next to any test
3. Debugger should launch and stop at your breakpoint
4. Step through code to verify debugging works

**Troubleshooting:** If you see "No launch configurations found", the `.vscode/` configuration files may be missing or corrupted. Restore them:

1. Create `.vscode/settings.json`:
```json
{
    "testMate.cpp.debug.configTemplate": {
        "type": "cppdbg",
        "linux": { "type": "cppdbg", "MIMode": "gdb" },
        "darwin": { "type": "cppdbg", "MIMode": "lldb" },
        "program": "${exec}",
        "args": "${argsArray}",
        "cwd": "${cwd}",
        "env": "${envObj}",
        "environment": "${envObjArray}"
    }
}
```

2. Create `.vscode/launch.json`:
```json
{
    "version": "0.2.0",
    "configurations": [
        {
            "name": "C++ Debug",
            "type": "cppdbg",
            "request": "launch",
            "program": "${workspaceFolder}/build-tdd-tsan/tests/mylib_tests",
            "args": [],
            "cwd": "${workspaceFolder}",
            "stopAtEntry": false,
            "environment": [],
            "MIMode": "gdb",
            "setupCommands": [
                {
                    "description": "Enable pretty-printing",
                    "text": "-enable-pretty-printing",
                    "ignoreFailures": true
                }
            ]
        }
    ]
}
```

3. Reload VSCode: `Ctrl+Shift+P` → "Developer: Reload Window"

### 5.5: Test Failure Navigation

1. Temporarily break a test by changing an expected value:
   ```cpp
   EXPECT_EQ(result, 99);  // Wrong value
   ```
2. Save the file
3. Run tests from VSCode
4. Click on the failed test
5. Verify it navigates to the failing line
6. **Revert the change** before continuing

---

## Phase 6: Test with Address Sanitizer (Optional)

You have been developing with `tdd-tsan` (Thread Sanitizer) which catches race conditions. Before finalizing, it's good practice to also run with `tdd-asan` (Address Sanitizer) to catch memory errors.

### 6.1: Build with Address Sanitizer

**VSCode:**
1. Open the CMake pane (click CMake icon in sidebar)
2. Under **Configure**, click the current preset (e.g., "TDD with Thread Sanitizer")
3. Select `tdd-asan` from the dropdown
4. VSCode reconfigures automatically
5. Under **Build**, click the build icon or press `F7`

Or: `Ctrl+Shift+P` → "CMake: Select Configure Preset" → `tdd-asan`

**Terminal:**
```bash
cmake --preset tdd-asan
cmake --build build-tdd-asan
```

> **Note:** Terminal commands and VSCode CMake Tools have independent state. If you switch presets via terminal, the VSCode UI won't update (and vice versa). Pick one method for consistency.

### 6.2: Run Tests

**VSCode:**
1. Click Testing icon (beaker) in the sidebar
2. Run the `SimplePipeline` tests

**Terminal:**
```bash
ctest --test-dir build-tdd-asan -R SimplePipeline --output-on-failure
```

Expected: All tests pass with no sanitizer warnings.

### 6.3: When to Use Each Preset

| Preset | Best For |
|--------|----------|
| `tdd-tsan` | Daily development with Taskflow (catches race conditions) |
| `tdd-asan` | Before commits, CI (catches memory errors + coverage) |

**Note:** You cannot run both sanitizers simultaneously - they are mutually exclusive. Switch between them as needed.

---

## Phase 7: Cleanup

This was a learning exercise. Delete the branch to clean up.

### 7.1: Return to Main Branch

```bash
git checkout main
```

### 7.2: Delete the Feature Branch

```bash
git branch -D feature/primer-exercise
```

The `-D` flag force-deletes the branch even though it was not merged.

### 7.3: Verify Cleanup

```bash
git branch
```

Expected: Only `main` (and any other real branches) listed.

---

## Summary: What You Learned

### TDD Workflow

| Phase | Purpose | Commit Prefix |
|-------|---------|---------------|
| RED | Write failing test first | `Red:` |
| GREEN | Minimal code to pass test | `Green:` |
| REFACTOR | Improve code quality | `Refactor:` |

### Key Commands

| Task | Command |
|------|---------|
| Configure (TDD) | `cmake --preset tdd-tsan` |
| Build | `cmake --build build-tdd-tsan` |
| Run all tests | `ctest --test-dir build-tdd-tsan --output-on-failure` |
| Run specific tests | `ctest --test-dir build-tdd-tsan -R PatternName` |
| Switch to ASan | `cmake --preset tdd-asan && cmake --build build-tdd-asan` |
| Release build | `cmake --preset release && cmake --build build-release` |

### Test Naming Convention

```
TEST(ClassName, Method_Scenario_ExpectedBehavior)
```

Examples:
- `SimplePipeline_Run_TwoSequentialTasks_ReturnsTwo`
- `SimplePipeline_counter_BeforeRun_ReturnsZero`
- `SimplePipeline_Reset_AfterRun_ClearsCounter`

### Files Modified During TDD

| File | Purpose |
|------|---------|
| `tests/<name>_test.cpp` | Test file |
| `tests/CMakeLists.txt` | Add test file to build |
| `include/mylib/<name>.hpp` | Header (class declaration) |
| `src/<name>.cpp` | Implementation |
| `src/CMakeLists.txt` | Add source file to library |

---

## Next Steps

You are now ready to develop real features. When starting a new feature:

1. Create a feature branch: `git checkout -b feature/<name>`
2. Use `/tdd-new <feature>` to create a TDD task file
3. Follow the Red-Green-Refactor cycle
4. Use `/tdd-test` to run tests with phase context
5. Update `CHANGELOG.md` before final commit
6. Create a pull request to `main`

### Reference Documentation

| Document | Purpose |
|----------|---------|
| `context/standards/cpp-tdd.md` | TDD workflow details |
| `context/standards/taskflow-testing-patterns.md` | Taskflow-specific test patterns |
| `context/standards/taskflow-reference.md` | Taskflow API reference |
| `context/standards/cpp-commits.md` | Commit message conventions |
| `.claude/commands/tdd-workflow.md` | Full TDD workflow command |

### TDD Slash Commands

| Command | Purpose |
|---------|---------|
| `/tdd-new <feature>` | Create TDD task file for new feature |
| `/tdd-test` | Run tests with phase context |
| `/tdd-workflow <task>` | Execute full guided TDD workflow |
