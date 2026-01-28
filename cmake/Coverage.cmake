# Coverage.cmake - Code coverage support for Clang/llvm-cov
#
# Usage:
#   cmake -DENABLE_COVERAGE=ON ..
#   cmake --build . --target coverage

if(NOT CMAKE_CXX_COMPILER_ID MATCHES "Clang")
    message(WARNING "Coverage is only supported with Clang")
    return()
endif()

# Add coverage flags for Clang
set(COVERAGE_FLAGS "-fprofile-instr-generate -fcoverage-mapping")
set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} ${COVERAGE_FLAGS}")
set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} ${COVERAGE_FLAGS}")
set(CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} ${COVERAGE_FLAGS}")

# Find required tools
find_program(LLVM_PROFDATA_PATH llvm-profdata)
find_program(LLVM_COV_PATH llvm-cov)

if(NOT LLVM_PROFDATA_PATH)
    message(FATAL_ERROR "llvm-profdata not found! Install llvm package.")
endif()

if(NOT LLVM_COV_PATH)
    message(FATAL_ERROR "llvm-cov not found! Install llvm package.")
endif()

# Set profile output path
set(PROFILE_RAW "${CMAKE_BINARY_DIR}/default.profraw")
set(PROFILE_DATA "${CMAKE_BINARY_DIR}/default.profdata")

# Create coverage target
add_custom_target(coverage
    # Clean previous coverage data
    COMMAND ${CMAKE_COMMAND} -E rm -f ${PROFILE_RAW} ${PROFILE_DATA}

    # Run tests with profiling enabled
    COMMAND ${CMAKE_COMMAND} -E env "LLVM_PROFILE_FILE=${PROFILE_RAW}"
            ${CMAKE_CTEST_COMMAND} --output-on-failure

    # Merge profile data
    COMMAND ${LLVM_PROFDATA_PATH} merge -sparse ${PROFILE_RAW} -o ${PROFILE_DATA}

    # Generate HTML report (only for src/ and include/ directories)
    COMMAND ${LLVM_COV_PATH} show
            $<TARGET_FILE:mylib_tests>
            -instr-profile=${PROFILE_DATA}
            -format=html
            -output-dir=${CMAKE_BINARY_DIR}/coverage
            -show-line-counts-or-regions
            -show-instantiations=false
            ${CMAKE_SOURCE_DIR}/src
            ${CMAKE_SOURCE_DIR}/include

    # Print summary to console
    COMMAND ${LLVM_COV_PATH} report
            $<TARGET_FILE:mylib_tests>
            -instr-profile=${PROFILE_DATA}
            ${CMAKE_SOURCE_DIR}/src
            ${CMAKE_SOURCE_DIR}/include

    WORKING_DIRECTORY ${CMAKE_BINARY_DIR}
    COMMENT "Running tests and generating coverage report..."
    DEPENDS mylib_tests
)

message(STATUS "Coverage enabled. Use 'cmake --build . --target coverage' to generate report.")
