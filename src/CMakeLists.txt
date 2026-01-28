# Library target
add_library(mylib
    mylib.cpp
)

# Public headers for consumers
target_include_directories(mylib
    PUBLIC
        $<BUILD_INTERFACE:${CMAKE_SOURCE_DIR}/include>
        $<INSTALL_INTERFACE:include>
)

# Link to Taskflow (includes threading automatically)
target_link_libraries(mylib PUBLIC Taskflow::Taskflow)

# Alias for consistent usage
add_library(mylib::mylib ALIAS mylib)
