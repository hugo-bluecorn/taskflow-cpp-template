#include "mylib/mylib.hpp"

#include <cstdint>

#include <string>

namespace mylib {

std::string Greet(const std::string& name) {
    return "Hello, " + name + "!";
}

int Add(int lhs, int rhs) {
    return lhs + rhs;
}

std::uint64_t Factorial(int num) {
    if (num <= 1) {
        return 1;
    }
    std::uint64_t result = 1;
    for (int idx = 2; idx <= num; ++idx) {
        result *= static_cast<std::uint64_t>(idx);
    }
    return result;
}

}  // namespace mylib
