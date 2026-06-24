cmake_policy(SET CMP0048 NEW)
project(
  ${SKBUILD_PROJECT_NAME}
  VERSION ${SKBUILD_PROJECT_VERSION}
  LANGUAGES CXX)

cmake_minimum_required(VERSION 3.15...3.27)

option(BUILD_PYTHON_BINDING "Build Python Binding" off)


set(CMAKE_POSITION_INDEPENDENT_CODE ON)

set(CMAKE_CXX_STANDARD 17)

link_libraries(booster_robotics_sdk.a fastrtps fastcdr libfoonathan_memory-0.7.3.a)

add_executable(b1_loco_example_client example/high_level/b1_loco_example_client.cpp)
add_executable(b1_arm_sdk_example_client example/high_level/b1_arm_sdk_example.cpp)
add_executable(b1_7dof_arm_sdk_example_client example/high_level/b1_7dof_arm_sdk_example.cpp)
add_executable(b1_low_level_publisher example/low_level/low_level_publisher.cpp)
add_executable(b1_low_level_subscriber example/low_level/low_level_subscriber.cpp)
add_executable(low_level_hand_data_subscriber example/low_level/low_level_hand_data_subscriber.cpp)
add_executable(b1_low_sdk_example example/low_level/b1_low_sdk_example.cpp)
add_executable(b1_7dof_arm_low_sdk_example example/low_level/b1_7dof_arm_low_sdk_example.cpp)
add_executable(odometer_example example/low_level/odometer_example.cpp)


include_directories(BEFORE $(PROJECT_SOURCE_DIR)/include)

if(BUILD_PYTHON_BINDING)
    find_package(Python3 REQUIRED COMPONENTS Interpreter Development.Module)
    message(STATUS "Python3 executable: ${Python3_EXECUTABLE}")

    execute_process(
        COMMAND ${Python3_EXECUTABLE} -c "import sysconfig; print(sysconfig.get_paths()['purelib'])"
        OUTPUT_VARIABLE PYTHON_SITE_PACKAGES
        OUTPUT_STRIP_TRAILING_WHITESPACE
    )

    include_directories(${Python3_INCLUDE_DIRS})
    
    # Use pip-installed pybind11 instead of system package
    execute_process(
        COMMAND ${Python3_EXECUTABLE} -c "import pybind11; print(pybind11.get_cmake_dir())"
        OUTPUT_VARIABLE pybind11_DIR
        OUTPUT_STRIP_TRAILING_WHITESPACE
    )
    find_package(pybind11 CONFIG REQUIRED HINTS ${pybind11_DIR})

    python3_add_library(booster_robotics_sdk_python MODULE python/binding.cpp WITH_SOABI)

    target_compile_definitions(booster_robotics_sdk_python PRIVATE VERSION_INFO=${PROJECT_VERSION})

    find_program(PYBIND11_STUBGEN_EXECUTABLE pybind11-stubgen)

    # Best-effort type-stub generation. This is wrapped so it never fails the
    # build: during wheel builds (cibuildwheel) the freshly linked module is not
    # yet importable from the build tree (its vendored DDS .so dependencies are
    # staged into the package dir afterwards), and the wheel's stubs are produced
    # separately by scripts/cibw_before_build.sh. `${CMAKE_BINARY_DIR}` is used
    # (not a hardcoded `build/`) so this works for any build directory name.
    if(PYBIND11_STUBGEN_EXECUTABLE)
        add_custom_command(
            TARGET booster_robotics_sdk_python
            POST_BUILD
            COMMAND ${CMAKE_COMMAND} -E env PYTHONPATH=${CMAKE_BINARY_DIR}:$ENV{PYTHONPATH}
                    ${PYBIND11_STUBGEN_EXECUTABLE} -o ${CMAKE_BINARY_DIR} booster_robotics_sdk_python || true
            VERBATIM
        )
    endif()

    install(TARGETS booster_robotics_sdk_python LIBRARY DESTINATION ${PYTHON_SITE_PACKAGES})
    # Install the stub file only if it was actually generated (it is optional).
    install(FILES ${CMAKE_BINARY_DIR}/booster_robotics_sdk_python.pyi
            DESTINATION ${PYTHON_SITE_PACKAGES} OPTIONAL)
endif()

