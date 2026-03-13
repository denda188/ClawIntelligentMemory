#!/bin/bash
# ========================================
# 预压缩钩子 - 上下文压缩保护机制（优化版）
# ========================================
# 功能：在上下文压缩前自动保存关键记忆
# 触发条件：上下文使用率 > 75%
# 冷却时间：60 分钟
# 维护者：Denda
# ========================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_DIR="/Volumes/Data/MySpace/.cache/memory-system"
STATE_FILE="/Volumes/Data/MySpace/.cache/memory-system/precomp-state.json"
MEMORY_FILE="/Volumes/Data/MySpace/MEMORY.md"
TASKS_FILE="/Volumes/Data/MySpace/life/areas/open-threads/open-threads.json"
EMERGENCY_DIR="/Volumes/Data/MySpace/.cache/memory-system/emergency"
ACTIVE_TASK_FILE="/Volumes/Data/MySpace/ACTIVE-TASK.md"

# 阈值配置
WARNING_THRESHOLD=60   # 警告线
CRITICAL_THRESHOLD=75  # 紧急线（从 70% 提高到 75%）
COOLDOWN_MINUTES=60    # 冷却时间（避免频繁触发）

# 最小化日志输出（避免增加上下文使用率）
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_DIR/precomp-hook.log"
}

warn() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] ⚠️ $1" >> "$LOG_DIR/precomp-hook.log"
}

error() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] ❌ $1" >> "$LOG_DIR/precomp-hook.log"
}

success() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] ✅ $1" >> "$LOG_DIR/precomp-hook.log"
}

# 创建必要的目录
mkdir -p "$EMERGENCY_DIR"
mkdir -p "$LOG_DIR"

# 检查冷却时间
check_cooldown() {
    if [ ! -f "$STATE_FILE" ]; then
        return 0  # 无状态文件，可以执行
    fi
    
    local last_emergency
    last_emergency=$(jq -r '.last_emergency_save // empty' "$STATE_FILE" 2>/dev/null || echo "")
    
    if [ -z "$last_emergency" ]; then
        return 0  # 无紧急保存记录，可以执行
    fi
    
    # 转换为时间戳
    local last_timestamp current_timestamp diff_minutes
    last_timestamp=$(date -j -f "%Y-%m-%dT%H:%M:%SZ" "$last_emergency" "+%s" 2>/dev/null || echo "0")
    current_timestamp=$(date "+%s")
    
    if [ "$last_timestamp" -eq "0" ]; then
        return 0  # 时间格式错误，忽略冷却
    fi
    
    diff_minutes=$(( (current_timestamp - last_timestamp) / 60 ))
    
    if [ "$diff_minutes" -lt "$COOLDOWN_MINUTES" ]; then
        log "冷却时间：距离上次紧急保存仅 $diff_minutes 分钟，跳过执行（需要等待 $COOLDOWN_MINUTES 分钟）"
        return 1
    fi
    
    return 0
}

# 智能获取主会话上下文使用率
get_context_usage() {
    # 方法 1：直接获取主会话
    local usage
    usage=$(openclaw status --json 2>/dev/null | jq -r '.sessions.recent[] | select(.key == "agent:main:main") | .percentUsed // 0' 2>/dev/null || echo "0")
    
    # 如果获取失败或为 0，尝试其他方法
    if [ -z "$usage" ] || [ "$usage" = "null" ] || [ "$usage" = "0" ]; then
        # 方法 2：查找最新的非 cron 会话
        usage=$(openclaw status --json 2>/dev/null | jq -r '.sessions.recent[] | select(.key | test("agent:main:main") and (contains("cron") | not)) | .percentUsed // 0' 2>/dev/null | head -1 || echo "0")
    fi
    
    # 确保是数字
    if ! [[ "$usage" =~ ^[0-9]+$ ]]; then
        usage=0
    fi
    
    echo "$usage"
}

# 轻量级紧急摘要保存
save_emergency_summary_light() {
    log "开始轻量级紧急摘要保存..."
    
    local timestamp=$(date +%Y%m%d-%H%M%S)
    local emergency_file="$EMERGENCY_DIR/emergency-summary-$timestamp.md"
    
    # 1. 保存 MEMORY.md
    if [ -f "$MEMORY_FILE" ]; then
        cp "$MEMORY_FILE" "$emergency_file"
        log "已保存 MEMORY.md -> $emergency_file"
    fi
    
    # 2. 保存开放线程
    if [ -f "$TASKS_FILE" ]; then
        cp "$TASKS_FILE" "$EMERGENCY_DIR/emergency-tasks-$timestamp.json"
        log "已保存开放线程"
    fi
    
    # 3. 保存活跃任务
    if [ -f "$ACTIVE_TASK_FILE" ]; then
        cp "$ACTIVE_TASK_FILE" "$EMERGENCY_DIR/emergency-active-task-$timestamp.md"
        log "已保存活跃任务"
    fi
    
    # 4. 更新状态文件
    cat > "$STATE_FILE" << EOF
{
  "last_emergency_save": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "context_usage_at_save": $(get_context_usage),
  "files_saved": [
    "$emergency_file",
    "$EMERGENCY_DIR/emergency-tasks-$timestamp.json",
    "$EMERGENCY_DIR/emergency-active-task-$timestamp.md"
  ]
}
EOF
    
    success "紧急摘要保存完成"
    log "紧急摘要保存完成，文件：$emergency_file"
}

# 主函数
main() {
    log "=========================================="
    log "预压缩钩子检查开始"
    
    # 1. 检查冷却时间
    if ! check_cooldown; then
        log "冷却时间中，跳过执行"
        exit 0
    fi
    
    # 2. 获取上下文使用率
    local usage=$(get_context_usage)
    log "当前上下文使用率：$usage%"
    
    # 3. 检查阈值
    if [ "$usage" -ge "$CRITICAL_THRESHOLD" ]; then
        warn "上下文使用率达到紧急阈值 ($usage% >= $CRITICAL_THRESHOLD%)"
        save_emergency_summary_light
        success "紧急保存完成"
    elif [ "$usage" -ge "$WARNING_THRESHOLD" ]; then
        warn "上下文使用率达到警告阈值 ($usage% >= $WARNING_THRESHOLD%)"
        log "继续监控，暂不执行紧急保存"
    else
        log "上下文使用率正常 ($usage% < $WARNING_THRESHOLD%)"
    fi
    
    log "预压缩钩子检查完成"
    log "=========================================="
}

main "$@"
