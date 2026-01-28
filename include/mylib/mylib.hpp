#ifndef MYLIB_MYLIB_HPP
#define MYLIB_MYLIB_HPP

#include <cstdint>

#include <string>

namespace mylib {

// Returns a greeting message for the given name.
std::string Greet(const std::string& name);

// Adds two integers and returns the result.
int Add(int lhs, int rhs);

// Computes the factorial of num.
// Precondition: num >= 0
std::uint64_t Factorial(int num);

}  // namespace mylib

#endif  // MYLIB_MYLIB_HPP
