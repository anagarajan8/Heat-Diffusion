
    cmake_minimum_required(VERSION 3.9.1)
    project(se2)
    find_package(MPI)
    set(CMAKE_CXX_STANDARD 17)
    set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -Werror")
    set(CMAKE_CXX_COMPILE_FLAGS ${CMAKE_CXX_COMPILE_FLAGS} ${MPI_COMPILE_FLAGS})
    set(CMAKE_CXX_LINK_FLAGS ${CMAKE_CXX_LINK_FLAGS} ${MPI_LINK_FLAGS})
    include_directories(
        src
	${MPI_INCLUDE_PATH}
)
    set(SOURCE_FILES
        src/heattransfer.cc
        
    )
    add_executable(heat1D ${SOURCE_FILES})
    target_link_libraries(heat1D ${MPI_LIBRARIES})
   
