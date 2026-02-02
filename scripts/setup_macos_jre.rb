#!/usr/bin/env ruby
# macOS Xcode Build Phase 配置脚本
# 运行此脚本将 JRE 复制阶段添加到 Xcode 项目中
# Usage: ruby scripts/setup_macos_jre.rb

require 'xcodeproj'

# 获取脚本所在目录的上级目录（项目根目录）
SCRIPT_DIR = File.dirname(File.expand_path(__FILE__))
PROJECT_DIR = File.dirname(SCRIPT_DIR)
PROJECT_PATH = File.join(PROJECT_DIR, 'macos', 'Runner.xcodeproj')
JRE_SOURCE_DIR = File.join(PROJECT_DIR, 'macos', 'Runner', 'jre')

puts "配置 Xcode 项目: #{PROJECT_PATH}"

# 检查 JRE 是否存在
unless File.exist?(JRE_SOURCE_DIR)
  puts "⚠️  警告: JRE 源目录不存在: #{JRE_SOURCE_DIR}"
  puts "请确保已将 JRE 复制到 macos/Runner/jre 目录"
  exit 1
end

# 打开项目
project = Xcodeproj::Project.open(PROJECT_PATH)

# 获取主 target
main_target = project.targets.find { |t| t.name == 'Runner' }
raise "找不到 Runner target" unless main_target

# 检查是否已经存在此构建阶段
existing_phase = main_target.build_phases.find do |phase|
  phase.is_a?(Xcodeproj::Project::Object::PBXShellScriptBuildPhase) &&
    phase.name == 'Copy JRE'
end

if existing_phase
  puts "删除旧的 'Copy JRE' 构建阶段"
  main_target.build_phases.delete(existing_phase)
  existing_phase.remove_from_project
end

# 创建新的 Shell Script 构建阶段
shell_script = project.new(Xcodeproj::Project::Object::PBXShellScriptBuildPhase)
shell_script.name = 'Copy JRE'
shell_script.shell_path = '/bin/bash'
# 直接使用复制命令，复制 JRE 到 app bundle 的 Resources
shell_script.shell_script = <<~SCRIPT
  set -e

  # JRE 源目录（相对于项目根目录）
  JRE_SOURCE="${PROJECT_DIR}/Runner/jre"

  # 目标路径（app bundle 的 Resources 目录）
  JRE_DEST="${BUILT_PRODUCTS_DIR}/${CONTENTS_FOLDER_PATH}/Resources/jre"

  echo "Copying JRE from: $JRE_SOURCE"
  echo "Copying JRE to: $JRE_DEST"

  if [ -d "$JRE_SOURCE" ]; then
    rm -rf "$JRE_DEST"
    cp -R "$JRE_SOURCE" "$JRE_DEST"
    echo "JRE copied successfully"
  else
    echo "Warning: JRE source not found: $JRE_SOURCE"
  fi
SCRIPT

shell_script.show_env_vars_in_log = '0'

# 添加输出文件以避免每次构建都运行
shell_script.output_paths = ['$(BUILT_PRODUCTS_DIR)/$(CONTENTS_FOLDER_PATH)/Resources/jre']

# 找到 "Copy Bundle Resources" 阶段
resources_phase = main_target.build_phases.find do |phase|
  phase.is_a?(Xcodeproj::Project::Object::PBXResourcesBuildPhase)
end

if resources_phase
  # 在 Copy Bundle Resources 之后添加
  main_target.build_phases.insert(
    main_target.build_phases.index(resources_phase) + 1,
    shell_script
  )
  puts "已添加 'Copy JRE' 构建阶段到 Copy Bundle Resources 之后"
else
  # 如果找不到，就添加到末尾
  main_target.build_phases << shell_script
  puts "已添加 'Copy JRE' 构建阶段到末尾"
end

# 保存项目
project.save

puts "✅ Xcode 项目配置完成"
