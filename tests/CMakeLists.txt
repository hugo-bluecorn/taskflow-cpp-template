# Test executable
add_executable(mylib_tests
    test_mylib.cpp
)

# Link against library and GoogleTest
target_link_libraries(mylib_tests
    PRIVATE
        mylib::mylib
        GTest::gtest_main
)

# Discover tests for CTest
include(GoogleTest)
gtest_discover_tests(mylib_tests
    PROPERTIES
        LABELS "unit"
)
