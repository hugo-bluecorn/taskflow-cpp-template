# GoogleTest Reference

Comprehensive reference for Google Test (gtest) and Google Mock (gmock).

## Assertions

### EXPECT vs ASSERT

| Type | Behavior on Failure |
|------|---------------------|
| `EXPECT_*` | Continue test execution (non-fatal) |
| `ASSERT_*` | Abort current test (fatal) |

Use `EXPECT_*` by default. Use `ASSERT_*` when continuing makes no sense (e.g., null pointer).

### Boolean Assertions

```cpp
EXPECT_TRUE(condition);
EXPECT_FALSE(condition);
```

### Comparison Assertions

```cpp
// Equality
EXPECT_EQ(expected, actual);    // ==
EXPECT_NE(val1, val2);          // !=

// Relational
EXPECT_LT(val1, val2);          // <
EXPECT_LE(val1, val2);          // <=
EXPECT_GT(val1, val2);          // >
EXPECT_GE(val1, val2);          // >=
```

### String Assertions

```cpp
// C strings (char*)
EXPECT_STREQ(str1, str2);       // Equal
EXPECT_STRNE(str1, str2);       // Not equal
EXPECT_STRCASEEQ(str1, str2);   // Case-insensitive equal
EXPECT_STRCASENE(str1, str2);   // Case-insensitive not equal

// std::string (use EXPECT_EQ)
EXPECT_EQ(std::string("hello"), actual);
```

### Floating-Point Assertions

```cpp
EXPECT_FLOAT_EQ(expected, actual);    // 4 ULPs tolerance
EXPECT_DOUBLE_EQ(expected, actual);   // 4 ULPs tolerance
EXPECT_NEAR(val1, val2, abs_error);   // Custom tolerance
```

### Exception Assertions

```cpp
EXPECT_THROW(statement, exception_type);   // Throws specific exception
EXPECT_ANY_THROW(statement);               // Throws any exception
EXPECT_NO_THROW(statement);                // Throws nothing
```

### Death Tests

```cpp
// Process terminates
EXPECT_DEATH(statement, regex);
EXPECT_DEATH_IF_SUPPORTED(statement, regex);

// Process exits with code
EXPECT_EXIT(statement, ::testing::ExitedWithCode(0), regex);
```

## Test Fixtures

### Basic Fixture

```cpp
class MyTest : public ::testing::Test {
 protected:
  void SetUp() override {
    // Called before each test
    obj_ = std::make_unique<MyClass>();
  }

  void TearDown() override {
    // Called after each test
    obj_.reset();
  }

  // Shared resources
  std::unique_ptr<MyClass> obj_;
};

TEST_F(MyTest, TestName) {
  // Use obj_ here
  EXPECT_TRUE(obj_->IsValid());
}
```

### SetUpTestSuite / TearDownTestSuite

```cpp
class ExpensiveTest : public ::testing::Test {
 protected:
  static void SetUpTestSuite() {
    // Called once before all tests in this fixture
    shared_resource_ = new ExpensiveResource();
  }

  static void TearDownTestSuite() {
    // Called once after all tests in this fixture
    delete shared_resource_;
    shared_resource_ = nullptr;
  }

  static ExpensiveResource* shared_resource_;
};

ExpensiveResource* ExpensiveTest::shared_resource_ = nullptr;
```

## Parameterized Tests

### Value-Parameterized Tests

```cpp
class AddTest : public ::testing::TestWithParam<std::tuple<int, int, int>> {};

TEST_P(AddTest, AddsNumbers) {
  auto [a, b, expected] = GetParam();
  EXPECT_EQ(add(a, b), expected);
}

INSTANTIATE_TEST_SUITE_P(
    AdditionTests,
    AddTest,
    ::testing::Values(
        std::make_tuple(1, 1, 2),
        std::make_tuple(2, 3, 5),
        std::make_tuple(-1, 1, 0)
    )
);
```

### Combine Parameters

```cpp
INSTANTIATE_TEST_SUITE_P(
    CombinedTests,
    MyTest,
    ::testing::Combine(
        ::testing::Values(1, 2, 3),
        ::testing::Bool(),
        ::testing::Values("a", "b")
    )
);
```

