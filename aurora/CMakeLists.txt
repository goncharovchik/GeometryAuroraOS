cmake_minimum_required(VERSION 3.10)
project(${FLUTTER_PROJECT_NAME} LANGUAGES CXX)

include(GNUInstallDirs)

set(BINARY_NAME ${CMAKE_PROJECT_NAME})
set(FLUTTER_DIR ${CMAKE_CURRENT_SOURCE_DIR}/flutter)
set(INCLUDE_DIR ${CMAKE_CURRENT_SOURCE_DIR}/include)
set(LIBS_DIR ${CMAKE_CURRENT_SOURCE_DIR}/lib/x86_64)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

set(CMAKE_CXX_FLAGS "-Wall -Wextra")
set(CMAKE_CXX_FLAGS_RELEASE "-O3")

set(CMAKE_SKIP_RPATH OFF)
set(CMAKE_INSTALL_RPATH "\$ORIGIN/../share/${BINARY_NAME}/lib")

add_executable(${BINARY_NAME} main.cpp)

# Import aurora_embedder, flutter_engine, maliit
add_library(aurora_embedder SHARED IMPORTED GLOBAL)
set_target_properties(aurora_embedder PROPERTIES
    IMPORTED_LOCATION "${LIBS_DIR}/libaurora_embedder.so"
    INTERFACE_INCLUDE_DIRECTORIES "${INCLUDE_DIR}"
)
add_library(aurora_embedder::aurora_embedder ALIAS aurora_embedder)

include(flutter/generated_plugins.cmake)

add_library(flutter_engine SHARED IMPORTED)
set_target_properties(flutter_engine PROPERTIES
    IMPORTED_LOCATION "${LIBS_DIR}/libflutter_engine.so"
)

add_library(maliit_glib SHARED IMPORTED)
set_target_properties(maliit_glib PROPERTIES
    IMPORTED_LOCATION "${LIBS_DIR}/libmaliit-glib.so.0"
)

find_package(PkgConfig REQUIRED)
pkg_check_modules(GLIB2 REQUIRED IMPORTED_TARGET glib-2.0 gobject-2.0)

target_link_directories(${BINARY_NAME} PRIVATE ${LIBS_DIR})
target_link_options(${BINARY_NAME} PRIVATE "-Wl,-rpath-link,${LIBS_DIR}" "-Wl,--allow-shlib-undefined")

target_link_libraries(${BINARY_NAME} PRIVATE
    aurora_embedder
    flutter_engine
    maliit_glib
    PkgConfig::GLIB2
    EGL
    GLESv2
    wayland-client
    wayland-egl
)

target_include_directories(${BINARY_NAME} PRIVATE
    ${FLUTTER_DIR}
    ${INCLUDE_DIR}
)

set(PACKAGE_INSTALL_DIR    ${CMAKE_INSTALL_DATADIR}/${BINARY_NAME})
set(DESKTOP_INSTALL_DIR    ${CMAKE_INSTALL_DATADIR}/applications)
set(ICONS_INSTALL_ROOT_DIR ${CMAKE_INSTALL_DATADIR}/icons/hicolor)

install(FILES     ${CMAKE_CURRENT_SOURCE_DIR}/icudtl.dat DESTINATION ${PACKAGE_INSTALL_DIR})
install(DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}/bundle/flutter_assets DESTINATION ${PACKAGE_INSTALL_DIR})
install(DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}/bundle/lib            DESTINATION ${PACKAGE_INSTALL_DIR})

install(TARGETS ${BINARY_NAME} RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR})
install(FILES desktop/${BINARY_NAME}.desktop DESTINATION ${DESKTOP_INSTALL_DIR})

foreach(ICONS_SIZE 86x86 108x108 128x128 172x172)
    install(FILES icons/${ICONS_SIZE}.png
            RENAME ${BINARY_NAME}.png
            DESTINATION ${ICONS_INSTALL_ROOT_DIR}/${ICONS_SIZE}/apps/)
endforeach(ICONS_SIZE)
