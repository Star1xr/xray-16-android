include_guard()

if (APPLE)
    if (NOT CMAKE_OSX_DEPLOYMENT_TARGET)
        if ($ENV{MACOSX_DEPLOYMENT_TARGET})
            set(CMAKE_OSX_DEPLOYMENT_TARGET $ENV{MACOSX_DEPLOYMENT_TARGET})
        else()
            message(NOTICE "CMAKE_OSX_DEPLOYMENT_TARGET is not set, defaulting it to your system's version: ${CMAKE_SYSTEM_VERSION}")
            set(CMAKE_OSX_DEPLOYMENT_TARGET ${CMAKE_SYSTEM_VERSION})
        endif()
    endif()
    message(STATUS "CMAKE_OSX_DEPLOYMENT_TARGET: ${CMAKE_OSX_DEPLOYMENT_TARGET}")
endif()

# Redirecting the default installation path /usr/local to /usr no need to use -DCMAKE_INSTALL_PREFIX =/usr
if (CMAKE_INSTALL_PREFIX_INITIALIZED_TO_DEFAULT AND NOT ANDROID)
    set(CMAKE_INSTALL_PREFIX "/usr")
endif()

include(GNUInstallDirs)

if (DISABLE_PORTABLE_MODE)
    add_compile_definitions(DISABLE_PORTABLE_MODE)
endif()

set(CMAKE_BUILD_RPATH_USE_ORIGIN TRUE)
set(CMAKE_MACOSX_RPATH TRUE)

find_program(CCACHE_FOUND ccache)
if (CCACHE_FOUND)
    set_property(GLOBAL PROPERTY RULE_LAUNCH_COMPILE ccache)
    set_property(GLOBAL PROPERTY RULE_LAUNCH_LINK ccache)
    set(ENV{CCACHE_SLOPPINESS} pch_defines,time_macros)
endif ()

if (CMAKE_CXX_COMPILER_ID MATCHES "GNU")
    if (CMAKE_CXX_COMPILER_VERSION VERSION_LESS 8.0)
        message(FATAL_ERROR "Building with a gcc version less than 8.0 is not supported.")
    endif()
elseif (CMAKE_CXX_COMPILER_ID MATCHES "Clang")
    # XXX: Remove -fdelayed-template-parsing
    add_compile_options(
        -fdelayed-template-parsing
        -Wno-unused-command-line-argument
        -Wno-inconsistent-missing-override
    )
endif()

if (CMAKE_CXX_COMPILER_ID MATCHES "Clang" AND NOT XRAY_USE_DEFAULT_CXX_LIB)
    if (NOT XRAY_CXX_LIB)
        include(CheckCXXCompilerFlag)
        CHECK_CXX_COMPILER_FLAG("-stdlib=libc++" LIBCPP_AVAILABLE)
        CHECK_CXX_COMPILER_FLAG("-stdlib=libstdc++" LIBSTDCPP_AVAILABLE)

        if (LIBCPP_AVAILABLE)
            set(XRAY_CXX_LIB "libc++" CACHE STRING "" FORCE)
        elseif (LIBSTDCPP_AVAILABLE)
            set(XRAY_CXX_LIB "libstdc++" CACHE STRING "" FORCE)
        else()
            message("Neither libstdc++ nor libc++ are available. Hopefully, system has another custom stdlib?")
        endif()
    endif()

    if (XRAY_CXX_LIB STREQUAL "libstdc++")
        add_compile_options(-stdlib=libstdc++)
        add_link_options(-stdlib=libstdc++)
    elseif (XRAY_CXX_LIB STREQUAL "libc++")
        add_compile_options(-stdlib=libc++)
        add_link_options(-stdlib=libc++)
        if (CMAKE_SYSTEM_NAME STREQUAL "FreeBSD")
            add_compile_options(-lcxxrt)
            add_link_options(-lcxxrt)
        else()
            add_compile_options(-lc++abi)
            add_link_options(-lc++abi)
        endif()
    endif()
endif()

add_compile_options(-Wno-attributes)
if (APPLE)
    add_compile_options(-Wl,-undefined,error)
else()
    add_compile_options(-Wl,--no-undefined)
endif()

# TODO test
if (XRAY_USE_ASAN)
    add_compile_options(
        -fsanitize=address
        -fsanitize=leak
        -fsanitize=undefined
        -fno-omit-frame-pointer
        -fno-optimize-sibling-calls
        -fno-sanitize=vptr
    )

    add_link_options(
        $<$<CXX_COMPILER_ID:Clang>:-shared-libasan>
        -fsanitize=address
        -fsanitize=leak
        -fsanitize=undefined
    )
endif()

if (CMAKE_SYSTEM_PROCESSOR STREQUAL "aarch64" OR CMAKE_SYSTEM_PROCESSOR STREQUAL "arm64")
    set(PROJECT_PLATFORM_ARM64 TRUE)
