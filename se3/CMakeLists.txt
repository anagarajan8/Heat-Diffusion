    cmake_minimum_required(VERSION 3.9.1)
    project(se3)
    find_package(Threads)
    set(CMAKE_CXX_STANDARD 17)
    set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -std=c++11 -pthread")
    include_directories(
        src
)
    set(SOURCE_FILES
        src/heat2D3D.cc
        
    )
    add_executable(heat2D3D ${SOURCE_FILES})
    target_link_libraries (heat2D3D ${CMAKE_THREAD_LIBS_INIT})
