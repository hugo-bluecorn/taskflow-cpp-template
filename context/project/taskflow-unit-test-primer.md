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
| CMake | Adding test files to the build system |
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

```bash
cmake --preset tdd-tsan
cmake --build build-tdd-tsan
```

Expected: Build completes without errors.

### 0.3: Run Existing Tests

```bash
ctest --test-dir build-tdd-tsan --output-on-failure
```

Expected: All existing tests pass with no sanitizer warnings.

### 0.4: Open VSCode

```bash
code .
```

Verify:
- C++ TestMate extension is installed (check Extensions sidebar)
- Test Explorer shows existing tests (beaker icon in sidebar)

If any step fails, resolve the issue before continuing.

---

## Step 1: Create Feature Branch

All development happens on feature branches, never on `main`.

```bash
git checkout main
git pull
git checkout -b feature/primer-exercise
```

Verify you are on the new branch:

```bash
git branch --show-current
```

Expected output: `feature/primer-exercise`

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

### 1.4: Create Minimal Header Stub

Create `include/mylib/simple_pipeline.hpp` with just enough code to compile:

```cpp
#ifndef MYLIB_SIMPLE_PIPELINE_HPP
#define MYLIB_SIMPLE_PIPELINE_HPP

namespace mylib {

class SimplePipeline {
 public:
  int Run() {
    return 0;  // Intentionally wrong - test will fail
  }
};

}  // namespace mylib

#endif  // MYLIB_SIMPLE_PIPELINE_HPP
```

### 1.5: Build Again

```bash
cmake --build build-tdd-tsan
```

Expected: Build succeeds (no compile errors).

### 1.6: Run Test (Expect Failure)

```bash
ctest --test-dir build-tdd-tsan -R SimplePipeline --output-on-failure
```

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

### 1.7: Commit RED Phase

```bash
git add tests/simple_pipeline_test.cpp
git add tests/CMakeLists.txt
git add include/mylib/simple_pipeline.hpp
git commit -m "Red: Add test for SimplePipeline.Run

Test that SimplePipeline.Run returns 2 after executing two
sequential tasks. Currently fails with return value 0.

Establishes the contract: Run() must create two dependent
tasks and return the count after execution."
```

---

## Phase 2: GREEN - Minimal Implementation

Now we write the minimum code needed to make the test pass. No extra features, no optimization.

### 2.1: Implement SimplePipeline

Replace the contents of `include/mylib/simple_pipeline.hpp`:

```cpp
#ifndef MYLIB_SIMPLE_PIPELINE_HPP
#define MYLIB_SIMPLE_PIPELINE_HPP

#include <taskflow/taskflow.hpp>
#include <atomic>

namespace mylib {

class SimplePipeline {
 public:
  SimplePipeline() : counter_(0) {}

  int Run() {
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

 private:
  std::atomic<int> counter_;
};

}  // namespace mylib

#endif  // MYLIB_SIMPLE_PIPELINE_HPP
```

### 2.2: Build

```bash
cmake --build build-tdd-tsan
```

Expected: Build succeeds.

### 2.3: Run Test (Expect Pass)

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

### 2.4: Commit GREEN Phase

```bash
git add include/mylib/simple_pipeline.hpp
git commit -m "Green: Implement SimplePipeline with Taskflow

Minimal implementation using tf::Executor and tf::Taskflow.
Creates two tasks that increment an atomic counter. Uses
task_a.precede(task_b) to ensure sequential execution.

All tests pass."
```

---

## Phase 3: REFACTOR - Improve Code Quality

With a passing test, we can now improve the code. The test ensures we do not break functionality.

### 3.1: Identify Improvements

Review the current implementation:

- [ ] Missing `GetCounter()` method for observability
- [ ] Missing `Reset()` method for reusability
- [ ] No task names for debugging
- [ ] No documentation comments

### 3.2: Update Implementation

Replace the contents of `include/mylib/simple_pipeline.hpp`:

