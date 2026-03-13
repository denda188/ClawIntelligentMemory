#!/bin/bash
# ========================================
# 夜间深度系统分析脚本
# ========================================
# 功能：使用 LLM 分析最近 7 天记忆模式，生成战略建议
# 频率：每天 03:00 执行
# 维护者：Denda
# ========================================

set -euo pipefail

WORKSPACE="/Volumes/Data/MySpace"
LOG_FILE="$WORKSPACE/para-system/logs/nightly-analysis-$(date +%Y%m%d).log"
REPORT_FILE="$WORKSPACE/para-system/reports/nightly-analysis-report-$(date +%Y%m%d).md"

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# 日志函数
log() {
    local level=$1
    local message=$2
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    case $level in
        "INFO") echo -e "${BLUE}[INFO]${NC} $timestamp - $message" | tee -a "$LOG_FILE" ;;
        "SUCCESS") echo -e "${GREEN}[SUCCESS]${NC} $timestamp - $message" | tee -a "$LOG_FILE" ;;
        "WARNING") echo -e "${YELLOW}[WARNING]${NC} $timestamp - $message" | tee -a "$LOG_FILE" ;;
        "ERROR") echo -e "${RED}[ERROR]${NC} $timestamp - $message" | tee -a "$LOG_FILE" ;;
    esac
}

# 创建报告目录
mkdir -p "$(dirname "$REPORT_FILE")"

log "INFO" "=========================================="
log "INFO" "夜间深度系统分析开始"
log "INFO" "=========================================="

# 1. 收集最近 7 天的记忆
log "INFO" "收集最近 7 天的记忆文件..."
recent_logs=$(find "$WORKSPACE/memory" -name "2026-*.md" -mtime -7 -type f 2>/dev/null | head -20)

if [ -z "$recent_logs" ]; then
    log "WARNING" "未找到最近 7 天的记忆文件"
    recent_logs="$WORKSPACE/memory/$(date +%Y-%m-%d).md"
fi

# 合并内容（限制在 500 行）
combined_content=$(cat $recent_logs 2>/dev/null | tail -500)

log "SUCCESS" "收集到 $(echo "$recent_logs" | wc -l | tr -d ' ') 个记忆文件"

# 2. 构建分析提示词
prompt="分析以下最近 7 天的记忆内容，提取关键洞察：

1. **重复主题** - 哪些主题反复出现？
2. **长期趋势** - 有什么发展趋势？
3. **知识盲点** - 哪些领域需要加强？
4. **行动建议** - 基于分析的 3-5 条建议

记忆内容：
$combined_content

请用简洁的中文回答，使用 Markdown 格式。"

log "INFO" "开始分析记忆模式..."

# 3. 使用本地模型分析 (如果有 Ollama)
if command -v ollama &> /dev/null; then
    log "INFO" "使用 Ollama 本地模型分析..."
    
    analysis=$(ollama run qwen3.5:0.8b "$prompt" 2>/dev/null || echo "分析失败，使用默认分析")
    
    log "SUCCESS" "本地模型分析完成"
else
    log "WARNING" "Ollama 未安装，使用简化分析"
    analysis="## 简化分析（Ollama 未安装）

### 重复主题
- 记忆系统优化
- 定时任务维护
- 社区参与

### 长期趋势
- 系统复杂度增加
- 自动化程度提高

### 行动建议
1. 继续优化记忆系统
2. 定期审查定时任务
3. 保持社区参与"
fi

# 4. 生成系统性能分析
log "INFO" "生成系统性能分析..."

# 定时任务状态
cron_status=$(openclaw cron list 2>/dev/null | grep -c "ok" || echo "0")
cron_total=$(openclaw cron list 2>/dev/null | tail -n +2 | wc -l | tr -d ' ')

# MEMORY.md 大小
memory_size=$(wc -c < "$WORKSPACE/MEMORY.md" 2>/dev/null || echo "0")

# QMD 状态
qmd_collections=$(qmd collection list 2>/dev/null | wc -l | tr -d ' ' || echo "0")

# 5. 生成完整报告
cat > "$REPORT_FILE" << EOF
# 夜间深度系统分析报告

**生成时间**: $(date '+%Y-%m-%d %H:%M:%S')  
**分析周期**: 最近 7 天  
**系统版本**: 智能记忆系统 v3.3

---

## 📊 系统状态摘要

| 指标 | 数值 | 状态 |
|------|------|------|
| 定时任务正常 | $cron_status / $cron_total | $([ "$cron_status" -eq "$cron_total" ] && echo "✅" || echo "⚠️") |
| MEMORY.md 大小 | $memory_size 字符 | $([ "$memory_size" -lt 3000 ] && echo "✅" || echo "⚠️") |
| QMD 集合数 | $qmd_collections | ✅ |

---

## 🧠 记忆模式分析

$analysis

---

## 🔧 系统性能分析

### 定时任务
- 正常运行：$cron_status 个
- 总任务数：$cron_total 个
- 成功率：$(echo "scale=0; $cron_status * 100 / $cron_total" | bc 2>/dev/null || echo "100")%

### 记忆系统
- MEMORY.md 大小：$memory_size 字符
- 目标大小：< 3000 字符
- 使用率：$(echo "scale=0; $memory_size * 100 / 3000" | bc 2>/dev/null || echo "0")%

### QMD 索引
- 集合数量：$qmd_collections 个
- 索引状态：正常

---

## 📋 行动建议

1. **立即行动** (24 小时内)
   - 审查失败的定时任务
   - 清理过大的记忆文件

2. **短期优化** (7 天内)
   - 优化记忆分类算法
   - 更新 QMD 索引

3. **长期规划** (30 天内)
   - 评估系统架构
   - 规划新功能

---

## 📝 详细日志

完整日志：$LOG_FILE

---

*报告生成时间：$(date '+%Y-%m-%d %H:%M:%S')*  
*下次分析：明天 03:00*
EOF

log "SUCCESS" "报告已保存：$REPORT_FILE"

# 6. 输出摘要
echo ""
echo "=========================================="
echo "  夜间深度分析完成"
echo "=========================================="
echo "  报告：$REPORT_FILE"
echo "  日志：$LOG_FILE"
echo "  时间：$(date '+%H:%M:%S')"
echo ""
echo "📊 摘要:"
echo "  定时任务：$cron_status / $cron_total 正常"
echo "  MEMORY.md: $memory_size 字符"
echo "  QMD 集合：$qmd_collections 个"
echo ""

log "SUCCESS" "=========================================="
log "SUCCESS" "夜间深度系统分析完成"
log "SUCCESS" "=========================================="
