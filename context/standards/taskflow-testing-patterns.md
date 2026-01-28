# Taskflow Testing Patterns Reference

Reference catalog of unit test patterns for TDD development with Taskflow using GoogleTest.

## Overview

This catalog provides GoogleTest patterns for testing Taskflow-based applications, derived from Taskflow's test suite.

**GoogleTest Basics:**
```cpp
#include <gtest/gtest.h>
#include <taskflow/taskflow.hpp>

TEST(SuiteName, TestName) {
    // Test body
    EXPECT_EQ(actual, expected);
}
```

**Key Assertions:**
| Assertion | Purpose |
|-----------|---------|
| `EXPECT_EQ(a, b)` | Non-fatal equality check |
| `ASSERT_EQ(a, b)` | Fatal equality check (stops test) |
| `EXPECT_TRUE(cond)` | Condition is true |
| `EXPECT_THROW(expr, type)` | Throws specific exception |
| `EXPECT_NO_THROW(expr)` | No exception thrown |

---

## Test Setup Patterns

### Basic Executor and Taskflow

```cpp
TEST(TaskflowTest, BasicSetup) {
    tf::Executor executor;        // Default: hardware concurrency
    tf::Taskflow taskflow;

    // Or specify thread count
    tf::Executor executor4(4);    // 4 worker threads
}
```

### Thread Count Parameterization

Test same logic across different thread counts:

```cpp
class TaskflowThreadTest : public ::testing::TestWithParam<unsigned> {};

TEST_P(TaskflowThreadTest, ExecutesCorrectly) {
    unsigned num_threads = GetParam();
    tf::Executor executor(num_threads);
    tf::Taskflow taskflow;

    std::atomic<int> counter{0};
    taskflow.emplace([&]{ counter++; });

    executor.run(taskflow).wait();
    EXPECT_EQ(counter, 1);
}

INSTANTIATE_TEST_SUITE_P(
    ThreadCounts,
    TaskflowThreadTest,
    ::testing::Values(1, 2, 4, 8)
);
```

### Test Fixture for Taskflow

```cpp
class TaskflowFixture : public ::testing::Test {
protected:
    void SetUp() override {
        counter = 0;
    }

    void TearDown() override {
        taskflow.clear();
    }

    tf::Executor executor{4};
    tf::Taskflow taskflow;
    std::atomic<int> counter{0};
};

TEST_F(TaskflowFixture, TasksExecute) {
    taskflow.emplace([this]{ counter++; });
    executor.run(taskflow).wait();
    EXPECT_EQ(counter, 1);
}
```

### Reusable Taskflow Pattern

```cpp
TEST(TaskflowTest, ReusableTaskflow) {
    tf::Executor executor(4);
    tf::Taskflow taskflow;
    std::atomic<int> counter{0};

    for(int iteration = 0; iteration < 100; iteration++) {
        taskflow.clear();  // Reset for reuse
        counter = 0;

        taskflow.emplace([&]{ counter++; });
        executor.run(taskflow).wait();

        EXPECT_EQ(counter, 1);
    }
}
```

---

## Core Patterns

### Task Creation and Dependencies

```cpp
TEST(TaskflowCore, TaskDependencies) {
    tf::Executor executor(4);
    tf::Taskflow taskflow;
    std::atomic<int> counter{0};

    // Static task (void callable)
    auto A = taskflow.emplace([&]{ counter++; });

    // Named task
    auto B = taskflow.emplace([&]{ counter++; }).name("TaskB");

    // Dependencies
    A.precede(B);           // A runs before B

    executor.run(taskflow).wait();
    EXPECT_EQ(counter, 2);
}

TEST(TaskflowCore, FanOutFanIn) {
    tf::Executor executor(4);
    tf::Taskflow taskflow;
    std::atomic<int> counter{0};

    auto A = taskflow.emplace([&]{ counter++; });
    auto B = taskflow.emplace([&]{ counter++; });
    auto C = taskflow.emplace([&]{ counter++; });
    auto D = taskflow.emplace([&]{ counter++; });

    // Fan-out: A before B, C, D
    A.precede(B, C, D);

    executor.run(taskflow).wait();
    EXPECT_EQ(counter, 4);

    // Verify graph structure
    EXPECT_EQ(taskflow.num_tasks(), 4);
    EXPECT_EQ(A.num_successors(), 3);
}
```

