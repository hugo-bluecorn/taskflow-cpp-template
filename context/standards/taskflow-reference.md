# Taskflow Reference

Taskflow (v4.1.0) is a header-only C++20 library for task-parallel programming with work-stealing scheduling.

## Overview

Taskflow enables expressing parallel workloads through task dependency graphs (DAGs). Key features:

- **Static Tasking** - Fixed task dependency graphs
- **Dynamic Tasking** - Nested subflows created at runtime
- **Conditional Tasking** - Control flow within task graphs
- **Parallel Algorithms** - `for_each`, `reduce`, `sort`, `scan`, `find`
- **Pipeline Parallelism** - Data and task parallel pipelines
- **Work-Stealing Scheduler** - Automatic load balancing

## CMake Integration

Taskflow is header-only. Add the include path in CMakeLists.txt:

```cmake
# Add taskflow include directory
target_include_directories(${PROJECT_NAME} PRIVATE
  ${CMAKE_SOURCE_DIR}/ext/taskflow
)
```

Then include in your code:

```cpp
#include <taskflow/taskflow.hpp>
```

### Compiler Requirements

| Compiler | Version | Flag |
|----------|---------|------|
| GCC | 11.0+ | `-std=c++20` |
| Clang | 12.0+ | `-std=c++20` |
| MSVC | 19.29+ | `/std:c++20` |
| Apple Clang | 13.0+ | `-std=c++20` |

## Core API

### Executor and Taskflow

```cpp
#include <taskflow/taskflow.hpp>

int main() {
  tf::Executor executor;      // Thread pool (defaults to hardware concurrency)
  tf::Taskflow taskflow;      // Task dependency graph

  // Create tasks
  auto A = taskflow.emplace([]{ std::cout << "A\n"; }).name("A");
  auto B = taskflow.emplace([]{ std::cout << "B\n"; }).name("B");
  auto C = taskflow.emplace([]{ std::cout << "C\n"; }).name("C");

  // Define dependencies: A runs before B and C
  A.precede(B, C);

  // Execute and wait
  executor.run(taskflow).wait();

  return 0;
}
```

### Key Classes

| Class | Purpose |
|-------|---------|
| `tf::Executor` | Manages worker threads, executes taskflows |
| `tf::Taskflow` | Container for task dependency graph |
| `tf::Task` | Handle to an individual task |
| `tf::Subflow` | Dynamic nested task graph |
| `tf::Runtime` | Execution context within tasks |

### Task Dependencies

```cpp
// A runs before B
A.precede(B);

// B runs after A (equivalent)
B.succeed(A);

// Multiple dependencies
A.precede(B, C, D);  // A before B, C, and D
D.succeed(B, C);     // D after both B and C
```

## Task Types

### Static Tasks

Basic callable tasks:

```cpp
taskflow.emplace([]{
  std::cout << "static task\n";
});
```

### Subflow Tasks (Dynamic Parallelism)

Create nested task graphs at runtime:

```cpp
taskflow.emplace([](tf::Subflow& subflow) {
  auto B1 = subflow.emplace([]{ std::cout << "B1\n"; });
  auto B2 = subflow.emplace([]{ std::cout << "B2\n"; });
  B1.precede(B2);
}).name("dynamic_task");
```

### Condition Tasks

Return values control branching (0-indexed):

```cpp
int counter = 0;
auto cond = taskflow.emplace([&counter]() {
  return (counter++ < 5) ? 0 : 1;  // 0 = first successor, 1 = second
}).name("condition");

auto loop_body = taskflow.emplace([]{ std::cout << "loop\n"; });
auto done = taskflow.emplace([]{ std::cout << "done\n"; });

cond.precede(loop_body, done);  // 0 -> loop_body, 1 -> done
loop_body.precede(cond);        // Loop back
```

### Module Tasks (Composition)

Compose taskflows hierarchically:

```cpp
tf::Taskflow f1, f2;

// Build f1
auto a = f1.emplace([]{ std::cout << "a\n"; });
auto b = f1.emplace([]{ std::cout << "b\n"; });
a.precede(b);

// Compose f1 into f2
auto module = f2.composed_of(f1).name("f1_module");
auto c = f2.emplace([]{ std::cout << "c\n"; });
module.precede(c);

executor.run(f2).wait();
```

## Execution Methods

```cpp
// Single run
executor.run(taskflow).wait();

// Run N times
executor.run_n(taskflow, 4).wait();

// Run until condition is true
executor.run_until(taskflow, [count=0]() mutable {
  return ++count == 10;
}).wait();

// Async execution (non-blocking)
std::future<void> fu = executor.run(taskflow);
// ... do other work ...
fu.get();  // Wait for completion
```

