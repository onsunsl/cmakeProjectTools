cmake_minimum_required(VERSION 3.27)

include(${CMAKE_CURRENT_LIST_DIR}/tools.cmake)
include(${CMAKE_CURRENT_LIST_DIR}/QtEnv.cmake)
include(${CMAKE_CURRENT_LIST_DIR}/platform.cmake)


if(WIN32)
    add_definitions(-DUNICODE -D_UNICODE)
endif()

set(versionMajor 1 CACHE STRING "默认主版本号")
if(DEFINED VersionMajor)
    set(versionMajor ${VersionMajor})
endif()

set(versionMinor 1 CACHE STRING "默认次版本号")
if(DEFINED VersionMinor)
    set(versionMinor ${VersionMinor})
endif()

set(versionBuild 4 CACHE STRING "默认构建版本号")
if(DEFINED VersionBuild)
    set(versionBuild ${VersionBuild})
endif()

set(versionRevision 5 CACHE STRING "默认修订版本号")
if(DEFINED VersionRevision)
    set(versionRevision ${VersionRevision})
endif()

set(projectVersion "${versionMajor}.${versionMinor}.${versionBuild}.${versionRevision}"  CACHE STRING "默认工程版本号")
message("工程版本号: ${projectVersion}")

set(runEnv "Pro" CACHE STRING "默认发布环境")
if(DEFINED RunEnv)
    set(runEnv ${RunEnv})
    message("运行环境: ${runEnv}")
endif()

set(CMAKE_EXPORT_COMPILE_COMMANDS ON)
set(CMAKE_INCLUDE_CURRENT_DIR ON)
set(CMAKE_WINDOWS_EXPORT_ALL_SYMBOLS ON)
message("输出目录: ${CMAKE_BINARY_DIR}")
# C++标准
set(CMAKE_CXX_STANDARD 11)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

message("CMAKE_BINARY_DIR: ${CMAKE_BINARY_DIR}")
set(CMAKE_INSTALL_PREFIX  ${CMAKE_BINARY_DIR}/output)
set(projectInstallBinPath ${CMAKE_BINARY_DIR}/${CMAKE_BUILD_TYPE}/bin)
set(projectInstallLibPath ${CMAKE_BINARY_DIR}/${CMAKE_BUILD_TYPE}/lib)
set(projectInstallAchPath ${CMAKE_BINARY_DIR}/${CMAKE_BUILD_TYPE}/lib)
set(projectInstallPdbPath ${CMAKE_BINARY_DIR}/${CMAKE_BUILD_TYPE}/pdb)

message("projectInstallBinPath: ${projectInstallBinPath}")