```cpp
#ifndef MYLIB_SIMPLE_PIPELINE_HPP
#define MYLIB_SIMPLE_PIPELINE_HPP

#include <taskflow/taskflow.hpp>
#include <atomic>

namespace mylib {

/// A simple two-task pipeline demonstrating Taskflow basics.
/// Task A runs before Task B, each incrementing a shared counter.
class SimplePipeline {
 public:
  SimplePipeline() : counter_(0) {}

  /// Execute the pipeline and return the final counter value.
  /// @return Counter value after both tasks complete (always 2 on first run)
  int Run() {
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

  /// Get current counter value without running the pipeline.
  /// @return Current counter value
  int GetCounter() const {
    return counter_.load(std::memory_order_relaxed);
  }

  /// Reset counter to zero for reuse.
  void Reset() {
    counter_.store(0, std::memory_order_relaxed);
  }

 private:
  std::atomic<int> counter_;
};

}  // namespace mylib

#endif  // MYLIB_SIMPLE_PIPELINE_HPP
```

### 3.3: Verify Existing Test Still Passes

```bash
cmake --build build-tdd-tsan
ctest --test-dir build-tdd-tsan -R SimplePipeline --output-on-failure
```

Expected: Test still passes. Refactoring must not break existing functionality.

### 3.4: Add Tests for New Methods

Update `tests/simple_pipeline_test.cpp`:

```cpp
#include <gtest/gtest.h>
#include "mylib/simple_pipeline.hpp"

namespace mylib {
namespace {

TEST(SimplePipeline, Run_TwoSequentialTasks_ReturnsTwo) {
  SimplePipeline pipeline;

  int result = pipeline.Run();

  EXPECT_EQ(result, 2);
}

TEST(SimplePipeline, GetCounter_BeforeRun_ReturnsZero) {
  SimplePipeline pipeline;

  int result = pipeline.GetCounter();

  EXPECT_EQ(result, 0);
}

TEST(SimplePipeline, GetCounter_AfterRun_ReturnsTwo) {
  SimplePipeline pipeline;
  pipeline.Run();

  int result = pipeline.GetCounter();

  EXPECT_EQ(result, 2);
}

TEST(SimplePipeline, Reset_AfterRun_ClearsCounter) {
  SimplePipeline pipeline;
  pipeline.Run();

  pipeline.Reset();

  EXPECT_EQ(pipeline.GetCounter(), 0);
}

TEST(SimplePipeline, Run_CalledTwice_Accumulates) {
  SimplePipeline pipeline;

  pipeline.Run();
  pipeline.Run();

  EXPECT_EQ(pipeline.GetCounter(), 4);
}

TEST(SimplePipeline, Run_AfterReset_StartsFromZero) {
  SimplePipeline pipeline;
  pipeline.Run();
  pipeline.Reset();

  int result = pipeline.Run();

  EXPECT_EQ(result, 2);
}

}  // namespace
}  // namespace mylib
```

### 3.5: Build and Run All Tests

```bash
cmake --build build-tdd-tsan
ctest --test-dir build-tdd-tsan -R SimplePipeline --output-on-failure
```

Expected output:

```
Test project /path/to/build-tdd-tsan
    Start 1: SimplePipeline.Run_TwoSequentialTasks_ReturnsTwo
1/6 Test #1: SimplePipeline.Run_TwoSequentialTasks_ReturnsTwo   Passed
    Start 2: SimplePipeline.GetCounter_BeforeRun_ReturnsZero
2/6 Test #2: SimplePipeline.GetCounter_BeforeRun_ReturnsZero   Passed
    Start 3: SimplePipeline.GetCounter_AfterRun_ReturnsTwo
3/6 Test #3: SimplePipeline.GetCounter_AfterRun_ReturnsTwo   Passed
    Start 4: SimplePipeline.Reset_AfterRun_ClearsCounter
4/6 Test #4: SimplePipeline.Reset_AfterRun_ClearsCounter   Passed
    Start 5: SimplePipeline.Run_CalledTwice_Accumulates
5/6 Test #5: SimplePipeline.Run_CalledTwice_Accumulates   Passed
    Start 6: SimplePipeline.Run_AfterReset_StartsFromZero
6/6 Test #6: SimplePipeline.Run_AfterReset_StartsFromZero   Passed

100% tests passed, 0 tests failed out of 6
```