## Parallel Algorithms

### Parallel For-Each

```cpp
std::vector<int> data(1000);

// Iterator-based
taskflow.for_each(data.begin(), data.end(), [](int& item) {
  item *= 2;
});

// Index-based
taskflow.for_each_index(0, 1000, 1, [&data](int i) {
  data[i] = i * i;
});

executor.run(taskflow).wait();
```

### Parallel Reduce

```cpp
std::vector<int> data = {1, 2, 3, 4, 5};
int sum = 0;

taskflow.reduce(data.begin(), data.end(), sum,
  [](int a, int b) { return a + b; }
);

executor.run(taskflow).wait();
// sum == 15
```

### Parallel Transform-Reduce

```cpp
std::vector<int> data = {1, 2, 3, 4, 5};
int sum_of_squares = 0;

taskflow.transform_reduce(
  data.begin(), data.end(),
  sum_of_squares,
  [](int a, int b) { return a + b; },      // Reduce
  [](int x) { return x * x; }              // Transform
);

executor.run(taskflow).wait();
// sum_of_squares == 55
```

### Parallel Sort

```cpp
std::vector<int> data = {5, 2, 8, 1, 9};

taskflow.sort(data.begin(), data.end());
// Or with custom comparator
taskflow.sort(data.begin(), data.end(), std::greater<int>());

executor.run(taskflow).wait();
```

### Parallel Scan

```cpp
std::vector<int> input = {1, 2, 3, 4, 5};
std::vector<int> output(5);

// Inclusive scan: [1, 3, 6, 10, 15]
taskflow.inclusive_scan(
  input.begin(), input.end(),
  output.begin(),
  [](int a, int b) { return a + b; }
);

// Exclusive scan: [0, 1, 3, 6, 10]
taskflow.exclusive_scan(
  input.begin(), input.end(),
  output.begin(),
  0,  // Initial value
  [](int a, int b) { return a + b; }
);

executor.run(taskflow).wait();
```

### Parallel Find

```cpp
std::vector<int> data = {1, 2, 3, 4, 5};
std::vector<int>::iterator result;

taskflow.find_if(
  data.begin(), data.end(),
  result,
  [](int x) { return x > 3; }
);

executor.run(taskflow).wait();
// *result == 4
```

## Pipeline Parallelism

### Basic Pipeline

```cpp
tf::Pipeline pl(
  4,  // Number of parallel lines

  // Stage 1: Serial input
  tf::Pipe{tf::PipeType::SERIAL, [](tf::Pipeflow& pf) {
    if (pf.token() == 10) {
      pf.stop();  // Stop after 10 tokens
      return;
    }
    printf("Stage 1: token %zu\n", pf.token());
  }},

  // Stage 2: Parallel processing
  tf::Pipe{tf::PipeType::PARALLEL, [](tf::Pipeflow& pf) {
    printf("Stage 2: token %zu\n", pf.token());
  }},

  // Stage 3: Serial output
  tf::Pipe{tf::PipeType::SERIAL, [](tf::Pipeflow& pf) {
    printf("Stage 3: token %zu\n", pf.token());
  }}
);

taskflow.composed_of(pl);
executor.run(taskflow).wait();
```

### Data Pipeline

Pass data between stages:

```cpp
tf::DataPipeline pl(
  4,  // Number of parallel lines

  tf::make_data_pipe<void, int>(tf::PipeType::SERIAL, [](tf::Pipeflow& pf) {
    if (pf.token() == 10) {
      pf.stop();
      return 0;
    }
    return static_cast<int>(pf.token());
  }),

  tf::make_data_pipe<int, float>(tf::PipeType::PARALLEL, [](int input) {
    return input * 2.0f;
  }),

  tf::make_data_pipe<float, void>(tf::PipeType::SERIAL, [](float input) {
    printf("Result: %f\n", input);
  })
);

taskflow.composed_of(pl);
executor.run(taskflow).wait();
```

## Asynchronous Tasks

### Basic Async

```cpp
// Returns future
std::future<int> fu = executor.async([]() {
  return 42;
});
int result = fu.get();

// Silent async (no return value)
executor.silent_async([]{
  std::cout << "async task\n";
});
```

### Dependent Async

```cpp
tf::AsyncTask A = executor.silent_dependent_async(
  []{ printf("A\n"); }
);

tf::AsyncTask B = executor.silent_dependent_async(
  []{ printf("B\n"); },
  A  // Depends on A
);

tf::AsyncTask C = executor.silent_dependent_async(
  []{ printf("C\n"); },
  A  // Depends on A
);

tf::AsyncTask D = executor.silent_dependent_async(
  []{ printf("D\n"); },
  B, C  // Depends on B and C
);

executor.wait_for_all();
```