### Subflow Testing

```cpp
TEST(TaskflowCore, SubflowExecution) {
    tf::Executor executor(4);
    tf::Taskflow taskflow;
    std::atomic<int> counter{0};

    auto subflow_task = taskflow.emplace([&](tf::Subflow& sf) {
        counter++;

        auto sub_a = sf.emplace([&]{ counter++; });
        auto sub_b = sf.emplace([&]{ counter++; });
        sub_a.precede(sub_b);

        // Implicit join at lambda end
    });

    executor.run(taskflow).wait();
    EXPECT_EQ(counter, 3);
}

TEST(TaskflowCore, NestedSubflows) {
    tf::Executor executor(4);
    tf::Taskflow taskflow;
    std::atomic<int> counter{0};

    taskflow.emplace([&](tf::Subflow& sf1) {
        counter++;
        sf1.emplace([&](tf::Subflow& sf2) {
            counter++;
            sf2.emplace([&](tf::Subflow& sf3) {
                counter++;
            });
        });
    });

    executor.run(taskflow).wait();
    EXPECT_EQ(counter, 3);
}
```

### Conditional Tasking

```cpp
TEST(TaskflowCore, ConditionalLoop) {
    tf::Executor executor(4);
    tf::Taskflow taskflow;
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
    EXPECT_EQ(counter, 5);
}
```

### Async Tasks

```cpp
TEST(TaskflowCore, AsyncWithFuture) {
    tf::Executor executor(4);
    std::atomic<int> counter{0};

    // Async with return value
    auto future = executor.async([&]{
        counter++;
        return 42;
    });

    // Silent async (no return)
    executor.silent_async([&]{ counter++; });

    executor.wait_for_all();

    EXPECT_EQ(counter, 2);
    EXPECT_EQ(future.get(), 42);
}

TEST(TaskflowCore, NestedAsync) {
    tf::Executor executor(4);
    std::atomic<int> counter{0};

    executor.async([&]{
        counter++;
        executor.async([&]{
            counter++;
            executor.async([&]{
                counter++;
            });
        });
    });

    executor.wait_for_all();
    EXPECT_EQ(counter, 3);
}
```

---

## Algorithm Patterns

### for_each Testing

```cpp
TEST(TaskflowAlgorithm, ForEachIndex) {
    tf::Executor executor(4);
    tf::Taskflow taskflow;

    std::vector<int> vec(100, 0);
    std::atomic<int> counter{0};

    taskflow.for_each_index(0, 100, 1,
        [&](int i){
            counter++;
            vec[i] = i;
        }
    );

    executor.run(taskflow).wait();

    EXPECT_EQ(counter, 100);
    for(int i = 0; i < 100; i++) {
        EXPECT_EQ(vec[i], i);
    }
}

TEST(TaskflowAlgorithm, ForEachIterator) {
    tf::Executor executor(4);
    tf::Taskflow taskflow;

    std::vector<int> vec(100, 0);

    taskflow.for_each(vec.begin(), vec.end(),
        [](int& val){ val = 1; }
    );

    executor.run(taskflow).wait();

    for(const auto& val : vec) {
        EXPECT_EQ(val, 1);
    }
}

// Parameterized test for partitioners
class ForEachPartitionerTest : public ::testing::TestWithParam<size_t> {};

TEST_P(ForEachPartitionerTest, WithChunkSize) {
    size_t chunk_size = GetParam();
    tf::Executor executor(4);
    tf::Taskflow taskflow;

    std::vector<int> vec(1000, 0);
    std::atomic<int> counter{0};

    taskflow.for_each_index(0, 1000, 1,
        [&](int i){ counter++; vec[i] = i; },
        tf::GuidedPartitioner(chunk_size)
    );

    executor.run(taskflow).wait();
    EXPECT_EQ(counter, 1000);
}

INSTANTIATE_TEST_SUITE_P(
    ChunkSizes,
    ForEachPartitionerTest,
    ::testing::Values(0, 1, 3, 7, 99)
);
```

### reduce Testing

