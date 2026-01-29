#include <gtest/gtest.h>

#include "mylib/mylib.hpp"

namespace mylib {
namespace {

// Simple smoke test - verifies the library links and runs.
// Replace with actual tests when you implement your features.
TEST(MyLibTest, PrintGreetingRuns) {
    // Act & Assert: Should not throw or crash
    EXPECT_NO_THROW(PrintGreeting());
}

}  // namespace
}  // namespace mylib
