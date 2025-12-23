set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -std=c++11")
set(PLUGIN "TwitchPlayer")

set(
    SRC
    plugin.cpp
    mpvplayer.cpp
)

set(CMAKE_AUTOMOC ON)

# Find MPV
find_package(PkgConfig REQUIRED)
pkg_check_modules(MPV REQUIRED mpv)

add_library(${PLUGIN} MODULE ${SRC})
set_target_properties(${PLUGIN} PROPERTIES LIBRARY_OUTPUT_DIRECTORY ${PLUGIN})

# Link libraries
qt5_use_modules(${PLUGIN} Qml Quick)
target_include_directories(${PLUGIN} PRIVATE ${MPV_INCLUDE_DIRS})
target_link_libraries(${PLUGIN} ${MPV_LIBRARIES})

execute_process(
    COMMAND dpkg-architecture -qDEB_HOST_MULTIARCH
    OUTPUT_VARIABLE ARCH_TRIPLET
    OUTPUT_STRIP_TRAILING_WHITESPACE
)

set(QT_IMPORTS_DIR "/lib/${ARCH_TRIPLET}")

install(TARGETS ${PLUGIN} DESTINATION ${QT_IMPORTS_DIR}/${PLUGIN}/)
install(FILES qmldir DESTINATION ${QT_IMPORTS_DIR}/${PLUGIN}/)