```cpp
TEST(TaskflowAlgorithm, ReduceSum) {
    tf::Executor executor(4);
    tf::Taskflow taskflow;

    std::vector<int> data(1000);
    for(size_t i = 0; i < data.size(); i++) {
        data[i] = static_cast<int>(i);
    }

    // Sequential baseline
    int sequential_sum = 0;
    for(const auto& d : data) sequential_sum += d;

    // Parallel reduce
    int parallel_sum = 0;
    taskflow.reduce(data.begin(), data.end(), parallel_sum,
        [](int a, int b){ return a + b; }
    );

    executor.run(taskflow).wait();
    EXPECT_EQ(parallel_sum, sequential_sum);
}

TEST(TaskflowAlgorithm, ReduceMin) {
    tf::Executor executor(4);
    tf::Taskflow taskflow;

    std::vector<int> data = {5, 2, 8, 1, 9, 3, 7, 4, 6};

    int min_val = std::numeric_limits<int>::max();
    taskflow.reduce(data.begin(), data.end(), min_val,
        [](int a, int b){ return std::min(a, b); }
    );

    executor.run(taskflow).wait();
    EXPECT_EQ(min_val, 1);
}
```

### sort Testing

```cpp
TEST(TaskflowAlgorithm, SortIntegers) {
    tf::Executor executor(4);
    tf::Taskflow taskflow;

    std::vector<int> data(10000);
    for(auto& d : data) d = rand() % 1000 - 500;

    taskflow.sort(data.begin(), data.end());

    executor.run(taskflow).wait();
    EXPECT_TRUE(std::is_sorted(data.begin(), data.end()));
}

TEST(TaskflowAlgorithm, SortWithComparator) {
    tf::Executor executor(4);
    tf::Taskflow taskflow;

    struct Item {
        int value;
        std::string name;
    };

    std::vector<Item> items = {
        {3, "c"}, {1, "a"}, {2, "b"}
    };

    taskflow.sort(items.begin(), items.end(),
        [](const Item& a, const Item& b){
            return a.value < b.value;
        }
    );

    executor.run(taskflow).wait();

    EXPECT_EQ(items[0].value, 1);
    EXPECT_EQ(items[1].value, 2);
    EXPECT_EQ(items[2].value, 3);
}
```

### transform Testing

```cpp
TEST(TaskflowAlgorithm, TransformToString) {
    tf::Executor executor(4);
    tf::Taskflow taskflow;

    std::vector<int> src = {1, 2, 3, 4, 5};
    std::vector<std::string> dst(5);

    taskflow.transform(src.begin(), src.end(), dst.begin(),
        [](int x){ return std::to_string(x * 2); }
    );

    executor.run(taskflow).wait();

    EXPECT_EQ(dst[0], "2");
    EXPECT_EQ(dst[1], "4");
    EXPECT_EQ(dst[2], "6");
    EXPECT_EQ(dst[3], "8");
    EXPECT_EQ(dst[4], "10");
}
```

### scan Testing

```cpp
TEST(TaskflowAlgorithm, InclusiveScan) {
    tf::Executor executor(4);
    tf::Taskflow taskflow;

    std::vector<int> input = {1, 2, 3, 4, 5};
    std::vector<int> output(5);

    taskflow.inclusive_scan(input.begin(), input.end(), output.begin(),
        [](int a, int b){ return a + b; }
    );

    executor.run(taskflow).wait();

    // Expected: [1, 3, 6, 10, 15]
    std::vector<int> expected = {1, 3, 6, 10, 15};
    EXPECT_EQ(output, expected);
}

TEST(TaskflowAlgorithm, ExclusiveScan) {
    tf::Executor executor(4);
    tf::Taskflow taskflow;

    std::vector<int> input = {1, 2, 3, 4, 5};
    std::vector<int> output(5);

    taskflow.exclusive_scan(input.begin(), input.end(), output.begin(),
        0,  // Initial value
        [](int a, int b){ return a + b; }
    );

    executor.run(taskflow).wait();

    // Expected: [0, 1, 3, 6, 10]
    std::vector<int> expected = {0, 1, 3, 6, 10};
    EXPECT_EQ(output, expected);
}
```

---

## Pipeline Patterns

### Basic Pipeline

