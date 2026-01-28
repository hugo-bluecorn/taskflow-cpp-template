# Coverage.cmake - Code coverage support for GCC/gcov
#
# Usage:
#   cmake -DENABLE_COVERAGE=ON ..
#   cmake --build . --target coverage

if(NOT CMAKE_CXX_COMPILER_ID MATCHES "GNU")
    message(WARNING "Coverage is only supported with GCC")
    return()
endif()

# Add coverage flags
set(COVERAGE_FLAGS "-fprofile-arcs -ftest-coverage")
set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} ${COVERAGE_FLAGS}")
set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} ${COVERAGE_FLAGS}")
set(CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} ${COVERAGE_FLAGS}")

# Find required tools
find_program(GCOV_PATH gcov)
find_program(LCOV_PATH lcov)
find_program(GENHTML_PATH genhtml)

if(NOT GCOV_PATH)
    message(FATAL_ERROR "gcov not found! Install it to enable coverage.")
endif()

if(NOT LCOV_PATH)
    message(FATAL_ERROR "lcov not found! Install it to enable coverage.")
endif()

if(NOT GENHTML_PATH)
    message(FATAL_ERROR "genhtml not found! Install it to enable coverage.")
endif()

# Create coverage target
add_custom_target(coverage
    COMMAND ${LCOV_PATH} --directory . --zerocounters
    COMMAND ${CMAKE_CTEST_COMMAND} --output-on-failure
    COMMAND ${LCOV_PATH} --directory . --capture --output-file coverage.info
    COMMAND ${LCOV_PATH} --remove coverage.info '/usr/*' '*/tests/*' '*/googletest/*' --output-file coverage.info.cleaned
    COMMAND ${GENHTML_PATH} -o coverage coverage.info.cleaned
    COMMAND ${CMAKE_COMMAND} -E remove coverage.info coverage.info.cleaned
    WORKING_DIRECTORY ${CMAKE_BINARY_DIR}
    COMMENT "Running tests and generating coverage report..."
)

message(STATUS "Coverage enabled. Use 'cmake --build . --target coverage' to generate report.")
