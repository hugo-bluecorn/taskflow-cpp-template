#include <gtest/gtest.h>
#include <mylib/mylib.hpp>

namespace mylib {
namespace {

TEST(GreetTest, ReturnsGreetingWithName) {
    EXPECT_EQ(Greet("World"), "Hello, World!");
    EXPECT_EQ(Greet("Alice"), "Hello, Alice!");
}

TEST(GreetTest, HandlesEmptyName) {
    EXPECT_EQ(Greet(""), "Hello, !");
}

TEST(AddTest, AddsTwoPositiveNumbers) {
    EXPECT_EQ(Add(2, 3), 5);
    EXPECT_EQ(Add(0, 0), 0);
}

TEST(AddTest, HandlesNegativeNumbers) {
    EXPECT_EQ(Add(-1, 1), 0);
    EXPECT_EQ(Add(-5, -3), -8);
}

TEST(FactorialTest, ComputesFactorial) {
    EXPECT_EQ(Factorial(0), 1);
    EXPECT_EQ(Factorial(1), 1);
    EXPECT_EQ(Factorial(5), 120);
    EXPECT_EQ(Factorial(10), 3628800);
}

}  // namespace
}  // namespace mylib
