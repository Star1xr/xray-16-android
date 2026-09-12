if (ANDROID)
    # Android: build as shared library for SDL2 NativeActivity
    add_library(xr_3da SHARED)
    set_target_properties(xr_3da PROPERTIES
        PREFIX "lib"
        OUTPUT_NAME "xr_3da"
    )
else()
    add_executable(xr_3da)
    set_property(
        DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}"
        PROPERTY
        VS_STARTUP_PROJECT xr_3da
    )
endif()

target_sources(xr_3da PRIVATE
    entry_point.cpp
    stdafx.h

    resource.h
    resource.rc

    splash_oxr.bmp
    stalker_cop.ico
    stalker_cs.ico
    stalker_soc.ico
)

target_include_directories(xr_3da
    PRIVATE
    "${CMAKE_SOURCE_DIR}/src"
)

target_link_libraries(xr_3da
    PRIVATE
    xrCore
    xrAPI
    xrEngine
    xrRender_GL
    xrGame
)

if (ANDROID)
    target_link_libraries(xr_3da PRIVATE GLESv2 EGL)
endif()

if (NOT ANDROID)
    set_target_properties(xr_3da PROPERTIES
        PREFIX ""
    )
endif()

install(TARGETS xr_3da
    RUNTIME DESTINATION "${CMAKE_INSTALL_BINDIR}"
    LIBRARY DESTINATION "${CMAKE_INSTALL_LIBDIR}"
)
