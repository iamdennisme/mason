cmake_minimum_required(VERSION 3.14)
project(runner LANGUAGES CXX)

# ========== Windows 编译优化设置 ==========

# 设置 C++ 标准
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# Windows 特定优化
if(MSVC)
  # 启用更高的警告级别
  add_compile_options(/W4)

  # 优化代码大小和速度
  add_compile_options(/O2 /GL)
  add_link_options(/LTCG)

  # 启用现代 Windows API 支持
  add_compile_definitions(
    WIN32_LEAN_AND_MEAN
    NOMINMAX
    _CRT_SECURE_NO_WARNINGS
    NTDDI_VERSION=NTDDI_WIN10_RS5  # Windows 10 1809+
    _WIN32_WINNT=0x0A00            # Windows 10
    WINVER=0x0A00                  # Windows 10
  )

  # 启用多核编译
  add_compile_options(/MP)

  # 运行时库优化（使用静态链接运行时）
  foreach(flag_var
      CMAKE_CXX_FLAGS CMAKE_CXX_FLAGS_DEBUG CMAKE_CXX_FLAGS_RELEASE
      CMAKE_CXX_FLAGS_MINSIZEREL CMAKE_CXX_FLAGS_RELWITHDEBINFO)
    if(${flag_var} MATCHES "/MD")
      string(REGEX REPLACE "/MD" "/MT" "${flag_var}" "${${flag_var}}")
    endif()
  endforeach()
endif()

# ========== 应用目标定义 ==========

# Define the application target. To change its name, change BINARY_NAME in the
# top-level CMakeLists.txt, not the value here, or `flutter run` will no longer
# work.
#
# Any new source files that you add to the application should be added here.
add_executable(${BINARY_NAME} WIN32
  "flutter_window.cpp"
  "main.cpp"
  "utils.cpp"
  "win32_window.cpp"
  "${FLUTTER_MANAGED_DIR}/generated_plugin_registrant.cc"
  "Runner.rc"
  "runner.exe.manifest"
)

# ========== 应用构建设置 ==========

# Apply the standard set of build settings. This can be removed for applications
# that need different build settings.
apply_standard_settings(${BINARY_NAME})

# Add preprocessor definitions for the build version.
target_compile_definitions(${BINARY_NAME} PRIVATE "FLUTTER_VERSION=\"${FLUTTER_VERSION}\"")
target_compile_definitions(${BINARY_NAME} PRIVATE "FLUTTER_VERSION_MAJOR=${FLUTTER_VERSION_MAJOR}")
target_compile_definitions(${BINARY_NAME} PRIVATE "FLUTTER_VERSION_MINOR=${FLUTTER_VERSION_MINOR}")
target_compile_definitions(${BINARY_NAME} PRIVATE "FLUTTER_VERSION_PATCH=${FLUTTER_VERSION_PATCH}")
target_compile_definitions(${BINARY_NAME} PRIVATE "FLUTTER_VERSION_BUILD=${FLUTTER_VERSION_BUILD}")

# Disable Windows macros that collide with C++ standard library functions.
target_compile_definitions(${BINARY_NAME} PRIVATE "NOMINMAX")

# ========== 依赖库链接 ==========

# Add dependency libraries and include directories. Add any application-specific
# dependencies here.
target_link_libraries(${BINARY_NAME} PRIVATE flutter flutter_wrapper_app)

# Windows 视觉效果相关库
target_link_libraries(${BINARY_NAME} PRIVATE
  dwmapi.lib      # Desktop Window Manager API
  comctl32.lib    # Common Controls
  gdi32.lib       # GDI (Graphics Device Interface)
  user32.lib      # User API
)

target_include_directories(${BINARY_NAME} PRIVATE "${CMAKE_SOURCE_DIR}")

# ========== Windows 特定属性 ==========

# 设置子系统为 Windows（无控制台）
if(MSVC)
  set_target_properties(${BINARY_NAME} PROPERTIES
    LINK_FLAGS "/SUBSYSTEM:WINDOWS /ENTRY:mainCRTStartup"
  )
endif()

# 设置输出目录
set_target_properties(${BINARY_NAME} PROPERTIES
  RUNTIME_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/runner"
)

# ========== 高 DPI 支持 ==========

# 确保 manifest 文件被正确嵌入
target_sources(${BINARY_NAME} PRIVATE "runner.exe.manifest")

# ========== Flutter 构建依赖 ==========

# Run the Flutter tool portions of the build. This must not be removed.
add_dependencies(${BINARY_NAME} flutter_assemble)
