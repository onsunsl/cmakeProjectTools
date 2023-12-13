cmake_minimum_required(VERSION 3.27)
if(WIN32)
    add_definitions(-DUNICODE -D_UNICODE)
endif()

set(FIND_CMAKE_IN_FILE ${CMAKE_CURRENT_LIST_DIR}/find.cmake.in)

LIST(APPEND CMAKE_MODULE_PATH ${CMAKE_BINARY_DIR}/findCmake)

# -------------------------------------------------------------------------------------------------------------
# 移除字符串尾部斜杠或反斜杠函数
# @param input    输入字符串
# @param output   输出字符串
# -------------------------------------------------------------------------------------------------------------
function(trimTailSlash input output)
    string(REGEX REPLACE "[/\\]$" "" value ${input})
    set(${output} ${value} PARENT_SCOPE)
endfunction()


# -------------------------------------------------------------------------------------------------------------
# 检查预设变量函数
# @param var          变量名
# @param defaultValue 默认值
# -------------------------------------------------------------------------------------------------------------
function(checkPreset var defaultValue)
    set(OS_VAR $ENV{${var}})

    if(${var})     # 已经定义
        trim_tail_slash(${${var}} value)
        set(${var} ${value} PARENT_SCOPE)

    elseif(OS_VAR) # 取系统环境变量
        trim_tail_slash(${OS_VAR} value)
        set(${var} ${value} PARENT_SCOPE)

    else()         # 取默认值
        set(${var} ${defaultValue} PARENT_SCOPE)
    endif()
endfunction()