elseif (CMAKE_SYSTEM_PROCESSOR MATCHES "armv*")
    set(PROJECT_PLATFORM_ARM TRUE)
elseif (CMAKE_SYSTEM_PROCESSOR STREQUAL "e2k")
    set(PROJECT_PLATFORM_E2K TRUE)
elseif (CMAKE_SYSTEM_PROCESSOR STREQUAL "ppc" OR CMAKE_SYSTEM_PROCESSOR STREQUAL "ppc64le")
    set(PROJECT_PLATFORM_PPC TRUE)
endif()

if (ANDROID)
    set(XRAY_USE_GLES ON CACHE BOOL "Use OpenGL ES (Android)" FORCE)
    add_definitions(-DTOGLES)
    if (NOT BUILD_SHARED_LIBS)
        add_definitions(-DXRAY_STATIC_BUILD)
    endif()
endif()

if (PROJECT_PLATFORM_ARM)
    add_compile_options(-mfpu=neon)
elseif (PROJECT_PLATFORM_ARM64)
    #add_compile_options()
elseif (PROJECT_PLATFORM_E2K)
    add_compile_options(-Wno-unknown-pragmas)
elseif (PROJECT_PLATFORM_PPC)
    add_compile_options(
        -maltivec
        -mabi=altivec
    )
    add_compile_definitions(NO_WARN_X86_INTRINSICS)
else()
    add_compile_options(
        -mfpmath=sse
        -msse3
    )
endif()

if (XRAY_LINKER)
    add_link_options(-fuse-ld=${XRAY_LINKER})
endif()

if (CMAKE_BUILD_TYPE STREQUAL "Debug")
    add_compile_options(-Og)
endif()

if (NOT WIN32 AND NOT ANDROID)
    find_package(SDL2 2.0.18 REQUIRED)
    find_package(OpenAL REQUIRED)
    find_package(JPEG)
    find_package(Ogg REQUIRED)
    find_package(Vorbis REQUIRED)
    find_package(Theora REQUIRED)
    find_package(LZO REQUIRED)
    find_package(mimalloc NAMES mimalloc2 mimalloc2.0 mimalloc)