## Concurrency Control

### Semaphores

Limit concurrent access:

```cpp
tf::Semaphore semaphore(2);  // Max 2 concurrent tasks

for (int i = 0; i < 10; ++i) {
  taskflow.emplace([&semaphore, i]() {
    semaphore.acquire();
    printf("Task %d running\n", i);
    // ... critical section ...
    semaphore.release();
  });
}

executor.run(taskflow).wait();
```

### Critical Sections

```cpp
tf::CriticalSection critical_section(1);  // Mutex (max 1)

auto [A, B, C] = taskflow.emplace(
  []{ printf("A\n"); },
  []{ printf("B\n"); },
  []{ printf("C\n"); }
);

// A and B cannot run concurrently
critical_section.add(A, B);

executor.run(taskflow).wait();
```

## Visualization and Profiling

### DOT Graph Export

```cpp
// Dump to stdout
taskflow.dump(std::cout);

// Dump to file
std::ofstream file("graph.dot");
taskflow.dump(file);
```

Visualize with Graphviz: `dot -Tpng graph.dot -o graph.png`

### Profiling

```bash
# Enable profiling via environment variable
TF_ENABLE_PROFILER=profile.json ./my_program

# Upload profile.json to https://taskflow.github.io/tfprof/
```

### Observer Interface

Monitor task execution:

```cpp
class MyObserver : public tf::ObserverInterface {
public:
  void set_up(size_t num_workers) override {
    printf("Observer: %zu workers\n", num_workers);
  }

  void on_entry(tf::WorkerView wv, tf::TaskView tv) override {
    printf("Worker %d starting %s\n", wv.id(), tv.name().data());
  }

  void on_exit(tf::WorkerView wv, tf::TaskView tv) override {
    printf("Worker %d finished %s\n", wv.id(), tv.name().data());
  }
};

auto observer = executor.make_observer<MyObserver>();
executor.run(taskflow).wait();
executor.remove_observer(std::move(observer));
```

## Exception Handling

```cpp
taskflow.emplace([]{
  throw std::runtime_error("error!");
});

try {
  executor.run(taskflow).get();
} catch (const std::exception& e) {
  std::cout << "Caught: " << e.what() << "\n";
}
```

## Best Practices

### Task Granularity

- Avoid tasks that are too fine-grained (overhead dominates)
- Avoid tasks that are too coarse-grained (poor load balancing)
- Target tasks that take microseconds to milliseconds

### Memory Access

- Minimize shared state between tasks
- Use task-local data when possible
- Be aware of false sharing in parallel algorithms

### Error Handling

- Use exception handling for error propagation
- Check futures for exceptions with `.get()`
- Consider `std::optional` for tasks that may not produce results

### Graph Design

- Keep task graphs shallow when possible
- Use modules to organize complex graphs
- Name tasks for easier debugging and profiling

## Project Structure

```
ext/taskflow/
├── taskflow/
│   ├── taskflow.hpp          # Main include file
│   ├── core/
│   │   ├── executor.hpp      # Thread pool management
│   │   ├── taskflow.hpp      # Graph construction
│   │   ├── task.hpp          # Task interface
│   │   └── ...
│   └── algorithm/
│       ├── for_each.hpp      # Parallel loops
│       ├── reduce.hpp        # Parallel reduction
│       ├── sort.hpp          # Parallel sort
│       ├── pipeline.hpp      # Pipeline parallelism
│       └── ...
├── examples/                  # 40+ examples
├── unittests/                 # Test suite
└── docs/                      # Documentation
```

## Quick Reference

### Common Patterns

| Pattern | Code |
|---------|------|
| Create task | `auto t = taskflow.emplace(callable)` |
| Name task | `t.name("task_name")` |
| Set dependency | `A.precede(B)` or `B.succeed(A)` |
| Run taskflow | `executor.run(taskflow).wait()` |
| Run N times | `executor.run_n(taskflow, N).wait()` |
| Parallel for | `taskflow.for_each(begin, end, func)` |
| Parallel reduce | `taskflow.reduce(begin, end, init, op)` |
| Parallel sort | `taskflow.sort(begin, end)` |

### Thread Control

```cpp
// Specific thread count
tf::Executor executor(4);

// Query thread count
size_t n = executor.num_workers();

// Wait for all tasks
executor.wait_for_all();
```

## References

- [Taskflow GitHub](https://github.com/taskflow/taskflow)
- [Taskflow Documentation](https://taskflow.github.io/)
- [TFProf Profiler](https://taskflow.github.io/tfprof/)
