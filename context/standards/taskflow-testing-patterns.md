# Taskflow Testing Patterns Reference

Reference catalog of unit test patterns from Taskflow's test suite for TDD development.

## Overview

Taskflow uses **doctest** for testing. This catalog documents testing patterns that can be adapted to any framework.

**Doctest Basics:**
```cpp
#define DOCTEST_CONFIG_IMPLEMENT_WITH_MAIN
#include <doctest.h>
#include <taskflow/taskflow.hpp>

TEST_CASE("TestName" * doctest::timeout(300)) {
  // Test body
  REQUIRE(condition);
}

TEST_CASE("TestWithSubcases") {
  SUBCASE("Variation1") { /* ... */ }
  SUBCASE("Variation2") { /* ... */ }
}
```

**Key Assertions:**
| Assertion | Purpose |
|-----------|---------|
| `REQUIRE(cond)` | Assert condition is true |
| `REQUIRE_NOTHROW(expr)` | Assert no exception thrown |
| `REQUIRE_THROWS_WITH_AS(expr, msg, type)` | Assert specific exception |

---

## Test Setup Patterns

### Basic Executor and Taskflow

```cpp
tf::Executor executor;        // Default: hardware concurrency
tf::Taskflow taskflow;

// Or specify thread count
tf::Executor executor(4);     // 4 worker threads
```

### Thread Count Parameterization

Test same logic across different thread counts:

```cpp
void test_feature(unsigned W) {
  tf::Executor executor(W);
  tf::Taskflow taskflow;

  // ... test implementation

  executor.run(taskflow).wait();
  REQUIRE(result == expected);
}

TEST_CASE("Feature.1thread") { test_feature(1); }
TEST_CASE("Feature.2threads") { test_feature(2); }
TEST_CASE("Feature.4threads") { test_feature(4); }
TEST_CASE("Feature.8threads") { test_feature(8); }
```

### Reusable Taskflow Pattern

```cpp
for(int iteration = 0; iteration < 100; iteration++) {
  taskflow.clear();  // Reset for reuse

  // ... rebuild tasks

  executor.run(taskflow).wait();
}
```

---

## Core Patterns

### Task Creation and Dependencies

```cpp
// Static task (void callable)
auto A = taskflow.emplace([&]{ /* work */ });

// Named task
auto B = taskflow.emplace([&]{ /* work */ }).name("TaskB");

// Dependencies
A.precede(B);           // A runs before B
B.succeed(A);           // Equivalent

// Fan-out (broadcast)
A.precede(B, C, D);     // A before all of B, C, D

// Fan-in (join)
A.precede(D);
B.precede(D);
C.precede(D);           // D waits for A, B, C
```

**Verification:**
```cpp
REQUIRE(taskflow.num_tasks() == 4);
REQUIRE(A.num_successors() == 3);
REQUIRE(D.num_predecessors() == 3);
```

### Subflow Testing

```cpp
std::atomic<int> counter{0};

auto subflow_task = taskflow.emplace([&](tf::Subflow& sf) {
  counter++;

  auto sub_a = sf.emplace([&]{ counter++; });
  auto sub_b = sf.emplace([&]{ counter++; });
  sub_a.precede(sub_b);

  // Implicit join at lambda end
});

executor.run(taskflow).wait();
REQUIRE(counter == 3);
```

**Nested Subflows:**
```cpp
taskflow.emplace([&](tf::Subflow& sf1) {
  sf1.emplace([&](tf::Subflow& sf2) {
    sf2.emplace([&](tf::Subflow& sf3) {
      // Deep nesting supported
    });
  });
});
```

### Conditional Tasking

```cpp
int counter = 0;

auto init = taskflow.emplace([&]{ counter = 0; });

auto cond = taskflow.emplace([&]() -> int {
  return (++counter < 5) ? 0 : 1;  // 0=loop, 1=exit
});

auto body = taskflow.emplace([&]{ /* loop body */ });
auto done = taskflow.emplace([&]{ /* exit */ });

init.precede(cond);
cond.precede(body, done);  // 0->body, 1->done
body.precede(cond);        // Loop back

executor.run(taskflow).wait();
REQUIRE(counter == 5);
```

### Async Tasks

```cpp
std::vector<std::future<int>> futures;
std::atomic<int> counter{0};

// Async with return value
futures.push_back(executor.async([&]{
  counter++;
  return 42;
}));

// Silent async (no return)
executor.silent_async([&]{ counter++; });

// Wait for all
executor.wait_for_all();

REQUIRE(counter == 2);
REQUIRE(futures[0].get() == 42);
```

**Nested Async:**
```cpp
executor.async([&]{
  executor.async([&]{
    executor.async([&]{
      counter++;
    });
  });
});
executor.wait_for_all();
```

---

## Algorithm Patterns

### for_each Testing

