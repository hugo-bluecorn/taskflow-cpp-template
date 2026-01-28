# C++ Coding Standards

This project follows the [Google C++ Style Guide](https://google.github.io/styleguide/cppguide.html).

## Naming Conventions

| Element | Style | Example |
|---------|-------|---------|
| Files | `snake_case` | `my_class.cpp`, `my_class.h` |
| Classes/Structs | `PascalCase` | `MyClass`, `SharedMemoryBuffer` |
| Functions | `snake_case` | `get_value()`, `calculate_offset()` |
| Variables | `snake_case` | `buffer_size`, `item_count` |
| Member variables | `snake_case_` (trailing underscore) | `buffer_size_`, `data_` |
| Constants | `kPascalCase` | `kMaxBufferSize`, `kDefaultTimeout` |
| Enums | `PascalCase` type, `kPascalCase` values | `enum class Color { kRed, kGreen }` |
| Macros | `UPPER_SNAKE_CASE` | `SHM_MAX_SIZE` |
| Namespaces | `snake_case` | `namespace shared_memory` |

## Formatting

- **Indentation**: 2 spaces (no tabs)
- **Line length**: 80 characters max
- **Braces**: Opening brace on same line
- **Namespace**: No indentation inside namespace

```cpp
namespace shared_memory {

class Buffer {
 public:
  Buffer(size_t size);

  void write(const void* data, size_t len);
  size_t read(void* dest, size_t max_len);

 private:
  size_t size_;
  std::unique_ptr<uint8_t[]> data_;
};

}  // namespace shared_memory
```

## Include Order

Group includes in this order, with blank line between groups:

1. Related header (e.g., `foo.h` for `foo.cpp`)
2. C system headers (`<unistd.h>`, `<sys/mman.h>`)
3. C++ standard library (`<memory>`, `<vector>`)
4. Other libraries
5. Project headers

```cpp
#include "shared_memory/buffer.h"

#include <sys/mman.h>
#include <unistd.h>

#include <memory>
#include <string>
#include <vector>

#include "shared_memory/config.h"
#include "shared_memory/utils.h"
```

## Header Guards

Use `#ifndef` style with path-based naming:

```cpp
#ifndef PROJECT_PATH_FILE_H_
#define PROJECT_PATH_FILE_H_

// ... content ...

#endif  // PROJECT_PATH_FILE_H_
```

## Modern C++ Practices

### Prefer
- `auto` for complex types: `auto it = map.find(key);`
- Range-based for: `for (const auto& item : items)`
- Smart pointers: `std::unique_ptr`, `std::shared_ptr`
- `nullptr` over `NULL` or `0`
- `enum class` over plain `enum`
- `constexpr` for compile-time constants
- `std::string_view` for non-owning string references

### Avoid
- Raw `new`/`delete` - use smart pointers
- C-style casts - use `static_cast`, `reinterpret_cast`
- `using namespace std;` in headers

## Memory Management

- **RAII**: Resources acquired in constructor, released in destructor
- **Smart pointers**:
  - `unique_ptr` for single ownership
  - `shared_ptr` only when ownership is truly shared
- **Raw pointers**: Only for non-owning references

## Error Handling

Google style discourages exceptions. Use:
- Return values or status codes
- `std::optional` for values that may not exist
- `std::expected` (C++23) or similar for error-or-value

```cpp
// Good
std::optional<Buffer> create_buffer(size_t size) {
  if (size == 0) return std::nullopt;
  return Buffer(size);
}

// Good - status code
enum class Status { kOk, kError, kNotFound };
Status find_item(int id, Item* out);
```

## Comments

- `//` for single-line comments
- `/* */` for multi-line (sparingly)
- Doxygen-style for API documentation:

```cpp
/// @brief Creates a shared memory segment.
/// @param name The name of the segment (must start with '/').
/// @param size The size in bytes.
/// @return File descriptor on success, -1 on error.
int shm_create(const char* name, size_t size);
```

## Scoping

### Namespaces

| Rule | Description |
|------|-------------|
| Place code in namespaces | Exceptions are rare; use unique names based on project/path |
| No `using namespace` | Never use `using namespace foo;` (using-directives) |
| No inline namespaces | Avoid `inline namespace` |
| Don't modify `std` | Never declare anything in namespace `std` |
| Comment closing brace | End multi-line namespaces with `}  // namespace name` |

```cpp
// Preferred: nested single-line syntax (C++17)
namespace my_project::my_component {

void do_something();

}  // namespace my_project::my_component

// Namespace aliases - OK in .cpp files, avoid in headers
namespace baz = ::foo::bar::baz;
```

### Internal Linkage

Use internal linkage for symbols that don't need external access:

| Method | Usage |
|--------|-------|
| Unnamed namespace | Preferred for functions and variables in .cpp files |
| `static` keyword | Alternative for functions and variables |

```cpp
// In .cpp file only (never in headers)
namespace {

constexpr int kLocalConstant = 42;

void helper_function() {
  // Only visible in this translation unit
}

}  // namespace
```

### Local Variables

- **Declare in narrowest scope** - immediately before first use
- **Initialize at declaration** - avoid separate declaration and assignment
- **Loop-scoped declarations** - use when appropriate

```cpp
// Good - declared where needed, initialized immediately
void process_items(const std::vector<Item>& items) {
  for (const auto& item : items) {
    int result = calculate(item);  // Declared at point of use
    use_result(result);
  }
}

// Good - loop-scoped declaration
while (const char* p = strchr(str, '/')) {
  process_segment(p);
  str = p + 1;
}

// Consider: move outside loop if constructor/destructor is expensive
ExpensiveObject obj;
for (int i = 0; i < n; ++i) {
  obj.reset();
  // ... use obj ...
}
```

### Static and Global Variables

**Core rule**: Objects with static storage duration must be **trivially destructible**.

| Allowed | Forbidden |
|---------|-----------|
| Fundamental types (`int`, `double`, etc.) | `std::string`, `std::map` |
| `constexpr` variables | Smart pointers (`unique_ptr`, `shared_ptr`) |
| `const` arrays of allowed types | Classes with non-trivial destructors |
| Function-local statics (any type) | Namespace-scope dynamic initialization |

```cpp
// Good - trivially destructible
constexpr int kMaxSize = 1024;
const char* const kNames[] = {"foo", "bar"};

// Good - use string_view instead of string
constexpr std::string_view kDefaultName = "default";

// Good - function-local static (lazy initialization)
const std::map<int, std::string>& get_mapping() {
  static const auto* mapping = new std::map<int, std::string>{
    {1, "one"}, {2, "two"}
  };
  return *mapping;
}

// Bad - non-trivial destructor at namespace scope
std::string default_name = "default";  // Don't do this
```

### thread_local Variables

| Scope | Requirement |
|-------|-------------|
| Namespace/class scope | Must use `constinit` (compile-time init only) |
| Function scope | May have dynamic initialization |

```cpp
// Good - constinit at namespace scope
constinit thread_local int tls_counter = 0;

// Good - function-local thread_local (preferred for complex types)
Cache& get_thread_cache() {
  thread_local Cache cache = create_cache();
  return cache;
}
```

**Caution**: Destructor order during thread exit is unpredictable. Prefer trivially destructible types for `thread_local` to avoid use-after-free bugs.

## Classes

### Constructors

| Rule | Description |
|------|-------------|
| Never call virtual functions | Virtual calls dispatch to base class, not derived |
| Avoid work that can fail | Constructors can't signal errors without exceptions |
| Use factory functions | For complex initialization that may fail |

```cpp
// Good - factory function for fallible initialization
class Connection {
 public:
  static std::optional<Connection> create(const std::string& host) {
    Connection conn;
    if (!conn.connect(host)) return std::nullopt;
    return conn;
  }

 private:
  Connection() = default;
  bool connect(const std::string& host);
};
```

### Implicit Conversions

Mark single-argument constructors and conversion operators as `explicit`:

```cpp
class MyString {
 public:
  explicit MyString(int size);           // Prevents MyString s = 42;
  explicit operator bool() const;        // Prevents if (my_string == other)

  // Exception: copy/move constructors should NOT be explicit
  MyString(const MyString&) = default;
  MyString(MyString&&) = default;
};
```

### Copyable and Movable Types

Explicitly declare copy/move semantics in the public section:

```cpp
// Copyable class
class Buffer {
 public:
  Buffer(const Buffer&) = default;
  Buffer& operator=(const Buffer&) = default;
  // ...
};

// Move-only class
class UniqueHandle {
 public:
  UniqueHandle(UniqueHandle&&) = default;
  UniqueHandle& operator=(UniqueHandle&&) = default;
  UniqueHandle(const UniqueHandle&) = delete;
  UniqueHandle& operator=(const UniqueHandle&) = delete;
  // ...
};

// Non-copyable, non-movable
class Singleton {
 public:
  Singleton(const Singleton&) = delete;
  Singleton& operator=(const Singleton&) = delete;
  // ...
};
```

### Structs vs Classes

| Use `struct` | Use `class` |
|--------------|-------------|
| Passive data containers only | Everything else |
| All fields public | Has invariants or private state |
| No enforced invariants | Methods that maintain state |
| Simple constructors OK | Complex initialization |

```cpp
// Good - passive data, use struct
struct Point {
  int x;
  int y;
};

// Good - has invariants, use class
class Rectangle {
 public:
  Rectangle(int w, int h) : width_(w), height_(h) {}
  int area() const { return width_ * height_; }

 private:
  int width_;
  int height_;
};
```

**Prefer `struct` over `std::pair`/`std::tuple`** - named fields are clearer than `.first`/`.second`.

### Inheritance

| Rule | Description |
|------|-------------|
| Public inheritance only | Never use private/protected inheritance; use composition |
| Mark overrides | Always use `override` or `final`, never bare `virtual` |
| Prefer composition | Use "is-a" test: "Can subclass be described as 'a kind of' base?" |
| Data members private | Even in base classes |

```cpp
class Animal {
 public:
  virtual ~Animal() = default;
  virtual void speak() const = 0;
};

class Dog : public Animal {
 public:
  void speak() const override;  // Always mark override
};

class FinalDog final : public Animal {  // Cannot be subclassed
 public:
  void speak() const final;     // Cannot be overridden
};
```

### Operator Overloading

| Allowed | Prohibited |
|---------|------------|
| `==`, `<=>` for comparable types | `&&`, `\|\|` (short-circuit semantics lost) |
| Arithmetic for numeric types | Comma operator |
| `<<`/`>>` for streams | Unary `&` |
| Container access `[]` | User-defined literals (`operator""`) |

```cpp
// Good - obvious semantics
bool operator==(const Point& a, const Point& b) {
  return a.x == b.x && a.y == b.y;
}

// Good - non-member for binary operators
Point operator+(const Point& a, const Point& b) {
  return {a.x + b.x, a.y + b.y};
}
```

### Declaration Order

Organize class members in this order:

1. **`public:`** - types, constants, factories, constructors, destructor, methods
2. **`protected:`** - (if needed, keep minimal)
3. **`private:`** - data members, private methods

```cpp
class MyClass {
 public:
  // Types and aliases
  using ValueType = int;

  // Static constants
  static constexpr int kMaxSize = 100;

  // Constructors and destructor
  MyClass();
  ~MyClass();

  // Public methods
  void do_something();

 private:
  // Data members
  int value_;
  std::string name_;
};
```

## Functions

### Inputs and Outputs

**Prefer return values over output parameters** for clarity and performance.

| Parameter Type | Guideline |
|----------------|-----------|
| Input (required) | Pass by value or `const&` |
| Input (optional) | Use `std::optional<T>` or `const T*` |
| Output (required) | Return by value, or use non-const reference |
| Output (optional) | Use `T*` (pointer can be null) |
| Input/output | Non-const reference |

```cpp
// Good - return value for output
std::vector<int> get_items();

// Good - const reference for input
void process(const std::string& input);

// Good - optional input with std::optional
void configure(std::optional<int> timeout);

// Good - optional output with pointer
bool find(int key, Item* result);  // result can be nullptr

// Good - input/output with reference
void update(Data& data);
```

**Parameter order**: Inputs first, then outputs.

**Avoid**: Functions requiring reference parameters to outlive the call (lifetime bugs).

### Write Short Functions

- Target ~40 lines or fewer
- Break up long functions for readability and testability
- No strict limit, but longer functions warrant consideration for decomposition

### Function Overloading

Overload only when the behavior is identical regardless of which overload is called:

```cpp
// Good - same behavior, different input types
class MyString {
 public:
  void append(const char* str);
  void append(const std::string& str);
  void append(std::string_view str);  // Often preferred over overloading
};

// Avoid - different behavior based on type
void process(int x);      // Rounds to nearest
void process(double x);   // Truncates
```

**Tip**: Consider `std::string_view` instead of overloading for `const char*` / `const std::string&`.

### Default Arguments

| Allowed | Not Allowed |
|---------|-------------|
| Non-virtual functions | Virtual functions (behavior undefined) |
| Constant defaults | Defaults that vary |

```cpp
// Good - non-virtual with constant default
void connect(const std::string& host, int port = 8080);

// Bad - default on virtual function
class Base {
 public:
  virtual void process(int value = 0);  // Don't do this
};
```

**Trade-off**: Default arguments are cleaner than overloads but are re-evaluated at each call site.

### Trailing Return Type Syntax

**Prefer traditional syntax** unless trailing improves readability:

```cpp
// Preferred - traditional syntax
int calculate(int x, int y);
std::vector<std::string> get_names();

// OK - trailing syntax required for lambdas
auto multiply = [](int a, int b) -> int { return a * b; };

// OK - trailing syntax helpful for complex templates
template <typename T, typename U>
auto add(T t, U u) -> decltype(t + u) {
  return t + u;
}
```

## Other C++ Features

### Rvalue References

Use rvalue references (`&&`) only for:

| Permitted Use | Description |
|---------------|-------------|
| Move constructor/assignment | `MyClass(MyClass&& other)` |
| Consuming methods | Methods qualified with `&&` that consume the object |
| Perfect forwarding | `std::forward` with forwarding references |

```cpp
class Buffer {
 public:
  Buffer(Buffer&& other) noexcept;             // Move constructor
  Buffer& operator=(Buffer&& other) noexcept;  // Move assignment

  // Consuming method - called on rvalues
  std::vector<uint8_t> release() &&;
};

// Perfect forwarding
template <typename T>
void wrapper(T&& arg) {
  inner(std::forward<T>(arg));
}
```

### Friends

- Define friends in the same file as the class
- Use for builder classes, unit test fixtures
- Most classes should only use public interfaces

### Exceptions

**Not used in this project** (following Google style). Use return values or status codes instead.
See the Error Handling section above.

### noexcept

Use `noexcept` for move operations and when beneficial:

```cpp
// Good - enables optimizations (e.g., std::vector::resize uses move)
Buffer(Buffer&& other) noexcept;
Buffer& operator=(Buffer&& other) noexcept;

// Good - function guaranteed not to throw
int calculate(int x) noexcept;
```

### RTTI (Run-Time Type Information)

| Context | Guideline |
|---------|-----------|
| Unit tests | `typeid` and `dynamic_cast` OK |
| Production code | Avoid - indicates design issues |

**Alternatives to RTTI**:
- Virtual methods for type-specific behavior
- Visitor pattern for external processing
- `static_cast` when type is guaranteed by logic

### Casting

| Operation | Use |
|-----------|-----|
| Arithmetic conversion | Brace init: `int64_t{x}` |
| Class conversion | Function-style: `std::string(value)` |
| Value/pointer conversion | `static_cast<T>(x)` |
| Remove const | `const_cast<T*>(ptr)` |
| Unsafe pointer conversion | `reinterpret_cast<T*>(ptr)` |
| Type punning | `std::bit_cast<T>(x)` (C++20) |

```cpp
// Good - explicit and clear
auto size = static_cast<int>(vector.size());
auto* derived = static_cast<Derived*>(base_ptr);

// Avoid - C-style casts are ambiguous
int x = (int)value;  // Don't do this
```

### Streams

| Use For | Avoid For |
|---------|-----------|
| Debug logging | External-facing I/O |
| Test diagnostics | Untrusted data |
| Ad-hoc developer output | Stateful operations |

### Preincrement and Predecrement

**Prefer prefix** (`++i`, `--i`) over postfix (`i++`, `i--`):

```cpp
// Good - no unnecessary copy
for (auto it = v.begin(); it != v.end(); ++it) { ... }

// Use postfix only when you need the original value
*dest++ = *src++;
```

### Use of const

Apply `const` consistently:

```cpp
// Immutable value
const int kMaxRetries = 3;

// Pointer to const data
const char* message = "hello";

// Const pointer
char* const buffer = get_buffer();

// Method that doesn't modify state
class Data {
 public:
  int size() const { return size_; }
};
```

### constexpr, constinit, consteval

| Keyword | Purpose |
|---------|---------|
| `constexpr` | Compile-time computable values and functions |
| `constinit` | Enforce compile-time initialization (C++20) |
| `consteval` | Must be evaluated at compile-time (C++20) |

```cpp
// Good - compile-time constant
constexpr int kBufferSize = 1024;
constexpr int square(int x) { return x * x; }

// Good - enforced compile-time init for static
constinit int global_counter = 0;
```

### Integer Types

Use fixed-width types from `<cstdint>` for specific sizes:

| Type | Use Case |
|------|----------|
| `int` | General-purpose (at least 16 bits) |
| `int32_t`, `int64_t` | Fixed-width requirements |
| `size_t` | Sizes and container indices |
| `ptrdiff_t` | Pointer differences |

### Preprocessor Macros

**Avoid macros** - prefer `constexpr`, `inline`, and `enum class`.

When macros are necessary:
- Use `SCREAMING_SNAKE_CASE`
- Document thoroughly
- Consider `#undef` after use

### nullptr

**Always use `nullptr`** instead of `0` or `NULL`:

```cpp
int* ptr = nullptr;  // Good
int* ptr = NULL;     // Avoid
int* ptr = 0;        // Avoid
```

### Type Deduction (auto, decltype)

Use `auto` when it improves clarity:

```cpp
// Good - type is clear from context
auto it = map.find(key);
auto ptr = std::make_unique<Widget>();

// Good - avoids long type names
for (const auto& [key, value] : map) { ... }

// Avoid - type unclear
auto result = calculate();  // What type is this?
```

### Lambda Expressions

Keep lambdas short and focused:

```cpp
// Good - simple, clear purpose
auto is_valid = [](int x) { return x > 0; };

// Good - explicit capture
auto callback = [&buffer, timeout](int id) {
  process(buffer, id, timeout);
};

// Avoid - complex lambdas (use named functions instead)
auto complex = [&](auto&& x) {
  // 20+ lines of code - extract to named function
};
```

### Template Metaprogramming

**Use sparingly** - prioritize readable code over clever metaprogramming.

Acceptable uses:
- Type traits: `std::is_integral_v<T>`
- Simple SFINAE or concepts
- Performance-critical specializations

```cpp
// Good - simple constraint (C++20)
template <std::integral T>
T sum(const std::vector<T>& values);

// Avoid - complex SFINAE unless absolutely necessary
```

## References

- [Google C++ Style Guide](https://google.github.io/styleguide/cppguide.html)
- [C++ Core Guidelines](https://isocpp.github.io/CppCoreGuidelines/CppCoreGuidelines)