elseif (ANDROID)
    if (ANDROID_DEPS_DIR)
        # Prebuilt kutuphaneleri kullan
        set(SDL2_INCLUDE_DIR "${ANDROID_DEPS_DIR}/include/SDL2" CACHE PATH "")
        set(SDL2_LIBRARY "${ANDROID_DEPS_DIR}/lib/libSDL2.so" CACHE FILEPATH "")
        set(OPENAL_INCLUDE_DIR "${ANDROID_DEPS_DIR}/include/AL" CACHE PATH "")
        set(OPENAL_LIBRARY "${ANDROID_DEPS_DIR}/lib/libopenal.so" CACHE FILEPATH "")
        set(OGG_INCLUDE_DIR "${ANDROID_DEPS_DIR}/include" CACHE PATH "")
        set(OGG_LIBRARY "${ANDROID_DEPS_DIR}/lib/libogg.a" CACHE FILEPATH "")
        set(VORBIS_INCLUDE_DIR "${ANDROID_DEPS_DIR}/include" CACHE PATH "")
        set(VORBIS_LIBRARY "${ANDROID_DEPS_DIR}/lib/libvorbis.a" CACHE FILEPATH "")
        set(LZO_INCLUDE_DIR "${ANDROID_DEPS_DIR}/include" CACHE PATH "")
        set(LZO_LIBRARY "${ANDROID_DEPS_DIR}/lib/liblzo2.a" CACHE FILEPATH "")

        set(SDL2_FOUND TRUE)
        set(OPENAL_FOUND TRUE)
        set(OGG_FOUND TRUE)
        set(VORBIS_FOUND TRUE)
        set(LZO_FOUND TRUE)

        add_library(SDL2::SDL2 SHARED IMPORTED)
        set_target_properties(SDL2::SDL2 PROPERTIES
            IMPORTED_LOCATION "${SDL2_LIBRARY}"
            INTERFACE_INCLUDE_DIRECTORIES "${SDL2_INCLUDE_DIR}"
        )

        add_library(OpenAL::OpenAL SHARED IMPORTED)
        set_target_properties(OpenAL::OpenAL PROPERTIES
            IMPORTED_LOCATION "${OPENAL_LIBRARY}"
            INTERFACE_INCLUDE_DIRECTORIES "${OPENAL_INCLUDE_DIR}"
        )

        add_library(Ogg::Ogg STATIC IMPORTED)
        set_target_properties(Ogg::Ogg PROPERTIES
            IMPORTED_LOCATION "${OGG_LIBRARY}"
            INTERFACE_INCLUDE_DIRECTORIES "${OGG_INCLUDE_DIR}"
        )

        add_library(Vorbis::Vorbis STATIC IMPORTED)
        set_target_properties(Vorbis::Vorbis PROPERTIES
            IMPORTED_LOCATION "${VORBIS_LIBRARY}"
            INTERFACE_INCLUDE_DIRECTORIES "${VORBIS_INCLUDE_DIR}"
        )

        add_library(Vorbis::VorbisFile STATIC IMPORTED)
        set_target_properties(Vorbis::VorbisFile PROPERTIES
            IMPORTED_LOCATION "${ANDROID_DEPS_DIR}/lib/libvorbisfile.a"
            INTERFACE_INCLUDE_DIRECTORIES "${VORBIS_INCLUDE_DIR}"
        )

        add_library(LZO::LZO STATIC IMPORTED)
        set_target_properties(LZO::LZO PROPERTIES
            IMPORTED_LOCATION "${LZO_LIBRARY}"
            INTERFACE_INCLUDE_DIRECTORIES "${LZO_INCLUDE_DIR}"
        )

        if (EXISTS "${ANDROID_DEPS_DIR}/include/theora/theora.h")
            set(THEORA_INCLUDE_DIR "${ANDROID_DEPS_DIR}/include" CACHE PATH "")
            set(THEORA_LIBRARY "${ANDROID_DEPS_DIR}/lib/libtheora.a" CACHE FILEPATH "")
            set(THEORA_FOUND TRUE)
            message(STATUS "Theora: FOUND")
            add_library(Theora::Theora STATIC IMPORTED)
            set_target_properties(Theora::Theora PROPERTIES
                IMPORTED_LOCATION "${THEORA_LIBRARY}"
                INTERFACE_INCLUDE_DIRECTORIES "${THEORA_INCLUDE_DIR}"
            )
        else()
            set(THEORA_FOUND FALSE)
            message(STATUS "Theora: NOT FOUND (optional)")
        endif()

        message(STATUS "Using prebuilt Android dependencies from: ${ANDROID_DEPS_DIR}")

        if (NOT XRAY_USE_LUAJIT)
            set(LUA_INCLUDE_DIR "${ANDROID_DEPS_DIR}/include" CACHE PATH "")
            set(LUA_LIBRARY "${ANDROID_DEPS_DIR}/lib/liblua.a" CACHE FILEPATH "")
            set(LUA_LIBRARIES "${LUA_LIBRARY}")
            set(LUA_FOUND TRUE)
            if (NOT TARGET Lua51)
                add_library(Lua51 STATIC IMPORTED)
                set_target_properties(Lua51 PROPERTIES
                    IMPORTED_LOCATION "${LUA_LIBRARY}"
                    INTERFACE_INCLUDE_DIRECTORIES "${LUA_INCLUDE_DIR}"
                )
            endif()
        endif()
    else()
        find_package(SDL2 2.0.18 REQUIRED)
        find_package(OpenAL REQUIRED)
        find_package(Ogg REQUIRED)
        find_package(Vorbis REQUIRED)
        find_package(Theora)
        find_package(LZO REQUIRED)
    endif()
endif()

# Memory allocator option
if (mimalloc_FOUND)
    set(MEMORY_ALLOCATOR "mimalloc" CACHE STRING "Use specific memory allocator (mimalloc/standard)")
else()
    set(MEMORY_ALLOCATOR "standard" CACHE STRING "Use specific memory allocator (mimalloc/standard)")
endif()
set_property(CACHE MEMORY_ALLOCATOR PROPERTY STRINGS "mimalloc" "standard")

if (MEMORY_ALLOCATOR STREQUAL "mimalloc" AND NOT mimalloc_FOUND)
    message(FATAL_ERROR "mimalloc allocator requested but not found. Please, install mimalloc package or select standard allocator.")
endif()

message(STATUS "Using ${MEMORY_ALLOCATOR} memory allocator")

get_property(LIB64 GLOBAL PROPERTY FIND_LIBRARY_USE_LIB64_PATHS)

if ("${LIB64}" STREQUAL "TRUE")
    set(LIBSUFFIX 64)
else()
    set(LIBSUFFIX "")
endif()

set(XRAY_ENABLE_WARNINGS
    -Wall
    #-Werror
    -Wextra
    #-pedantic
    -Wno-unknown-pragmas
    -Wno-strict-aliasing
    -Wno-parentheses
    -Wno-unused-label
    -Wno-unused-parameter
    -Wno-switch
    -Wno-trigraphs
    #-Wno-padded
    #-Wno-c++98-compat
    #-Wno-c++98-compat-pedantic
    #-Wno-c++11-compat
    #-Wno-c++11-compat-pedantic
    #-Wno-c++14-compat
    #-Wno-c++14-compat-pedantic
    #-Wno-newline-eof
    $<$<CXX_COMPILER_ID:GNU>:$<$<COMPILE_LANGUAGE:CXX>:-Wno-class-memaccess>>
    $<$<CXX_COMPILER_ID:GNU>:$<$<COMPILE_LANGUAGE:CXX>:-Wno-interference-size>>
)

set(XRAY_DISABLE_WARNINGS "-w")
