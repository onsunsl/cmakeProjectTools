cmake_minimum_required(VERSION 3.27)

project(main VERSION 1.0)

include(cmake/project.cmake)


MakeProject(bin
            outDir          ${projectInstallBinPath}
            outFile         ${PROJECT_NAME}
            sourceDir       ${CMAKE_SOURCE_DIR}/src
            includeDirs     ${CMAKE_SOURCE_DIR}/inc
            linkLibs        QtCore
            )