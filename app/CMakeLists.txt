# Executable target
add_executable(${PROJECT_NAME}_app
    main.cpp
)

# Link against library
target_link_libraries(${PROJECT_NAME}_app
    PRIVATE
        mylib::mylib
)