```cpp
template <typename P>
void test_for_each(unsigned W) {
  tf::Executor executor(W);
  tf::Taskflow taskflow;

  std::vector<int> vec(1000, 0);
  std::atomic<int> counter{0};

  // Test varying sizes and chunk counts
  for(size_t n = 0; n <= 100; n++) {
    for(size_t c : {0, 1, 3, 7, 99}) {
      taskflow.clear();
      counter = 0;

      // Index-based
      taskflow.for_each_index(0, (int)n, 1,
        [&](int i){ counter++; vec[i] = i; },
        P(c)
      );

      executor.run(taskflow).wait();
      REQUIRE(counter == n);
    }
  }
}

// Instantiate with partitioners
TEST_CASE("ForEach.Guided") { test_for_each<tf::GuidedPartitioner<>>(4); }
TEST_CASE("ForEach.Static") { test_for_each<tf::StaticPartitioner<>>(4); }
TEST_CASE("ForEach.Dynamic") { test_for_each<tf::DynamicPartitioner<>>(4); }
```

### reduce Testing

```cpp
template <typename P>
void test_reduce(unsigned W) {
  tf::Executor executor(W);
  tf::Taskflow taskflow;

  std::vector<int> data(1000);
  for(auto& d : data) d = rand() % 100;

  int sequential_sum = 0;
  for(auto& d : data) sequential_sum += d;

  int parallel_sum = 0;
  taskflow.reduce(data.begin(), data.end(), parallel_sum,
    [](int a, int b){ return a + b; },
    P()
  );

  executor.run(taskflow).wait();
  REQUIRE(parallel_sum == sequential_sum);
}
```

### sort Testing

```cpp
void test_sort(unsigned W, size_t N) {
  tf::Executor executor(W);
  tf::Taskflow taskflow;

  std::vector<int> data(N);
  for(auto& d : data) d = rand() % 1000 - 500;

  taskflow.sort(data.begin(), data.end());

  executor.run(taskflow).wait();
  REQUIRE(std::is_sorted(data.begin(), data.end()));
}

// Custom comparator
taskflow.sort(data.begin(), data.end(),
  [](const auto& a, const auto& b){ return a.value < b.value; }
);
```

### transform Testing

```cpp
template <typename P>
void test_transform(unsigned W) {
  tf::Executor executor(W);
  tf::Taskflow taskflow;

  std::vector<int> src(1000);
  std::vector<std::string> dst(1000);

  for(size_t i = 0; i < src.size(); i++) src[i] = i;

  taskflow.transform(src.begin(), src.end(), dst.begin(),
    [](int x){ return std::to_string(x * 2); },
    P()
  );

  executor.run(taskflow).wait();

  for(size_t i = 0; i < src.size(); i++) {
    REQUIRE(dst[i] == std::to_string(src[i] * 2));
  }
}
```

### scan Testing

```cpp
void test_inclusive_scan(unsigned W) {
  tf::Executor executor(W);
  tf::Taskflow taskflow;

  std::vector<int> input = {1, 2, 3, 4, 5};
  std::vector<int> output(5);

  taskflow.inclusive_scan(input.begin(), input.end(), output.begin(),
    [](int a, int b){ return a + b; }
  );

  executor.run(taskflow).wait();

  // Expected: [1, 3, 6, 10, 15]
  REQUIRE(output == std::vector<int>{1, 3, 6, 10, 15});
}
```

---

## Pipeline Patterns

### Basic Pipeline

```cpp
void test_pipeline(unsigned W) {
  tf::Executor executor(W);
  tf::Taskflow taskflow;

  std::atomic<int> counter{0};

  tf::Pipeline pl(4,  // 4 parallel lines
    tf::Pipe{tf::PipeType::SERIAL, [&](tf::Pipeflow& pf){
      if(pf.token() == 10) {
        pf.stop();
        return;
      }
      counter++;
    }},
    tf::Pipe{tf::PipeType::PARALLEL, [&](tf::Pipeflow& pf){
      counter++;
    }},
    tf::Pipe{tf::PipeType::SERIAL, [&](tf::Pipeflow& pf){
      counter++;
    }}
  );

  taskflow.composed_of(pl);
  executor.run(taskflow).wait();

  REQUIRE(counter == 30);  // 10 tokens * 3 stages
}
```

---

## Verification Patterns

### Atomic Counter Pattern

Verify all tasks executed:

```cpp
std::atomic<size_t> counter{0};

for(int i = 0; i < 100; i++) {
  taskflow.emplace([&]{
    counter.fetch_add(1, std::memory_order_relaxed);
  });
}

executor.run(taskflow).wait();
REQUIRE(counter == 100);
```

### State Ordering Pattern

Verify sequential dependencies:

```cpp
int state = 0;

auto A = taskflow.emplace([&]{
  REQUIRE(state == 0);
  state = 1;
});

auto B = taskflow.emplace([&]{
  REQUIRE(state == 1);
  state = 2;
});

auto C = taskflow.emplace([&]{
  REQUIRE(state == 2);
  state = 3;
});

A.precede(B);
B.precede(C);

executor.run(taskflow).wait();
REQUIRE(state == 3);
```

### Data Correctness Pattern