# -------------------------------------------------------------------------------------------------------------
# 获取子目录列表(绝对目录)
# @param curDir 顶层目录
# @param result 返回值
# -------------------------------------------------------------------------------------------------------------
function(subAbsDirList curdir result)
    file(GLOB_RECURSE children LIST_DIRECTORIES true RELATIVE ${curdir} ${curdir}/*)
    set(dirlist "")
    foreach(child ${children})
        if(IS_DIRECTORY ${curdir}/${child})
            get_filename_component(absPath "${curdir}/${child}" ABSOLUTE)
            list(APPEND dirlist ${absPath})
            subAbsDirList(sub_subdirs ${absPath})
            foreach(subdir ${sub_subdirs})
                list(APPEND dirlist ${subdir})
            endforeach()
        endif()
    endforeach()
    set(${result} ${dirlist} PARENT_SCOPE)

endfunction()


# -------------------------------------------------------------------------------------------------------------
# 获取指定后缀的文件
# @param topDir         顶层目录
# @param inludeFileExts 查找文件名后缀   如: ".cpp,.h"
# @param dirRecurse     递子查找目录     如: ON / OFF
# @param excludeDirs    排除的目录列表   如：dir1 dir2
# @param returnFiles    返回文件列表
# -------------------------------------------------------------------------------------------------------------
function(scanFiles returnFiles)

    set(options )
    set(oneValueArgs   noLog dirRecurse topDir inludeFileExts)
    set(multiValueArgs excludeDirs excludeFiles scanFiles extraSourceFiles)

    cmake_parse_arguments(a "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN} )

    if(a_dirRecurse)
        file(GLOB_RECURSE files ${a_topDir}/*)
    else()
        file(GLOB files ${a_topDir}/*)
    endif()
    LIST(APPEND files ${a_extraSourceFiles})

    foreach(file ${files})
        # message("file: ${file}")

        # 排除文件
        set(isPassFile OFF)
        foreach(fFile ${a_excludeFiles})
            if(file AND fFile AND  "${file}" MATCHES "^${fFile}")
                message("file: ${file} 排除文件: ${fFile}")
                set(isPassFile ON)
                break()
            endif()
        endforeach()
        if(isPassFile)
            continue()
        endif()

        # 排除目录
        set(isPassDir OFF)
        foreach(fDir ${a_excludeDirs})
            if(file AND fDir AND  "${file}" MATCHES "^${fDir}")
                set(isPassDir ON)
                break()
            endif()
        endforeach()
        if(isPassDir)
            continue()
        endif()

        # 排除文件
        get_filename_component(fileExt ${file} EXT)
        if(NOT fileExt OR NOT "${a_inludeFileExts}" MATCHES "${fileExt}")
            continue()
        endif()

        list(APPEND filesList ${file})
    endforeach()

    set(${returnFiles} ${filesList} PARENT_SCOPE)

    if(NOT a_noLog)
        message("代码目录: ${a_topDir} 含(${a_inludeFileExts}) 递归(${a_dirRecurse})")
        if(a_excludeDirs)
            string(JOIN "," excludeDirs ${a_excludeDirs})
            message("排除目录: ${excludeDirs}")
        endif()
        if(a_excludeFiles)
            string(JOIN "," excludeFiles ${a_excludeFiles})
            message("排除文件: ${excludeFiles}")
        endif()
    endif()

endfunction()

# -------------------------------------------------------------------------------------
# 查找库生成依赖文件
#
# @param name         库名
# @param incDir       头文件目录
# @param libDir       库文件目录
# -------------------------------------------------------------------------------------
function(findLib name incDir libDir)
    set(PROJECT_NAME         ${name})
    set(publicLibDirs       "${libDir}")
    set(publicLibs          "${name}")
    get_filename_component(sourceParentDir "${incDir}/../" REALPATH)
    get_filename_component(sourceParentIncDir "${incDir}/../include" REALPATH)
    set(publicIncludeDirs   "${incDir}
                            ${sourceParentDir}
                            ${sourceParentIncDir}
                            ${CMAKE_BINARY_DIR}
                            ${CMAKE_CURRENT_BINARY_DIR}
                            ")
    configure_file(${FIND_CMAKE_IN_FILE} ${CMAKE_BINARY_DIR}/findCmake/Find${name}.cmake @ONLY)
endfunction()



# -------------------------------------------------------------------------------------
# 生成工程结构
#
# * 开关参数(ON/OFF)
# @param options          输出类型      dLib 动态库开关 sLib 静态库开关 bin 可执行文件开关
#                         递归子目录    dirRecurse 递归开关
#                         输出日志      logEnable 输出日志开关
# * 单个键值对参数
# @param outDir           输出目录
# @param outFile          输出文件名
# @param sourceDir        源文件目录
# @param sourceFileExts   源文件扩展名
#
# * 多个键值对参数
# @param excludeFileDirs  排除的源文件目录列表
# @param excludeFiles     排除的源文件列表
# @param includeDirs      头文件目录列表(如果不指定则自动添加子目录)
# @param linkDirs         库文件目录列表
# @param linkLibs         依赖库文件列表
# @param headOnlyLibs     只依赖头文件库文件列表
# extraSourceFiles        额外的源文件列表
#-------------------------------------------------------------------------------------
function(MakeProject)
    set(options        dLib sLib bin noDirRecurse noLog)
    set(oneValueArgs   sourceDir outDir outFile sourceFileExts)
    set(multiValueArgs includeDirs excludeFileDirs excludeFiles linkDirs linkLibs headOnlyLibs extraSourceFiles)

    cmake_parse_arguments(a "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN})

    # 获取工程的源文件扩展名
    if(NOT a_sourceFileExts)
        set(sourceFileExts ".cpp,.c,.h,.hpp,.inc,.qrc,.rc,.qml")
    else()
        set(sourceFileExts ${a_sourceFileExts})
    endif()

    if(a_noDirRecurse)
        set(_dirRecurse OFF)
    else()
        set(_dirRecurse ON)
    endif()

    # 扫描文件
    if(a_sourceDir)

        # 源文件
        scanFiles(sourceFiles
                dirRecurse     ${_dirRecurse}
                noLog          ${a_noLog}
                inludeFileExts ${sourceFileExts}
                topDir         ${a_sourceDir}
                excludeDirs    ${a_excludeFileDirs}
                excludeFiles   ${a_excludeFiles}
                extraSourceFiles   ${a_extraSourceFiles}
                )

        # ui文件
        scanFiles(uiFiles
                dirRecurse     ${_dirRecurse}
                noLog          ${a_noLog}
                inludeFileExts ".ui"
                topDir         ${a_sourceDir}
                excludeDirs    ${a_excludeFileDirs}
                excludeFiles   ${a_excludeFiles}
                extraSourceFiles   ${a_extraSourceFiles}
                )

        # 子目录作头文件目录
        subAbsDirList(${a_sourceDir} subIncludeDirs)
    endif()

    if(NOT sourceFiles)
        message("[ERROR] ==> 工程(${a_outFile}) 未扫描到可用的源文件!!!! <== [ERROR]")
        message("========================================================================================")
        return()
    endif()


    # 设置工程输出目录
    set(CMAKE_RUNTIME_OUTPUT_DIRECTORY_DEBUG   ${a_outDir})
    set(CMAKE_RUNTIME_OUTPUT_DIRECTORY_RELEASE ${a_outDir})
    set(CMAKE_ARCHIVE_OUTPUT_DIRECTORY_DEBUG   ${a_outDir})
    set(CMAKE_ARCHIVE_OUTPUT_DIRECTORY_RELEASE ${a_outDir})
    set(CMAKE_LIBRARY_OUTPUT_DIRECTORY_DEBUG   ${a_outDir})
    set(CMAKE_LIBRARY_OUTPUT_DIRECTORY_RELEASE ${a_outDir})
    set(CMAKE_LIBRARY_OUTPUT_DIRECTORY         ${a_outDir})

    # 公开发布的头文件目录、库文件目录、库文件列表的find.cmake
    set(publicLibDirs       "${a_outDir}")
    set(publicLibs          "${a_outFile}")
    get_filename_component(sourceParentDir "${a_sourceDir}/../" REALPATH)
    get_filename_component(sourceParentIncDir "${a_sourceDir}/../include" REALPATH)
    set(publicIncludeDirs   "${a_includeDirs}
                            ${a_sourceDir}
                            ${sourceParentDir}
                            ${sourceParentIncDir}
                            ${CMAKE_BINARY_DIR}
                            ${CMAKE_CURRENT_BINARY_DIR}
                            ")
    configure_file(${FIND_CMAKE_IN_FILE} ${CMAKE_BINARY_DIR}/findCmake/Find${a_outFile}.cmake @ONLY)

    # 为工程查找Qt库并添加依赖
    findQtLib(QtDependLibs noLog ${a_noLog} inputLibs ${a_linkLibs})
    list(FIND a_linkLibs "QtWidgets" index)
    if(${index} GREATER -1)
        qt5_wrap_ui(uiHeaders ${uiFiles})
        LIST(APPEND sourceFiles ${uiFiles} ${uiHeaders})
    endif()

    # 设定编译输出的工程类型(添加源文件到工程)
    if(a_dLib OR CMAKE_SYSTEM_NAME STREQUAL "Android")
        string(TOUPPER ${a_outFile} LIBRARY_EXPORT)
        add_definitions(-D${LIBRARY_EXPORT}_LIB)
        add_definitions(-D${LIBRARY_EXPORT}_BUILD)
        add_library(${a_outFile} SHARED ${sourceFiles})
        set(projectType ${CMAKE_SHARED_LIBRARY_SUFFIX})
    elseif(a_sLib)
        add_definitions(-DBUILD_STATIC)
        add_library(${a_outFile} STATIC ${sourceFiles})
        set(projectType ${CMAKE_STATIC_LIBRARY_SUFFIX})
    elseif(a_bin)
        add_executable(${a_outFile} ${sourceFiles})
        set(projectType ${CMAKE_EXECUTABLE_SUFFIX})
    else()
        message(FATAL_ERROR "未指定工程输出类型")
    endif()

    # 为工程查找非Qt库并添加依赖
    filterQtlib(otherDependLibs excludeQt filterInputLibs ${a_linkLibs})
    LIST(APPEND otherDependLibs ${a_headOnlyLibs})
    set(includeDirs ${CMAKE_BINARY_DIR} ${CMAKE_CURRENT_BINARY_DIR})
    if(otherDependLibs)
        foreach(otherDependLib ${otherDependLibs})
            find_package(${otherDependLib} REQUIRED)
            list(APPEND includeDirs ${${otherDependLib}_INCLUDE_DIRS})
            target_link_directories(${a_outFile} PRIVATE ${${otherDependLib}_LIBRARY_DIRS})
            if(TARGET ${otherDependLib})
                add_dependencies(${a_outFile} ${otherDependLib})
            endif()
        endforeach()
    endif()

    # 添加用户外部指定头文件目录
    if(a_includeDirs)
        list(APPEND includeDirs ${a_includeDirs})
    # 添加子目录到头文件目录
    else()
        list(APPEND includeDirs ${a_sourceDir} ${sourceParentDir} ${sourceParentIncDir} ${subIncludeDirs})
    endif()
    list(REMOVE_DUPLICATES includeDirs)
    target_include_directories(${a_outFile} PRIVATE ${includeDirs})

    # 添加链接依赖库列表
    set(dependLibs ${QtDependLibs} ${otherDependLibs})
    if(dependLibs)
        target_link_libraries(${a_outFile} PRIVATE ${dependLibs})
    endif()

    # 输出日志
    if(NOT a_noLog)
        get_target_property(allIncudeDirs ${a_outFile} INCLUDE_DIRECTORIES)
        String(REPLACE ";" "\n" allIncudeDirs "${allIncudeDirs}")
        message("头文件目录:${allIncudeDirs}")

        get_target_property(allLinkLibs ${a_outFile} LINK_LIBRARIES)
        message("依赖模块: ${allLinkLibs}")

        get_target_property(allLinkLibDirs ${a_outFile} INTERFACE_LINK_DIRECTORIES)
        message("依赖目录: ${allLinkLibDirs}")

        get_target_property(sourceFiles ${a_outFile} SOURCES)
        string(JOIN "\n" fileLogs ${sourceFiles})
        message("源码文件: ${fileLogs}")

        message("输出路径: ${a_outDir}")
        message("工程模块: [${a_outFile}${projectType}]")
        message("========================================================================================")
    endif()

endfunction()

# -------------------------------------------------------------------------------------
# 生成CMakeLists.txt文件并添加到工程
#
# @param sourceDir        源文件目录
#-------------------------------------------------------------------------------------
function(addSubProject sourceDir)
    set(projectFile ${CMAKE_SOURCE_DIR}/cmake/projects/${sourceDir}/CMakeLists.txt)
    get_filename_component(projectPath ${projectFile} DIRECTORY)
    get_filename_component(projectName ${projectPath} NAME)

    if(NOT EXISTS ${projectFile})
        message("生成工程文件: ${projectFile}")
        configure_file(${CMAKE_SOURCE_DIR}/cmake/CMakeLists.txt.in ${projectFile} @ONLY)
    endif()
    add_subdirectory(${projectPath})

    # if(NOT TARGET ${projectName})
    #     message("删除: ${projectName}")
    #     file(REMOVE_RECURSE ${projectPath})
    # endif()

endfunction()



# 安装编译输出文件
# @param outFile    输出文件名
# @param ourDir     安装目录
# @param otherFiles 额外的安装文件
# @param otherDirs  额外的安装目录
function(installFile outFile ourDir otherFiles otherDirs)

    list(APPEND logLists "安装目录: ${ourDir}")
    install(TARGETS ${outFile}
        RUNTIME DESTINATION ${projectInstallRuntimePath}/${ourDir}
        LIBRARY DESTINATION ${projectInstallLibaryPath}/${ourDir}
        ARCHIVE DESTINATION ${projectInstallArchivePath}/${ourDir}
    )

    # 额外的安装文件
    if(otherFiles)
        list(APPEND logLists "额外安装文件: ${otherFiles}")
        install(FILES ${otherFiles} DESTINATION ${ourDir})
    endif()

    # 额外的安装目录
    if(otherDirs)
        list(APPEND logLists "额外安装目录: ${otherDirs}")
        install(DIRECTORY ${otherDirs} DESTINATION ${ourDir})
    endif()

    get_target_property(target_type ${outFile} TYPE)

    if(NOT target_type STREQUAL "STATIC_LIBRARY" AND MSVC)
        install(FILES $<TARGET_PDB_FILE:${outFile}> DESTINATION ${projectInstallPdbPath}/${ourDir} OPTIONAL)
    endif()

endfunction(installFile )
