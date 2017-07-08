cmake_minimum_required(VERSION 3.7)
project(valence_server)

add_custom_target(valence_server
        COMMAND /usr/bin/swift build
        WORKING_DIRECTORY ${CMAKE_SOURCE_DIR}
        SOURCES Sources)
