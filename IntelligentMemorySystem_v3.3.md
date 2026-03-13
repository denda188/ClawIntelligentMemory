# 智能记忆系统 3.3 - 完整实施指南
**版本**: v3.3
**最后更新**: 2026-03-13
**系统状态**: 29 个定时任务运行中
**维护者**: Denda

---

## 目录
1. [系统概述](#系统概述)
2. [核心架构](#核心架构)
3. [定时任务系统](#定时任务系统)
4. [关键脚本详解](#关键脚本详解)
5. [安装与配置](#安装与配置)
6. [使用指南](#使用指南)
7. [故障排除](#故障排除)
8. [性能指标](#性能指标)

## 系统概述
智能记忆系统 3.3 是一个基于 PARA 架构的三层记忆管理系统,集成了智能检查点,语义搜索,自动分类和两级摘要功能.

### 核心特性
- **三层记忆架构**: 每日日志 → MEMORY.md → 档案库
- **智能检查点**: 每 6 小时 LLM 提取关键记忆
- **语义搜索**: QMD 向量搜索 + 全文搜索
- **自动分类**: 7 种记忆类型,类型特定衰减率
- **两级摘要**: m1(任务级) → m2(宏观) 恒定上下文
- **资源感知**: 系统资源监控,智能决策参与

### 技术栈
- **搜索**: QMD (向量搜索 + 全文搜索)
- **定时任务**: OpenClaw Cron (15 个任务)
- **分类**: Python + Bash 混合实现
- **摘要**: Bash 脚本 + LLM 集成

## 核心架构

### 三层记忆结构
```
原始对话 → memory/YYYY-MM-DD.md (原始日志)
 ↓
 MEMORY.md (精选记忆,<3000 字符)
 life/archives/ (归档记忆,按需检索)

### 两级摘要系统
任务完成 → m1 摘要 (~150 字)
 ↓ (积累 20 个)
 m2 宏观摘要 (~200 字)
 代理上下文 (恒定长度)

### 记忆类型分类
决策, 衰减率=-0.3, 归档周期=永不归档, 示例=系统架构决策
偏好, 衰减率=-0.2, 归档周期=永不归档, 示例=用户偏好设置
关系, 衰减率=-0.1, 归档周期=永不归档, 示例=人际关系记录
技能, 衰减率=0.5, 归档周期=180 天, 示例=学习的新技能
事件, 衰减率=0.7, 归档周期=90 天, 示例=重要事件记录
事实, 衰减率=0.8, 归档周期=30 天, 示例=客观事实信息
上下文, 衰减率=0.9, 归档周期=7 天, 示例=临时上下文

## 定时任务系统

### 任务总览 (15 个运行中)
记忆系统, 任务数=3, 频率=6h/天/天, 说明=维护,检查点,心跳
战略分析, 任务数=2, 频率=天/天, 说明=夜间维护,知识库更新
社区参与, 任务数=1, 频率=8h, 说明=Moltbook 检测
智能监控, 任务数=3, 频率=30m/天/天, 说明=压缩,清理,自检
智能分类, 任务数=1, 频率=周, 说明=每周一分类
质量评分, 任务数=1, 频率=月, 说明=每月 1 日评估
Claw 压缩, 任务数=2, 频率=30m/天, 说明=统一压缩,清理
两级摘要, 任务数=1, 频率=4h, 说明=监控每 4 小时
V4 自动化, 任务数=1, 频率=天, 说明=每日 10 点优化
数据一致性, 任务数=1, 频率=天, 说明=每日 12 点监控

### 关键定时任务详情

#### 1. 记忆系统维护 (合并版)
- **频率**: 每 6 小时
- **脚本**: `para-system/maintenance/memory-maintenance-combined.sh`
- **功能**: 衰减权重更新 + 检查点提取
- **任务 ID**: `memory-maintenance-combined`

#### 2. QMD 综合维护
- **频率**: 每天 06:00, **脚本**: `para-system/maintenance/qmd-full-maintenance.sh`, **功能**: 深度索引优化,清理过期文件,重建向量嵌入, **任务 ID**: `926adaf9-d949-4151-b58d-6001a3d19521`

#### 3. 夜间深度分析
- **频率**: 每天 03:00
- **脚本**: `para-system/maintenance/nightly-deep-analysis.sh`
- **功能**: 使用 LLM 分析最近 7 天记忆模式,生成战略建议
- **任务 ID**: `48018ad2-6f59-4d3d-a5f9-982936bab438`

#### 4. 两级摘要监控
- **频率**: 每 4 小时
- **脚本**: `two-level-memory/scripts/enhanced-monitor.sh`
- **功能**: m1/m2 数量检查,动态阈值计算,自动 m2 生成
- **任务 ID**: `a981c7b2-29f6-4c85-8fd6-6ab54a5c7ee5`

#### 5. 优化版预压缩钩子
- **频率**: 每 2 小时
- **脚本**: `para-system/maintenance/pre-compression-hook-optimized.sh`, **功能**: 上下文使用率监控,紧急保存,冷却机制, **任务 ID**: `55317b02-0034-4eae-b213-d6aedc1e314d`

## 关键脚本详解

### 1. 两级摘要集成脚本
**位置**: `para-system/scripts/two-level-memory-integration.sh`

**功能**:
- 生成 m1 单任务摘要 (~150 字)
- 阈值触发 m2 宏观摘要 (~200 字)
- 与记忆检查点集成

**使用方法**:
```bash

# 生成 m1 摘要
./two-level-memory-integration.sh generate-m1 "task-123" "任务描述" "详细内容"

# 检查系统状态
./two-level-memory-integration.sh status

# 测试功能
./two-level-memory-integration.sh test

**核心逻辑**:

# m1 生成
generate_m1() {
 local task_id="$1"
 local task_desc="$2"
 local task_content="$3"

 # 创建 m1 文件
 cat > "$m1_file" << EOF

# m1 摘要 - $task_id

## 任务描述
$task_desc

## 任务摘要
$task_content
EOF
}

# m2 生成 (阈值触发)
check_m2_generation() {
 local m1_count=$(find "$TWO_LEVEL_DIR/m1" -name "m1-*.md" | wc -l)
 if [ "$m1_count" -ge 20 ]; then
 generate_m2
 fi

### 2. 记忆系统维护 (合并版)
**位置**: `para-system/maintenance/memory-maintenance-combined.sh`

- 衰减权重更新, 检查点提取, 日志记录

# 1. 衰减权重更新
bash "$WORKSPACE/para-system/maintenance/update-memory-decay.sh"

# 2. 检查点提取
bash "$WORKSPACE/para-system/maintenance/checkpoint-memory-llm.sh.original"

### 3. QMD 完整维护
**位置**: `para-system/maintenance/qmd-full-maintenance.sh`

- 清理缓存和临时文件, 增量更新索引, 增量嵌入向量, 检查文件完整性

# 1. 清理缓存
qmd cleanup

# 2. 增量更新索引
for DIR in life memory workspace; do
 NEW_IN_DIR=$(find "$WORKSPACE/$DIR" -name "*.md" -newer "$INDEX_FILE" | wc -l)
 if [ "$NEW_IN_DIR" -gt 0 ]; then
 qmd collection rm "$DIR"
 qmd collection add "$WORKSPACE/$DIR" --name "$DIR"
done

# 3. 嵌入向量
qmd embed

### 4. 夜间深度分析
**位置**: `para-system/maintenance/nightly-deep-analysis.sh`

- 深度记忆分析 (最近 7 天)
- 知识图谱构建, 系统性能分析, 脚本审计

# 收集最近 7 天记忆
recent_logs=$(find "$WORKSPACE/memory" -name "2026-*.md" -mtime -7)

# 使用 LLM 分析
prompt="分析以下最近 7 天的记忆内容,提取关键洞察:
1. 重复主题
2. 长期趋势
3. 知识盲点
4. 行动建议

记忆内容:$combined_content"

# 调用本地模型
curl -X POST "$OLLAMA_URL" -d "{\"model\":\"$MODEL\",\"prompt\":\"$prompt\"}"

### 5. Moltbook 资源感知检测
**位置**: `para-system/scripts/moltbook-resource-aware-check.sh`

- 检查系统资源 (CPU < 70%, 内存 < 80%)
- 检查 OpenClaw 活跃任务
- 检查时间间隔 (至少 4 小时)
- 智能社区参与

# 检查 CPU 使用率
cpu_usage=$(top -l 1 | grep "CPU usage" | awk '{print $3}' | sed 's/%//')

# 检查内存使用率
mem_info=$(top -l 1 | grep "PhysMem")
mem_usage=$(calculate_from_mem_info "$mem_info")

# 资源阈值
if [ "$cpu_usage" -lt 70 ] && [ "$mem_usage" -lt 80 ]; then
 # 参与社区
 moltbook_check

### 6. 预压缩钩子 (优化版)
**位置**: `para-system/maintenance/pre-compression-hook-optimized.sh`

- 上下文使用率监控, 紧急保存 (阈值 75%), 冷却机制 (60 分钟), 智能检测主会话

# 获取上下文使用率
usage=$(openclaw status --json | jq -r '.sessions.recent[] | select(.key == "agent:main:main") | .percentUsed')

# 检查冷却时间
check_cooldown() {
 diff_minutes=$(( (current_timestamp - last_timestamp) / 60 ))
 if [ "$diff_minutes" -lt 60 ]; then
 return 1 # 冷却中

# 紧急保存
if [ "$usage" -ge 75 ]; then
 save_emergency_summary_light

### 7. 增强版分类工作流
**位置**: `para-system/maintenance/integrated-categorization-workflow.sh`

- 增强版分类 (132 个关键词), 质量评分 (6 维度), 综合报告生成

# 运行增强版分类
./enhanced-smart-categorization.sh

# 运行质量评分
./simple-quality-scorer.sh

# 生成综合报告
generate_comprehensive_report

### 8. 两级摘要监控
**位置**: `two-level-memory/scripts/enhanced-monitor.sh`

- m1/m2 数量检查, 动态阈值计算, 自动 m2 生成, 监控报告生成

# 检查数量
m1_count=$(ls -1 "$M1_DIR"/*.md | wc -l)
m2_count=$(ls -1 "$M2_DIR"/*.md | wc -l)

# 动态阈值
dynamic_threshold=$(cat "$BASE_DIR/dynamic-threshold-config.json" | jq '.current_threshold')

# 自动生成 m2
if [ "$m1_count" -ge "$dynamic_threshold" ]; then
 "$BASE_DIR/scripts/generate-m2.sh"

## 安装与配置

### 前置要求
1. **OpenClaw**: 已安装并配置
2. **QMD**: `npm install -g qmd`
3. **Ollama**: 本地模型运行 (可选)
4. **Node.js**: v22+

### 安装步骤

#### 1. 克隆工作空间
cd path../Space

# 确保目录结构存在
mkdir -p para-system/{scripts,maintenance,config,docs}
mkdir -p memory life/{projects,areas,resources,archives}
mkdir -p two-level-memory/{m1,m2,logs,scripts}

# 初始化 QMD
qmd init

# 添加集合
qmd collection add path../Space/life --name life --mask "**/*.md"
qmd collection add path../Space/memory --name memory --mask "**/*.md"
qmd collection add path../Space/workspace --name workspace --mask "**/*.md"

# 嵌入向量

# 查看现有任务
openclaw cron list

# 添加记忆系统维护 (每 6 小时)
openclaw cron add --name "记忆系统维护 (合并版)" \
 --every "6h" \
 --command "bash path../Space/para-system/maintenance/memory-maintenance-combined.sh" \
 --agent main \
 --delivery announce

# 添加 QMD 维护 (每天 06:00)
openclaw cron add --name "QMD 综合维护" \
 --at "06:00" \
 --command "bash path../Space/para-system/maintenance/qmd-full-maintenance.sh" \
 --agent main

# 添加夜间分析 (每天 03:00)
openclaw cron add --name "夜间深度分析" \
 --at "03:00" \
 --command "bash path../Space/para-system/maintenance/nightly-deep-analysis.sh" \

#### 4. 配置记忆类型
创建 `para-system/config/memory-types.json`:

```json
{
 "types": {
 "决策": { "decay_rate": -0.3, "archive_days": null },
 "偏好": { "decay_rate": -0.2, "archive_days": null },
 "关系": { "decay_rate": -0.1, "archive_days": null },
 "技能": { "decay_rate": 0.5, "archive_days": 180 },
 "事件": { "decay_rate": 0.7, "archive_days": 90 },
 "事实": { "decay_rate": 0.8, "archive_days": 30 },
 "上下文": { "decay_rate": 0.9, "archive_days": 7 }

#### 5. 配置两级摘要
创建 `two-level-memory/config.json`:

 "m1_threshold": 20,
 "m1_max_words": 150,
 "m2_max_words": 200,
 "auto_generate": true,
 "integration_enabled": true

## 使用指南

### 日常使用

# 手动添加到今日日志
echo "## 新决策" >> memory/$(date +%Y-%m-%d).md
echo "- 决定实施两级摘要系统" >> memory/$(date +%Y-%m-%d).md

# 等待检查点自动提取 (每 6 小时)

# 全文搜索
qmd search "关键词" -n 10

# 向量搜索
qmd search "概念描述" --vector -n 10

# 混合搜索
qmd search "关键词" --hybrid -n 10

# 任务完成后生成 m1
./para-system/scripts/two-level-memory-integration.sh \
 generate-m1 "task-$(date +%s)" \
 "优化记忆系统" \
 "实施了两级摘要系统,上下文使用率从 67% 降至 15%"

### 维护命令

# 记忆系统维护
./para-system/maintenance/memory-maintenance-combined.sh

# QMD 维护
./para-system/maintenance/qmd-full-maintenance.sh

# 夜间分析 (手动触发)
./para-system/maintenance/nightly-deep-analysis.sh

# 查看 QMD 状态
qmd status

# 查看记忆健康
./para-system/memory-health-dashboard.sh

# 查看两级摘要状态
./two-level-memory/scripts/enhanced-monitor.sh

# 检查点日志
tail -50 path../Space/memory/checkpoint-*.log

# QMD 日志
tail -50 path../Space/para-system/qmd-update.log

# 夜间分析日志
tail -50 path../Space/para-system/nightly-analysis-*.log

# 两级摘要日志
tail -50 path../Space/two-level-memory/logs/*.log

## 故障排除

### 定时任务未执行
**症状**: 定时任务显示 error 或未运行

**解决方案**:

# 1. 检查 OpenClaw 服务
openclaw status

# 2. 检查 cron 服务
openclaw cron status

# 4. 手动运行测试
openclaw cron run --name "记忆系统维护 (合并版)"

# 5. 查看日志
tail -50 path../Space/para-system/logs/*.log

### QMD 搜索无结果
**症状**: `qmd search` 返回空结果

# 1. 手动更新索引
qmd collection rm life memory workspace
qmd collection add life --name life --mask "**/*.md"
qmd collection add memory --name memory --mask "**/*.md"
qmd collection add workspace --name workspace --mask "**/*.md"

# 3. 检查索引文件
ls -la ~/.cache/qmd/

# 4. 测试搜索
qmd search "测试" -n 5

### 上下文使用率过高
**症状**: 上下文使用率 > 75%

# 1. 立即执行预压缩钩子
./para-system/maintenance/pre-compression-hook-optimized.sh

# 2. 手动紧急摘要
mkdir -p .cache/memory-system/emergency
cp MEMORY.md .cache/memory-system/emergency/emergency-$(date +%Y%m%d-%H%M%S).md

# 3. 重启 OpenClaw (极端情况)
openclaw gateway restart

# 4. 查看使用率
openclaw status --json | jq '.sessions.recent[] | {key, percentUsed}'

### 两级摘要未生成
**症状**: m1 积累超过阈值但未生成 m2

# 1. 检查 m1 数量
ls -1 two-level-memory/m1/*.md | wc -l

# 2. 检查阈值配置
cat two-level-memory/dynamic-threshold-config.json

# 3. 手动生成 m2
./two-level-memory/scripts/generate-m2.sh

# 4. 检查监控日志
tail -50 two-level-memory/logs/enhanced-monitor-*.log

### 记忆分类不准确
**症状**: 分类置信度低或分类错误

# 1. 运行增强分类
./para-system/maintenance/enhanced-smart-categorization.sh

# 2. 查看分类结果
cat .cache/memory-system/categories/enhanced-categorized-results.json | jq '.[] | {text, category, confidence}'

# 4. 重新运行分类
./para-system/maintenance/integrated-categorization-workflow.sh

## 性能指标

### 记忆系统
MEMORY.md 大小, 目标值=< 3000 字符, 当前值=2807 字符, 状态=
检查点频率, 目标值=每 6 小时, 当前值=每 6 小时, 状态=
健康评分, 目标值=> 80, 当前值=92.5, 状态=
分类准确率, 目标值=> 90%, 当前值=100%, 状态=
归档准确率, 目标值=> 85%, 当前值=85%, 状态=

### QMD 索引
| 索引文件数 | - | 37 个 | |
| 向量块数 | - | 102 个 | |
| 更新策略 | 自适应 | 自适应 | |
| 资源节省 | > 70% | 80% | |

### 搜索性能
全文搜索, 目标时间=< 1 秒, 实际时间=< 1 秒, 状态=
向量搜索, 目标时间=1-3 秒, 实际时间=1-3 秒, 状态=
混合搜索, 目标时间=10-30 秒, 实际时间=10-30 秒, 状态=

### 两级摘要
| m1 阈值 | 20 | 20 | |
| m1 字数 | ~150 | ~150 | |
| m2 字数 | ~200 | ~200 | |
| 上下文使用率 | < 20% | 15% | |
| 准确率提升 | > 10% | +12% | |

### 定时任务
| 任务总数 | - | 15 个 | |
| 正常运行 | 100% | 100% | |
| 错误任务 | 0 | 0 | |
| 通知送达 | > 95% | 100% | |

## 附录

### A. 完整脚本列表
**记忆系统**:
- `para-system/maintenance/memory-maintenance-combined.sh`, `para-system/maintenance/checkpoint-memory-llm.sh`, `para-system/maintenance/memory-health-dashboard.sh`, `para-system/maintenance/update-memory-decay.sh`

**QMD 索引**:
- `para-system/maintenance/qmd-full-maintenance.sh`
- `para-system/maintenance/qmd-adaptive-update.sh`

**战略分析**:
- `para-system/maintenance/nightly-deep-analysis.sh`
- `para-system/maintenance/maintain-knowledge-base.sh`

**社区参与**:
- `para-system/scripts/moltbook-resource-aware-check.sh`

**监控压缩**:
- `para-system/maintenance/pre-compression-hook-optimized.sh`
- `para-system/maintenance/claw-compactor.sh`

**分类评分**:
- `para-system/maintenance/integrated-categorization-workflow.sh`, `para-system/maintenance/enhanced-smart-categorization.sh`, `para-system/maintenance/simple-quality-scorer.sh`

**两级摘要**:
- `para-system/scripts/two-level-memory-integration.sh`
- `two-level-memory/scripts/enhanced-monitor.sh`

### B. 配置文件列表
- `para-system/config/memory-types.json` - 记忆类型定义, `para-system/config/categorization-keywords.json` - 分类关键词, `para-system/config/clarifying-questions-config.json` - 澄清问题配置, `two-level-memory/config.json` - 两级摘要配置, `two-level-memory/dynamic-threshold-config.json` - 动态阈值

### C. 相关文档
- `AGENTS.md` - 记忆系统架构和使用指南, `MEMORY.md` - 精选长期记忆, `HEARTBEAT.md` - 定时任务完整配置
- `SOUL.md` - AI 助手个性和原则
- `TOOLS.md` - 本地工具配置

# 搜索
qmd search "概念" --vector -n 10

# 两级摘要
./para-system/scripts/two-level-memory-integration.sh status

# 查看日志
tail -f path../Space/para-system/logs/*.log

**文档维护**: 每次系统更新后同步更新此文档
**最后同步**: 2026-03-13
**维护者**: Denda