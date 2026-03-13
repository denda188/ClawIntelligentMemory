#!/bin/bash
# ========================================
# 记忆系统维护 - 合并版
# ========================================
# 功能：衰减权重更新 + 检查点提取
# 频率：每 6 小时执行
# 维护者：Denda
# ========================================

set -euo pipefail

WORKSPACE="/Volumes/Data/MySpace"
LOG_FILE="$WORKSPACE/memory/maintenance-combined-$(date +%Y%m%d).log"

echo "🔧 [$(date '+%Y-%m-%d %H:%M:%S')] 记忆系统维护开始" | tee -a "$LOG_FILE"

# 1. 衰减权重更新
echo "📉 [1/2] 更新记忆衰减权重..." | tee -a "$LOG_FILE"
bash "$WORKSPACE/para-system/maintenance/update-memory-decay.sh" >> "$LOG_FILE" 2>&1
echo "✅ 衰减权重更新完成" | tee -a "$LOG_FILE"

# 2. 检查点提取 - 使用原始脚本，因为增强版本需要缺失的文件
echo "📝 [2/2] 执行记忆检查点..." | tee -a "$LOG_FILE"
bash "$WORKSPACE/para-system/maintenance/checkpoint-memory-llm.sh.original" >> "$LOG_FILE" 2>&1
echo "✅ 检查点完成" | tee -a "$LOG_FILE"

echo "🎉 [$(date '+%Y-%m-%d %H:%M:%S')] 记忆系统维护完成" | tee -a "$LOG_FILE"

# 输出摘要
echo ""
echo "📊 维护摘要:"
echo "  日志文件：$LOG_FILE"
echo "  完成时间：$(date '+%H:%M:%S')"
echo "  状态：成功"
