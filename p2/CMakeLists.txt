    cmake_minimum_required(VERSION 3.9.1)
    project(p2)
    find_package(CUDA QUIET REQUIRED)
    set(CMAKE_CXX_STANDARD 17)
    set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -Werror")
    include_directories(
        src
)
    set(SOURCE_FILES
        src/heat2D3D.cu
        
    )
    cuda_add_executable(heat2D3D ${SOURCE_FILES})