```cpp
TEST(TaskflowPipeline, ThreeStages) {
    tf::Executor executor(4);
    tf::Taskflow taskflow;

    std::atomic<int> stage1_count{0};
    std::atomic<int> stage2_count{0};
    std::atomic<int> stage3_count{0};

    tf::Pipeline pl(4,  // 4 parallel lines
        tf::Pipe{tf::PipeType::SERIAL, [&](tf::Pipeflow& pf){
            if(pf.token() == 10) {
                pf.stop();
                return;
            }
            stage1_count++;
        }},
        tf::Pipe{tf::PipeType::PARALLEL, [&](tf::Pipeflow& pf){
            stage2_count++;
        }},
        tf::Pipe{tf::PipeType::SERIAL, [&](tf::Pipeflow& pf){
            stage3_count++;
        }}
    );

    taskflow.composed_of(pl);
    executor.run(taskflow).wait();

    EXPECT_EQ(stage1_count, 10);
    EXPECT_EQ(stage2_count, 10);
    EXPECT_EQ(stage3_count, 10);
}
```

---

## Verification Patterns

### Atomic Counter Pattern

Verify all tasks executed:

```cpp
TEST(Verification, AtomicCounter) {
    tf::Executor executor(4);
    tf::Taskflow taskflow;
    std::atomic<size_t> counter{0};

    for(int i = 0; i < 100; i++) {
        taskflow.emplace([&]{
            counter.fetch_add(1, std::memory_order_relaxed);
        });
    }

    executor.run(taskflow).wait();
    EXPECT_EQ(counter, 100);
}
```

### State Ordering Pattern

Verify sequential dependencies:

```cpp
TEST(Verification, StateOrdering) {
    tf::Executor executor(4);
    tf::Taskflow taskflow;
    int state = 0;

    auto A = taskflow.emplace([&]{
        EXPECT_EQ(state, 0);
        state = 1;
    });

    auto B = taskflow.emplace([&]{
        EXPECT_EQ(state, 1);
        state = 2;
    });

    auto C = taskflow.emplace([&]{
        EXPECT_EQ(state, 2);
        state = 3;
    });

    A.precede(B);
    B.precede(C);

    executor.run(taskflow).wait();
    EXPECT_EQ(state, 3);
}
```

### Data Correctness Pattern

Compare parallel with sequential:

```cpp
TEST(Verification, DataCorrectness) {
    tf::Executor executor(4);
    tf::Taskflow taskflow;

    std::vector<int> data(1000);
    for(size_t i = 0; i < data.size(); i++) {
        data[i] = static_cast<int>(i);
    }

    // Sequential baseline
    int seq_result = 0;
    for(const auto& x : data) seq_result += x;

    // Parallel reduce
    int par_result = 0;
    taskflow.reduce(data.begin(), data.end(), par_result, std::plus<int>());
    executor.run(taskflow).wait();

    EXPECT_EQ(par_result, seq_result);
}
```

### Exception Handling Pattern

```cpp
TEST(Verification, ExceptionPropagation) {
    tf::Executor executor(4);
    tf::Taskflow taskflow;

    taskflow.emplace([]{
        throw std::runtime_error("test error");
    });

    EXPECT_THROW(executor.run(taskflow).get(), std::runtime_error);
}

TEST(Verification, PartialExecutionOnException) {
    tf::Executor executor(4);
    tf::Taskflow taskflow;
    std::atomic<int> counter{0};

    auto A = taskflow.emplace([&]{ counter++; });
    auto B = taskflow.emplace([&]{
        counter++;
        throw std::runtime_error("error");
    });
    auto C = taskflow.emplace([&]{ counter++; });

    A.precede(B);
    B.precede(C);

    EXPECT_THROW(executor.run(taskflow).get(), std::runtime_error);
    EXPECT_EQ(counter, 2);  // A and B ran, C did not
}
```

---

## Edge Cases

### Empty Taskflow

```cpp
TEST(EdgeCases, EmptyTaskflow) {
    tf::Executor executor(4);
    tf::Taskflow taskflow;

    EXPECT_TRUE(taskflow.empty());
    EXPECT_EQ(taskflow.num_tasks(), 0);

    EXPECT_NO_THROW(executor.run(taskflow).wait());
}
```

