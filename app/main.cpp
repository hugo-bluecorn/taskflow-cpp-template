#include <iostream>
#include <mylib/mylib.hpp>

int main() {
    std::cout << mylib::Greet("World") << '\n';
    std::cout << "2 + 3 = " << mylib::Add(2, 3) << '\n';
    std::cout << "5! = " << mylib::Factorial(5) << '\n';
    return 0;
}
