# Phoenix SDR Core - CMake Build System
# Requires: SDRplay API v3.x installed by user
# Build: cmake -B build && cmake --build build

cmake_minimum_required(VERSION 3.16)

project(phoenix-sdr-core
    VERSION 0.1.0
    DESCRIPTION "SDRplay RSP2 Pro hardware interface for Phoenix Nest"
    LANGUAGES C
)

# Options
option(BUILD_TESTS "Build unit tests" ON)
option(REQUIRE_SDRPLAY "Require SDRplay API (fail if not found)" OFF)

# C standard
set(CMAKE_C_STANDARD 17)
set(CMAKE_C_STANDARD_REQUIRED ON)

# Add cmake modules path
list(APPEND CMAKE_MODULE_PATH "${CMAKE_CURRENT_SOURCE_DIR}/cmake")

# Compiler warnings
if(MSVC)
    add_compile_options(/W4)
else()
    add_compile_options(-Wall -Wextra -pedantic)
endif()

# Debug/Release flags
if(CMAKE_BUILD_TYPE STREQUAL "Debug")
    add_compile_definitions(_DEBUG)
else()
    add_compile_definitions(NDEBUG)
endif()

#============================================================================
# Dependencies
#============================================================================

# SDRplay API (user-installed)
find_package(SDRplayAPI)

if(SDRplayAPI_FOUND)
    message(STATUS "SDRplay API found: ${SDRplayAPI_INCLUDE_DIR}")
    message(STATUS "SDRplay library: ${SDRplayAPI_LIBRARY}")
else()
    if(REQUIRE_SDRPLAY)
        message(FATAL_ERROR "SDRplay API not found. Install from https://www.sdrplay.com/downloads/")
    else()
        message(WARNING "SDRplay API not found - building stub version for CI")
        message(STATUS "Install SDRplay API from https://www.sdrplay.com/downloads/")
    endif()
endif()

# kiss_fft (submodule)
if(EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/external/kiss_fft/src/kiss_fft.c")
    set(KISS_FFT_SOURCES
        external/kiss_fft/src/kiss_fft.c
    )
    set(KISS_FFT_INCLUDE_DIR "${CMAKE_CURRENT_SOURCE_DIR}/external/kiss_fft/include")
    message(STATUS "Using kiss_fft from external/kiss_fft/src/")
else()
    message(FATAL_ERROR "kiss_fft not found. Run: git submodule update --init")
endif()

#============================================================================
# Version header generation
#============================================================================

# Get git info
find_package(Git QUIET)
if(GIT_FOUND)
    execute_process(
        COMMAND ${GIT_EXECUTABLE} rev-parse --short HEAD
        WORKING_DIRECTORY ${CMAKE_SOURCE_DIR}
        OUTPUT_VARIABLE GIT_COMMIT
        OUTPUT_STRIP_TRAILING_WHITESPACE
        ERROR_QUIET
    )
    execute_process(
        COMMAND ${GIT_EXECUTABLE} status --porcelain
        WORKING_DIRECTORY ${CMAKE_SOURCE_DIR}
        OUTPUT_VARIABLE GIT_STATUS
        OUTPUT_STRIP_TRAILING_WHITESPACE
        ERROR_QUIET
    )
    if(GIT_STATUS)
        set(GIT_DIRTY true)
        set(GIT_DIRTY_STR "-dirty")
    else()
        set(GIT_DIRTY false)
        set(GIT_DIRTY_STR "")
    endif()
else()
    set(GIT_COMMIT "unknown")
    set(GIT_DIRTY false)
    set(GIT_DIRTY_STR "")
endif()

# Configure version header
configure_file(
    "${CMAKE_CURRENT_SOURCE_DIR}/cmake/version.h.in"
    "${CMAKE_CURRENT_BINARY_DIR}/include/version.h"
    @ONLY
)

#============================================================================
# Libraries
#============================================================================

# Core SDR library (static)
add_library(phoenix_sdr_core STATIC
    src/sdr_device.c
    src/sdr_stream.c
    src/decimator.c
    src/tcp_commands.c
    ${KISS_FFT_SOURCES}
)

target_include_directories(phoenix_sdr_core PUBLIC
    ${CMAKE_CURRENT_SOURCE_DIR}/include
    ${KISS_FFT_INCLUDE_DIR}
    ${CMAKE_CURRENT_BINARY_DIR}/include
)

if(SDRplayAPI_FOUND)
    target_include_directories(phoenix_sdr_core PUBLIC ${SDRplayAPI_INCLUDE_DIRS})
    target_link_libraries(phoenix_sdr_core PUBLIC ${SDRplayAPI_LIBRARIES})
    target_compile_definitions(phoenix_sdr_core PUBLIC HAS_SDRPLAY_API)
else()
    # Stub mode - use local header copy for compilation
    target_include_directories(phoenix_sdr_core PUBLIC ${CMAKE_CURRENT_SOURCE_DIR}/include/sdrplay)
    target_compile_definitions(phoenix_sdr_core PUBLIC SDRPLAY_STUB_MODE)
endif()

# Platform libraries
if(WIN32)
    target_link_libraries(phoenix_sdr_core PUBLIC ws2_32 winmm)
else()
    target_link_libraries(phoenix_sdr_core PUBLIC m pthread)
endif()

#============================================================================
# Executables
#============================================================================

# Main SDR server (only if SDRplay API available)
if(SDRplayAPI_FOUND)
    add_executable(sdr_server src/main.c)
    target_link_libraries(sdr_server PRIVATE phoenix_sdr_core)
    
    # Copy DLL to output (Windows)
    if(WIN32 AND SDRplayAPI_DLL)
        add_custom_command(TARGET sdr_server POST_BUILD
            COMMAND ${CMAKE_COMMAND} -E copy_if_different
                "${SDRplayAPI_DLL}"
                "$<TARGET_FILE_DIR:sdr_server>"
            COMMENT "Copying sdrplay_api.dll"
        )
    endif()
    
    install(TARGETS sdr_server RUNTIME DESTINATION bin)
endif()

#============================================================================
# Tests
#============================================================================

if(BUILD_TESTS)
    enable_testing()
    
    # Test: TCP command parser
    add_executable(test_tcp_commands
        test/test_tcp_commands.c
        test/sdr_stubs.c
    )
    target_link_libraries(test_tcp_commands PRIVATE phoenix_sdr_core)
    target_include_directories(test_tcp_commands PRIVATE test)
    add_test(NAME tcp_commands COMMAND test_tcp_commands)
endif()

#============================================================================
# Install
#============================================================================

install(TARGETS phoenix_sdr_core
    ARCHIVE DESTINATION lib
    LIBRARY DESTINATION lib
)

install(DIRECTORY include/
    DESTINATION include/phoenix_sdr
    FILES_MATCHING PATTERN "*.h"
)

install(FILES ${CMAKE_CURRENT_BINARY_DIR}/include/version.h
    DESTINATION include/phoenix_sdr
)

#============================================================================
# Summary
#============================================================================

message(STATUS "")
message(STATUS "Phoenix SDR Core v${PROJECT_VERSION}")
message(STATUS "  SDRplay API: ${SDRplayAPI_FOUND}")
message(STATUS "  Build tests: ${BUILD_TESTS}")
message(STATUS "  Git commit:  ${GIT_COMMIT}${GIT_DIRTY_STR}")
message(STATUS "")