### Single Task

```cpp
TEST(EdgeCases, SingleTask) {
    tf::Executor executor(4);
    tf::Taskflow taskflow;
    int value = 0;

    taskflow.emplace([&]{ value = 42; });

    EXPECT_EQ(taskflow.num_tasks(), 1);
    executor.run(taskflow).wait();
    EXPECT_EQ(value, 42);
}
```

### Placeholder Tasks

```cpp
TEST(EdgeCases, PlaceholderTasks) {
    tf::Executor executor(4);
    tf::Taskflow taskflow;
    std::atomic<int> counter{0};

    std::vector<tf::Task> tasks;

    for(int i = 0; i < 100; i++) {
        tasks.push_back(taskflow.placeholder().name(std::to_string(i)));
    }

    // Verify placeholders exist
    for(int i = 0; i < 100; i++) {
        EXPECT_EQ(tasks[i].name(), std::to_string(i));
    }

    // Assign work later
    for(auto& t : tasks) {
        t.work([&]{ counter++; });
    }

    executor.run(taskflow).wait();
    EXPECT_EQ(counter, 100);
}
```

### Move-Only Types

```cpp
TEST(EdgeCases, MoveOnlyTypes) {
    struct MoveOnly {
        int value;
        MoveOnly(int v) : value(v) {}
        MoveOnly(const MoveOnly&) = delete;
        MoveOnly(MoveOnly&&) = default;
        MoveOnly& operator=(const MoveOnly&) = delete;
        MoveOnly& operator=(MoveOnly&&) = default;
    };

    tf::Executor executor(4);
    tf::Taskflow taskflow;

    std::vector<MoveOnly> data;
    for(int i = 0; i < 1000; i++) {
        data.emplace_back(rand() % 100);
    }

    taskflow.sort(data.begin(), data.end(),
        [](const MoveOnly& a, const MoveOnly& b){
            return a.value < b.value;
        }
    );

    executor.run(taskflow).wait();

    for(size_t i = 1; i < data.size(); i++) {
        EXPECT_LE(data[i-1].value, data[i].value);
    }
}
```

### Stress Test Pattern

```cpp
TEST(EdgeCases, StressTest) {
    tf::Executor executor(8);
    tf::Taskflow taskflow;
    std::atomic<int> counter{0};

    const int N = 100000;

    for(int i = 0; i < N; i++) {
        taskflow.emplace([&]{
            counter.fetch_add(1, std::memory_order_relaxed);
        });
    }

    executor.run(taskflow).wait();
    EXPECT_EQ(counter, N);
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
| `tf::GuidedPartitioner(c)` | General purpose, good load balancing |
| `tf::StaticPartitioner(c)` | Uniform work, predictable |
| `tf::DynamicPartitioner(c)` | Variable work per element |
| `tf::RandomPartitioner(c)` | Testing, debugging |

### Execution Methods

| Method | Description |
|--------|-------------|
| `executor.run(tf).wait()` | Run once, block |
| `executor.run(tf).get()` | Run once, block (throws on exception) |
| `executor.run_n(tf, N).wait()` | Run N times |
| `executor.run_until(tf, pred).wait()` | Run until predicate true |
| `executor.wait_for_all()` | Wait for all async tasks |

### GoogleTest Assertions for Taskflow

| Assertion | Use Case |
|-----------|----------|
| `EXPECT_EQ(counter, N)` | Verify task execution count |
| `EXPECT_TRUE(std::is_sorted(...))` | Verify sort results |
| `EXPECT_THROW(run().get(), type)` | Verify exception handling |
| `EXPECT_NO_THROW(run().wait())` | Verify no exceptions |
| `EXPECT_EQ(vec, expected_vec)` | Compare entire vectors |

### Test Data Sizes

| Purpose | Sizes |
|---------|-------|
| Basic correctness | 0, 1, 10, 100 |
| Boundary testing | 0, 1, 3, 7, 99 (chunk sizes) |
| Stress testing | 10000, 100000 |

### Thread Counts for Parameterized Tests

```cpp
::testing::Values(1, 2, 4, 8)      // Basic
::testing::Values(1, 2, 3, 4, 5, 6, 7, 8)  // Comprehensive
```