**REFACTOR PHASE COMPLETE**: Code improved, all tests pass.

### 3.6: Commit REFACTOR Phase

```bash
git add include/mylib/simple_pipeline.hpp
git add tests/simple_pipeline_test.cpp
git commit -m "Refactor: Add observability and reuse to SimplePipeline

Improvements:
- Added GetCounter() for observing state without running
- Added Reset() for reusing the pipeline
- Added task names (TaskA, TaskB) for Taskflow debugging
- Added documentation comments

New tests verify:
- Initial counter is zero
- GetCounter reflects state after Run
- Reset clears counter
- Multiple runs accumulate
- Reset allows fresh start"
```

---

## Phase 4: Verify VSCode Integration

Before cleaning up, verify that VSCode Test Explorer works correctly with your tests.

### 4.1: Refresh Test Explorer

1. Open VSCode in the project directory (if not already open)
2. Click the Testing icon in the sidebar (beaker icon)
3. Click the refresh button at the top of Test Explorer

### 4.2: Verify Test Discovery

You should see:

```
mylib_tests
├── SimplePipeline
│   ├── Run_TwoSequentialTasks_ReturnsTwo
│   ├── GetCounter_BeforeRun_ReturnsZero
│   ├── GetCounter_AfterRun_ReturnsTwo
│   ├── Reset_AfterRun_ClearsCounter
│   ├── Run_CalledTwice_Accumulates
│   └── Run_AfterReset_StartsFromZero
└── (other existing tests)
```

### 4.3: Test Features

Try each of these actions:

| Action | How | Expected Result |
|--------|-----|-----------------|
| Run all tests | Click play button at top of Test Explorer | All tests show green checkmarks |
| Run single test | Click play button next to a test name | Only that test runs |
| Run test suite | Click play button next to "SimplePipeline" | All 6 SimplePipeline tests run |
| View output | Click a test, then click output icon | Test output displayed |
| Go to source | Double-click a test name | Editor opens test file at that test |

### 4.4: Test Debugging (Optional)

1. Set a breakpoint in `simple_pipeline.hpp` inside the `Run()` method
2. In Test Explorer, click the debug icon (bug) next to any test
3. Debugger should launch and stop at your breakpoint
4. Step through code to verify debugging works

### 4.5: Test Failure Navigation

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

## Phase 5: Test with Address Sanitizer (Optional)

You have been developing with `tdd-tsan` (Thread Sanitizer) which catches race conditions. Before finalizing, it's good practice to also run with `tdd-asan` (Address Sanitizer) to catch memory errors.

### 5.1: Build with Address Sanitizer

```bash
cmake --preset tdd-asan
cmake --build build-tdd-asan
```

### 5.2: Run Tests

```bash
ctest --test-dir build-tdd-asan -R SimplePipeline --output-on-failure
```

Expected: All tests pass with no sanitizer warnings.

### 5.3: When to Use Each Preset

| Preset | Best For |
|--------|----------|
| `tdd-tsan` | Daily development with Taskflow (catches race conditions) |
| `tdd-asan` | Before commits, CI (catches memory errors + coverage) |

**Note:** You cannot run both sanitizers simultaneously - they are mutually exclusive. Switch between them as needed.

---

## Phase 6: Cleanup

This was a learning exercise. Delete the branch to clean up.

### 6.1: Return to Main Branch

```bash
git checkout main
```

### 6.2: Delete the Feature Branch

```bash
git branch -D feature/primer-exercise
```

The `-D` flag force-deletes the branch even though it was not merged.

### 6.3: Verify Cleanup

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
- `SimplePipeline_GetCounter_BeforeRun_ReturnsZero`
- `SimplePipeline_Reset_AfterRun_ClearsCounter`

### Files Modified During TDD

| File | Purpose |
|------|---------|
| `tests/<name>_test.cpp` | Test file |
| `tests/CMakeLists.txt` | Add test file to build |
| `include/mylib/<name>.hpp` | Header (often header-only for simple classes) |
| `src/<name>.cpp` | Implementation (if not header-only) |

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