### Range Parameters

```cpp
INSTANTIATE_TEST_SUITE_P(
    RangeTests,
    MyTest,
    ::testing::Range(0, 10, 2)  // 0, 2, 4, 6, 8
);
```

## Typed Tests

### Type-Parameterized Tests

```cpp
template <typename T>
class ContainerTest : public ::testing::Test {
 public:
  using List = std::list<T>;
  static T shared_;
  T value_;
};

using MyTypes = ::testing::Types<int, float, std::string>;
TYPED_TEST_SUITE(ContainerTest, MyTypes);

TYPED_TEST(ContainerTest, DoesBlah) {
  // TypeParam is the current type
  TypeParam value = this->value_;
  EXPECT_EQ(value, value);
}
```

## Google Mock

### Creating Mocks

```cpp
#include <gmock/gmock.h>

class MockDatabase : public Database {
 public:
  MOCK_METHOD(bool, Connect, (const std::string& host), (override));
  MOCK_METHOD(int, Query, (const std::string& sql), (override));
  MOCK_METHOD(void, Disconnect, (), (override));

  // Const methods
  MOCK_METHOD(int, GetCount, (), (const, override));

  // Methods with default arguments
  MOCK_METHOD(void, Configure, (int timeout, bool retry), (override));
};
```

### Setting Expectations

```cpp
using ::testing::Return;
using ::testing::_;

TEST(ClientTest, ConnectsToDatabase) {
  MockDatabase db;

  // Expect specific call
  EXPECT_CALL(db, Connect("localhost"))
      .Times(1)
      .WillOnce(Return(true));

  // Expect any argument
  EXPECT_CALL(db, Query(_))
      .WillRepeatedly(Return(42));

  Client client(&db);
  EXPECT_TRUE(client.Initialize());
}
```

### Cardinalities

```cpp
EXPECT_CALL(mock, Method(_))
    .Times(0);                    // Never called
    .Times(1);                    // Exactly once
    .Times(AtLeast(n));          // n or more
    .Times(AtMost(n));           // n or fewer
    .Times(Between(m, n));       // Between m and n (inclusive)
    .Times(AnyNumber());         // Any number of times
```

### Actions

```cpp
using ::testing::Return;
using ::testing::ReturnRef;
using ::testing::Throw;
using ::testing::DoAll;
using ::testing::SetArgPointee;
using ::testing::SaveArg;

EXPECT_CALL(mock, Method(_))
    .WillOnce(Return(42));                       // Return value
    .WillOnce(ReturnRef(ref));                   // Return reference
    .WillOnce(Throw(std::runtime_error("!")));   // Throw exception
    .WillOnce(DoAll(SaveArg<0>(&saved), Return(true)));  // Multiple actions
    .WillOnce(SetArgPointee<0>(42));             // Set pointed value
```

### Matchers

```cpp
using ::testing::_;             // Any value
using ::testing::Eq;            // Equals
using ::testing::Ne;            // Not equals
using ::testing::Lt;            // Less than
using ::testing::Le;            // Less or equal
using ::testing::Gt;            // Greater than
using ::testing::Ge;            // Greater or equal
using ::testing::IsNull;        // Pointer is null
using ::testing::NotNull;       // Pointer is not null
using ::testing::Ref;           // Same reference
using ::testing::TypedEq<T>;    // Type-specific equality

// String matchers
using ::testing::StartsWith;
using ::testing::EndsWith;
using ::testing::HasSubstr;
using ::testing::MatchesRegex;
using ::testing::ContainsRegex;

// Container matchers
using ::testing::Contains;
using ::testing::Each;
using ::testing::ElementsAre;
using ::testing::UnorderedElementsAre;
using ::testing::IsEmpty;
using ::testing::SizeIs;
```

### Matcher Examples

```cpp
EXPECT_CALL(mock, Method(StartsWith("prefix")));
EXPECT_CALL(mock, Method(HasSubstr("middle")));
EXPECT_CALL(mock, Process(ElementsAre(1, 2, 3)));
EXPECT_CALL(mock, SetItems(Contains(42)));
EXPECT_CALL(mock, GetList(SizeIs(Gt(5))));
```

### Nice, Strict, and Naggy Mocks

