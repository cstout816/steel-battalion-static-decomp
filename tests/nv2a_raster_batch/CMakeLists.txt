cmake_minimum_required(VERSION 3.20)
project(nv2a_raster_batch_regression C)
enable_testing()
set(XBOXRECOMP_SOURCE_DIR "${CMAKE_CURRENT_SOURCE_DIR}/../../local-tools/xboxrecomp"
    CACHE PATH "Pinned XboxRecomp source checkout with project patches applied")
if(NOT EXISTS "${XBOXRECOMP_SOURCE_DIR}/src/kernel/nv2a_pb_exec.c")
    message(FATAL_ERROR "Set XBOXRECOMP_SOURCE_DIR to a prepared XboxRecomp checkout")
endif()
add_executable(nv2a-raster-batch-test nv2a_raster_batch_test.c
    "${XBOXRECOMP_SOURCE_DIR}/src/kernel/nv2a_pb_exec.c"
    "${XBOXRECOMP_SOURCE_DIR}/src/kernel/nv2a_vsh_interp.c"
    "${XBOXRECOMP_SOURCE_DIR}/src/kernel/nv2a_combiner.c")
target_include_directories(nv2a-raster-batch-test PRIVATE
    "${XBOXRECOMP_SOURCE_DIR}/src/kernel"
    "${XBOXRECOMP_SOURCE_DIR}/src"
    "${XBOXRECOMP_SOURCE_DIR}/src/nv2a"
    "${XBOXRECOMP_SOURCE_DIR}/src/video")
if(MSVC)
    target_compile_definitions(nv2a-raster-batch-test PRIVATE _CRT_SECURE_NO_WARNINGS)
elseif(NOT WIN32)
    target_link_libraries(nv2a-raster-batch-test PRIVATE m pthread)
endif()
add_test(NAME nv2a-raster-batch COMMAND nv2a-raster-batch-test)