Verify algorithm results:

```cpp
// Compare parallel with sequential
int seq_result = 0;
for(auto& x : data) seq_result += x;

int par_result = 0;
taskflow.reduce(data.begin(), data.end(), par_result, std::plus<int>());
executor.run(taskflow).wait();

REQUIRE(par_result == seq_result);
```

### Exception Handling Pattern

```cpp
auto throwing_task = taskflow.emplace([]{
  throw std::runtime_error("test error");
});

REQUIRE_THROWS_WITH_AS(
  executor.run(taskflow).get(),
  "test error",
  std::runtime_error
);
```

**Partial Execution on Exception:**
```cpp
std::atomic<int> counter{0};

auto A = taskflow.emplace([&]{ counter++; });
auto B = taskflow.emplace([&]{ counter++; throw std::runtime_error("x"); });
auto C = taskflow.emplace([&]{ counter++; });

A.precede(B);
B.precede(C);

REQUIRE_THROWS(executor.run(taskflow).get());
REQUIRE(counter == 2);  // A and B ran, C did not
```

---

## Edge Cases

### Empty Taskflow

```cpp
tf::Taskflow taskflow;
tf::Executor executor;

REQUIRE(taskflow.empty());
REQUIRE(taskflow.num_tasks() == 0);

executor.run(taskflow).wait();  // Should not crash
```

### Single Task

```cpp
int value = 0;
taskflow.emplace([&]{ value = 42; });

REQUIRE(taskflow.num_tasks() == 1);
executor.run(taskflow).wait();
REQUIRE(value == 42);
```

### Placeholder Tasks

```cpp
std::vector<tf::Task> tasks;

for(int i = 0; i < 100; i++) {
  tasks.push_back(taskflow.placeholder().name(std::to_string(i)));
}

// Verify placeholders exist
for(int i = 0; i < 100; i++) {
  REQUIRE(tasks[i].name() == std::to_string(i));
}

// Assign work later
int counter = 0;
for(auto& t : tasks) {
  t.work([&]{ counter++; });
}

executor.run(taskflow).wait();
REQUIRE(counter == 100);
```

### Move-Only Types

```cpp
struct MoveOnly {
  int value;
  MoveOnly(int v) : value(v) {}
  MoveOnly(const MoveOnly&) = delete;
  MoveOnly(MoveOnly&&) = default;
};

std::vector<MoveOnly> data;
for(int i = 0; i < 1000; i++) data.emplace_back(rand() % 100);

taskflow.sort(data.begin(), data.end(),
  [](const MoveOnly& a, const MoveOnly& b){
    return a.value < b.value;
  }
);

executor.run(taskflow).wait();

for(size_t i = 1; i < data.size(); i++) {
  REQUIRE(data[i-1].value <= data[i].value);
}
```

### Stress Test Pattern

```cpp
void stress_test(unsigned W) {
  tf::Executor executor(W);
  tf::Taskflow taskflow;

  std::atomic<int> counter{0};
  const int N = 100000;

  for(int i = 0; i < N; i++) {
    taskflow.emplace([&]{
      counter.fetch_add(1, std::memory_order_relaxed);
    });
  }

  executor.run(taskflow).wait();
  REQUIRE(counter == N);
}
```

---

## Quick Reference

### Task Types

| Type | Signature | Detection |
|------|-----------|-----------|
| Static | `void()` | `tf::TaskType::STATIC` |
| Condition | `int()` | `tf::TaskType::CONDITION` |
| Subflow | `void(tf::Subflow&)` | `tf::TaskType::SUBFLOW` |
| Runtime | `void(tf::Runtime&)` | `tf::TaskType::RUNTIME` |

### Partitioners

| Partitioner | Use Case |
|-------------|----------|
| `tf::GuidedPartitioner<>` | General purpose, good load balancing |
| `tf::StaticPartitioner<>` | Uniform work, predictable |
| `tf::DynamicPartitioner<>` | Variable work per element |
| `tf::RandomPartitioner<>` | Testing, debugging |

### Execution Methods

| Method | Description |
|--------|-------------|
| `executor.run(tf).wait()` | Run once, block |
| `executor.run(tf).get()` | Run once, block (throws on exception) |
| `executor.run_n(tf, N).wait()` | Run N times |
| `executor.run_until(tf, pred).wait()` | Run until predicate true |
| `executor.wait_for_all()` | Wait for all async tasks |

### Test Data Sizes

| Purpose | Sizes |
|---------|-------|
| Basic correctness | 0, 1, 10, 100 |
| Boundary testing | 0, 1, 2, 3, 7, 99 (chunk sizes) |
| Stress testing | 10000, 100000, 1000000 |
| Exponential sweep | 1, 2, 4, 8, ..., 65536 |

### Thread Counts

| Purpose | Values |
|---------|--------|
| Basic | 1, 2, 4 |
| Comprehensive | 1, 2, 3, 4, 5, 6, 7, 8 |
| Stress | 1, 2, 4, 8, 16, 32 |
