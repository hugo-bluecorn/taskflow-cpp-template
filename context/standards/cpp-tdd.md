# Test-Driven Development with Google Test

## TDD Workflow: Red-Green-Refactor

```
┌─────────────────────────────────────────────────────┐
│  RED: Write a failing test                          │
│       - Test must fail for the right reason         │
│       - Compile errors count as "red"               │
│                                                     │
│  GREEN: Write minimal code to pass                  │
│         - Only enough to make the test pass         │
│         - Don't over-engineer                       │
│                                                     │
│  REFACTOR: Improve the code                         │
│            - Keep tests passing                     │
│            - Remove duplication                     │
│            - Improve naming/structure               │
└─────────────────────────────────────────────────────┘
```

## Google Test Basics

### Test Structure

```cpp
#include <gtest/gtest.h>

// Simple test
TEST(TestSuiteName, TestName) {
  // Arrange
  int a = 5;
  int b = 3;

  // Act
  int result = add(a, b);

  // Assert
  EXPECT_EQ(result, 8);
}
```

### Test Fixtures

```cpp
class BufferTest : public ::testing::Test {
 protected:
  void SetUp() override {
    buffer_ = std::make_unique<Buffer>(1024);
  }

  void TearDown() override {
    buffer_.reset();
  }

  std::unique_ptr<Buffer> buffer_;
};

TEST_F(BufferTest, InitiallyEmpty) {
  EXPECT_EQ(buffer_->size(), 0);
}

TEST_F(BufferTest, WriteIncreasesSize) {
  buffer_->write("hello", 5);
  EXPECT_EQ(buffer_->size(), 5);
}
```

## Assertions

### Fatal vs Non-Fatal

| Fatal (stops test) | Non-Fatal (continues) |
|--------------------|----------------------|
| `ASSERT_*` | `EXPECT_*` |

Use `EXPECT_*` by default. Use `ASSERT_*` when continuing makes no sense.

### Common Assertions

```cpp
// Boolean
EXPECT_TRUE(condition);
EXPECT_FALSE(condition);

// Equality
EXPECT_EQ(val1, val2);    // val1 == val2
EXPECT_NE(val1, val2);    // val1 != val2

// Comparison
EXPECT_LT(val1, val2);    // val1 < val2
EXPECT_LE(val1, val2);    // val1 <= val2
EXPECT_GT(val1, val2);    // val1 > val2
EXPECT_GE(val1, val2);    // val1 >= val2

// Strings
EXPECT_STREQ(str1, str2);     // C strings equal
EXPECT_STRNE(str1, str2);     // C strings not equal

// Floating point
EXPECT_FLOAT_EQ(val1, val2);  // Almost equal
EXPECT_NEAR(val1, val2, abs_error);

// Exceptions
EXPECT_THROW(statement, exception_type);
EXPECT_NO_THROW(statement);

// Death tests (process termination)
EXPECT_DEATH(statement, regex);
```

## Google Mock Basics

### Creating Mocks

```cpp
#include <gmock/gmock.h>

class MockDatabase : public Database {
 public:
  MOCK_METHOD(bool, connect, (const std::string& host), (override));
  MOCK_METHOD(int, query, (const std::string& sql), (override));
  MOCK_METHOD(void, disconnect, (), (override));
};
```

### Setting Expectations

```cpp
using ::testing::Return;
using ::testing::_;

TEST(ClientTest, ConnectsToDatabase) {
  MockDatabase db;

  EXPECT_CALL(db, connect("localhost"))
      .Times(1)
      .WillOnce(Return(true));

  Client client(&db);
  EXPECT_TRUE(client.initialize());
}
```

### Common Matchers

```cpp
using ::testing::_;           // Any value
using ::testing::Eq;          // Equals
using ::testing::Ne;          // Not equals
using ::testing::Lt;          // Less than
using ::testing::Gt;          // Greater than
using ::testing::StartsWith;  // String starts with
using ::testing::HasSubstr;   // String contains
using ::testing::IsNull;      // Pointer is null
using ::testing::NotNull;     // Pointer is not null
```

## Test Naming Convention

```
TEST(ClassName, MethodName_Scenario_ExpectedBehavior)
```

Examples:
```cpp
TEST(Buffer, Write_EmptyData_DoesNothing)
TEST(Buffer, Write_ValidData_IncreasesSize)
TEST(Buffer, Read_WhenEmpty_ReturnsZero)
TEST(SharedMemory, Create_InvalidName_ReturnsError)
```

## File Organization

```
project/
├── src/
│   ├── buffer.cpp
│   └── buffer.h
├── test/
│   ├── buffer_test.cpp
│   └── shared_memory_test.cpp
└── CMakeLists.txt
```

Test files mirror source structure with `_test.cpp` suffix.

## CMake Integration

```cmake
cmake_minimum_required(VERSION 3.14.0)
project(my_project VERSION 0.1.0 LANGUAGES C CXX)

# Fetch Google Test
include(FetchContent)
FetchContent_Declare(
  googletest
  GIT_REPOSITORY https://github.com/google/googletest.git
  GIT_TAG v1.14.0
)
FetchContent_MakeAvailable(googletest)

# Main executable
add_executable(${PROJECT_NAME} main.cpp)

# Test executable
enable_testing()
add_executable(${PROJECT_NAME}_test
  test/example_test.cpp
)
target_link_libraries(${PROJECT_NAME}_test
  GTest::gtest_main
  GTest::gmock
)

# Register tests with CTest
include(GoogleTest)
gtest_discover_tests(${PROJECT_NAME}_test
  WORKING_DIRECTORY ${CMAKE_SOURCE_DIR}
  PROPERTIES
    TIMEOUT 10
)
```

## Running Tests

```bash
# Build
cmake --build build

# Run all tests
ctest --test-dir build --output-on-failure

# Run specific test
ctest --test-dir build -R "BufferTest"

# Verbose output
ctest --test-dir build -V
```

## Commit Pattern

See `cpp-commits.md` for full Conventional Commits specification.

| Phase | Commit? | Type | Reasoning |
|-------|---------|------|-----------|
| RED | No | - | Don't commit failing tests |
| GREEN | Yes | `feat` | Test + implementation together = new capability |
| REFACTOR | If changes | `refactor` | Restructure without behavior change |

**Note:** The `test` type is for adding tests to EXISTING functionality, not for TDD where tests drive NEW features.

## References

- [Google Test Documentation](https://google.github.io/googletest/)
- [Google Test GitHub](https://github.com/google/googletest)
- [Google Mock Guide](https://google.github.io/googletest/gmock_for_dummies.html)
- [GoogleTest CMake Integration](https://google.github.io/googletest/quickstart-cmake.html)
