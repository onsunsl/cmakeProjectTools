cmake_minimum_required(VERSION 3.13 FATAL_ERROR)
if(WIN32)
    add_definitions(-DUNICODE -D_UNICODE)
endif()

function(uiFileDirs curdir result)
    file(GLOB_RECURSE items ${curdir}/*)
    set(dirList "")
    foreach(filePath ${items})
        get_filename_component(fileExt ${filePath} EXT)
        if(fileExt MATCHES ".ui")
            get_filename_component(dirPath "${filePath}" PATH)
            set(dirList ${dirList} ${dirPath})
            # message("dirPath: ${dirPath}")
        endif()
    endforeach()
    list(REMOVE_DUPLICATES dirList)
    set(${result} ${dirList} PARENT_SCOPE)
endfunction()

function(qt5_wrap_ui2 outfiles )
    message("qt5_wrap_ui------")
    set(options)
    set(oneValueArgs)
    set(multiValueArgs OPTIONS)

    cmake_parse_arguments(_WRAP_UI "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN})

    set(ui_files ${_WRAP_UI_UNPARSED_ARGUMENTS})
    set(ui_options ${_WRAP_UI_OPTIONS})

    foreach(it ${ui_files})
        get_filename_component(outfile ${it} NAME_WE)
        get_filename_component(infile ${it} ABSOLUTE)
        get_filename_component(outPath ${it} PATH)
        set(outfile ${CMAKE_CURRENT_BINARY_DIR}/ui_${outfile}.h)
        message("outfile==========:${outfile} ${outPath}")
        add_custom_command(OUTPUT ${outfile}
          COMMAND ${Qt5Widgets_UIC_EXECUTABLE}
          ARGS ${ui_options} -o ${outfile} ${infile}
          MAIN_DEPENDENCY ${infile} VERBATIM)
        set_source_files_properties(${infile} PROPERTIES SKIP_AUTOUIC ON)
        set_source_files_properties(${outfile} PROPERTIES SKIP_AUTOMOC ON)
        set_source_files_properties(${outfile} PROPERTIES SKIP_AUTOUIC ON)
        list(APPEND ${outfiles} ${outfile})
    endforeach()
    set(${outfiles} ${${outfiles}} PARENT_SCOPE)
endfunction()


#------------------------------------------------------------
# 根据输入的库列表，过滤出Qt库
# 例：
#   输入：QtWidgets QtCore QtGui QtSql spdlog mtqq
#   输出：Widgets Core Gui Sql
# @param includeQt          包含Qt库(可选)
# @param excludeQt          不包含Qt库(可选)
# @param filterInputLibs    待过滤后的库列表
# @param returnLibs         返回的Qt库列表
#------------------------------------------------------------
function(filterQtlib returnLibs)
    set(options includeQt excludeQt)
    set(oneValueArgs )
    set(multiValueArgs filterInputLibs)

    cmake_parse_arguments(a "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN})

    # 过滤Qt库 & 去除Qt字样
    foreach(_lib ${a_filterInputLibs})
        string(FIND ${_lib} "Qt" position)
        if(NOT ${position} EQUAL -1)
            string(REPLACE "Qt" "" _lib ${_lib})
            list(APPEND includeQtLibs ${_lib})
        else()
            list(APPEND excludeQtLibs ${_lib})
        endif()
    endforeach()

    # message("输入库列表:${a_filterInputLibs} 包含Qt库:${includeQtLibs} 不包含Qt库:${excludeQtLibs}")

    # 返回值
    if(a_includeQt)
        set(${returnLibs} ${includeQtLibs} PARENT_SCOPE)
    elseif(a_excludeQt)
        set(${returnLibs} ${excludeQtLibs} PARENT_SCOPE)
    else()
        set(${returnLibs} ${a_filterInputLibs} PARENT_SCOPE)
    endif()

endfunction()


#------------------------------------------------------------
# 根据输入的库列表查找出Qt依赖库
# 例：
#   输入：QtWidgets QtCore QtGui QtSql spdlog mtqq
#   输出：Widgets Core Gui Sql
#
# @param noLog           是否打印日志
# @param inputLibs       输入库库列表
# @param QtDependLibs    返回的Qt库列表
#------------------------------------------------------------
function(findQtLib QtDependLibs)
    set(options )
    set(oneValueArgs noLog)
    set(multiValueArgs inputLibs)

    cmake_parse_arguments(a "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN})
    filterQtlib(onlyQtLibs includeQt filterInputLibs ${a_inputLibs})
    if(NOT onlyQtLibs)
        return()
    endif()

    if(ANDROID)
        LIST(APPEND onlyQtLibs QtAndroidExtras)
    endif()

    string(REGEX REPLACE "\\\\" "/" QTDIR_ENV ${QTDIR_ENV})
    set(CMAKE_PREFIX_PATH ${QTDIR_ENV})

    set(CMAKE_AUTOMOC ON)
    set(CMAKE_AUTORCC ON)

    find_package(QT NAMES Qt6 Qt5 COMPONENTS ${onlyQtLibs} Test REQUIRED)
    find_package(Qt${QT_VERSION_MAJOR} COMPONENTS ${onlyQtLibs} Test REQUIRED)

    # 设置Qt链接库list
    foreach(qt ${onlyQtLibs})
        list(APPEND QtLibs Qt${QT_VERSION_MAJOR}::${qt})
    endforeach()

    list(APPEND QtLibs Qt${QT_VERSION_MAJOR}::Test)
    set(${QtDependLibs} ${QtLibs} PARENT_SCOPE)
endfunction()


if(DEFINED QtEnv)
    set(QTDIR_ENV ${QtEnv})
    set(CMAKE_AUTOMOC ON)
    set(CMAKE_AUTORCC ON)
    set(CMAKE_AUTOUIC OFF)
    set(Qt5Widgets_UIC_EXECUTABLE ${QTDIR_ENV}/bin/uic.exe)
    uiFileDirs(${CMAKE_SOURCE_DIR} uiFileDirs)
    set(CMAKE_AUTOUIC_SEARCH_PATHS ${uiFileDirs})
    LIST(APPEND CMAKE_FIND_ROOT_PATH ${QTDIR_ENV})
    LIST(APPEND CMAKE_PREFIX_PATH ${QTDIR_ENV})
    message("Qt环境:${QTDIR_ENV}")
endif()
