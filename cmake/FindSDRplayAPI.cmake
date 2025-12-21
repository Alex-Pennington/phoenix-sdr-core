# FindSDRplayAPI.cmake
# Locate the SDRplay API SDK
#
# This module defines:
#   SDRplayAPI_FOUND        - True if SDRplay API was found
#   SDRplayAPI_INCLUDE_DIRS - Include directories
#   SDRplayAPI_LIBRARIES    - Libraries to link
#   SDRplayAPI_DLL          - Runtime DLL (Windows)
#
# User can set SDRplayAPI_ROOT to hint the search location

# Default install locations
if(WIN32)
    set(_SDRPLAY_DEFAULT_PATH "C:/Program Files/SDRplay/API")
else()
    set(_SDRPLAY_DEFAULT_PATH "/usr/local")
endif()

# Find include directory
find_path(SDRplayAPI_INCLUDE_DIR
    NAMES sdrplay_api.h
    HINTS
        ${SDRplayAPI_ROOT}
        ENV SDRplayAPI_ROOT
        ${_SDRPLAY_DEFAULT_PATH}
    PATH_SUFFIXES
        inc
        include
)

# Find library
if(WIN32)
    # Windows: look for import library
    find_library(SDRplayAPI_LIBRARY
        NAMES sdrplay_api
        HINTS
            ${SDRplayAPI_ROOT}
            ENV SDRplayAPI_ROOT
            ${_SDRPLAY_DEFAULT_PATH}
        PATH_SUFFIXES
            x64
            x86
            lib
    )
    
    # Find the DLL for runtime
    find_file(SDRplayAPI_DLL
        NAMES sdrplay_api.dll
        HINTS
            ${SDRplayAPI_ROOT}
            ENV SDRplayAPI_ROOT
            ${_SDRPLAY_DEFAULT_PATH}
        PATH_SUFFIXES
            x64
            x86
            bin
    )
else()
    # Linux/macOS: shared library
    find_library(SDRplayAPI_LIBRARY
        NAMES sdrplay_api
        HINTS
            ${SDRplayAPI_ROOT}
            ENV SDRplayAPI_ROOT
            ${_SDRPLAY_DEFAULT_PATH}
        PATH_SUFFIXES
            lib
            lib64
    )
endif()

# Standard CMake handling
include(FindPackageHandleStandardArgs)
find_package_handle_standard_args(SDRplayAPI
    REQUIRED_VARS
        SDRplayAPI_LIBRARY
        SDRplayAPI_INCLUDE_DIR
)

if(SDRplayAPI_FOUND)
    set(SDRplayAPI_INCLUDE_DIRS ${SDRplayAPI_INCLUDE_DIR})
    set(SDRplayAPI_LIBRARIES ${SDRplayAPI_LIBRARY})
    
    # Create imported target
    if(NOT TARGET SDRplay::API)
        add_library(SDRplay::API SHARED IMPORTED)
        set_target_properties(SDRplay::API PROPERTIES
            IMPORTED_LOCATION "${SDRplayAPI_DLL}"
            IMPORTED_IMPLIB "${SDRplayAPI_LIBRARY}"
            INTERFACE_INCLUDE_DIRECTORIES "${SDRplayAPI_INCLUDE_DIR}"
        )
    endif()
endif()

mark_as_advanced(
    SDRplayAPI_INCLUDE_DIR
    SDRplayAPI_LIBRARY
    SDRplayAPI_DLL
)