```cpp
// Default: warns on unexpected calls
MockDatabase mock;

// Nice: ignores unexpected calls
::testing::NiceMock<MockDatabase> nice_mock;

// Strict: fails on unexpected calls
::testing::StrictMock<MockDatabase> strict_mock;
```

## Test Execution Options

### Command-Line Flags

```bash
# Run specific tests
./test_executable --gtest_filter="TestSuite.TestName"
./test_executable --gtest_filter="*Pattern*"
./test_executable --gtest_filter="-ExcludeThis*"

# Repeat tests
./test_executable --gtest_repeat=10
./test_executable --gtest_repeat=-1  # Forever until failure

# Shuffle tests
./test_executable --gtest_shuffle
./test_executable --gtest_random_seed=12345

# Output formats
./test_executable --gtest_output=xml:report.xml
./test_executable --gtest_output=json:report.json

# List tests without running
./test_executable --gtest_list_tests

# Break on failure (for debugging)
./test_executable --gtest_break_on_failure

# Disable colored output
./test_executable --gtest_color=no
```

### Filtering Examples

```bash
# Run all tests in a suite
--gtest_filter="BufferTest.*"

# Run specific test
--gtest_filter="BufferTest.WriteRead"

# Run tests matching pattern
--gtest_filter="*Memory*"

# Exclude tests
--gtest_filter="-*Slow*"

# Combine include and exclude
--gtest_filter="BufferTest.*:-*Slow*"
```

## CMake Integration

### FetchContent

```cmake
include(FetchContent)
FetchContent_Declare(
    googletest
    GIT_REPOSITORY https://github.com/google/googletest.git
    GIT_TAG        e39786088138f2749d64e9571571e7a5d79ce4e6  # v1.14.0
)
FetchContent_MakeAvailable(googletest)
```

### Linking

```cmake
add_executable(my_test test.cpp)
target_link_libraries(my_test
    PRIVATE
        GTest::gtest_main    # Provides main()
        GTest::gmock         # Google Mock
)
```

### Test Discovery

```cmake
include(GoogleTest)
gtest_discover_tests(my_test
    WORKING_DIRECTORY ${CMAKE_SOURCE_DIR}
    PROPERTIES
        TIMEOUT 10
        LABELS "unit"
)
```

### Running Tests

```bash
# Build and run
cmake --build build
ctest --test-dir build --output-on-failure

# Run specific tests
ctest --test-dir build -R "BufferTest"

# Run by label
ctest --test-dir build -L unit

# Verbose output
ctest --test-dir build -V
```

## Best Practices

### Test Organization

1. **One assertion per test** when possible
2. **Descriptive test names**: `MethodName_Condition_ExpectedBehavior`
3. **AAA pattern**: Arrange, Act, Assert
4. **Independent tests**: No dependencies between tests

### Fixture Guidelines

1. Use fixtures for shared setup/teardown
2. Keep fixtures focused and minimal
3. Use `SetUpTestSuite` sparingly (for expensive resources)
4. Clean up in `TearDown` (RAII is better)

### Mock Guidelines

1. Mock external dependencies, not internal implementation
2. Prefer `NiceMock` for tests with many expectations
3. Use `EXPECT_CALL` before the action that triggers it
4. Verify mocks are called (use `testing::Mock::VerifyAndClearExpectations`)

### Naming Conventions

```cpp
// Test suite matches class name
class BufferTest : public ::testing::Test {};

// Test names describe behavior
TEST_F(BufferTest, Write_EmptyData_ReturnsZero)
TEST_F(BufferTest, Write_ValidData_IncreasesSize)
TEST_F(BufferTest, Read_WhenEmpty_ReturnsZero)
```

## References

- [GoogleTest Primer](https://google.github.io/googletest/primer.html)
- [GoogleTest Advanced](https://google.github.io/googletest/advanced.html)
- [GoogleMock for Dummies](https://google.github.io/googletest/gmock_for_dummies.html)
- [GoogleMock Cookbook](https://google.github.io/googletest/gmock_cook_book.html)
- [Matchers Reference](https://google.github.io/googletest/reference/matchers.html)
- [Actions Reference](https://google.github.io/googletest/reference/actions.html)
