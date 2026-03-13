#!/bin/bash
# ========================================
# QMD 完整系统维护脚本
# ========================================
# 功能：清理缓存，增量更新索引，嵌入向量
# 频率：每天 06:00 执行
# 维护者：Denda
# ========================================

set -euo pipefail

WORKSPACE="/Volumes/Data/MySpace"
LOG_FILE="$WORKSPACE/para-system/logs/qmd-maintenance-$(date +%Y%m%d).log"

echo "🔧 QMD 完整系统维护 - $(date '+%Y-%m-%d %H:%M:%S')" | tee -a "$LOG_FILE"
echo "==================================================" | tee -a "$LOG_FILE"

# 0. 检查 QMD 是否安装
if ! command -v qmd &> /dev/null; then
    echo "❌ QMD 未安装，无法维护" | tee -a "$LOG_FILE"
    exit 1
fi

echo "📊 维护前系统状态:" | tee -a "$LOG_FILE"
echo "-------------------" | tee -a "$LOG_FILE"
qmd status 2>&1 | tee -a "$LOG_FILE"

# 1. 清理缓存和临时文件
echo "" | tee -a "$LOG_FILE"
echo "🧹 清理缓存和临时文件..." | tee -a "$LOG_FILE"
START_TIME=$(date +%s)
qmd cleanup 2>&1 | tee -a "$LOG_FILE"
CLEANUP_TIME=$(( $(date +%s) - START_TIME ))
echo "   清理耗时：${CLEANUP_TIME}秒" | tee -a "$LOG_FILE"

# 2. 增量更新索引（优化：只更新变化的集合）
echo "" | tee -a "$LOG_FILE"
echo "🔄 增量更新索引..." | tee -a "$LOG_FILE"
START_TIME=$(date +%s)

INDEX_FILE="$HOME/.cache/qmd/index.sqlite"
DIRS_TO_CHECK=("life" "memory" "workspace")

for DIR in "${DIRS_TO_CHECK[@]}"; do
    if [ -d "$WORKSPACE/$DIR" ]; then
        NEW_IN_DIR=$(find "$WORKSPACE/$DIR" -name "*.md" -type f -newer "$INDEX_FILE" 2>/dev/null | wc -l | tr -d ' ')
        if [ "$NEW_IN_DIR" -gt 0 ]; then
            echo "   🔄 更新 $DIR 集合 ($NEW_IN_DIR 个新文件)..." | tee -a "$LOG_FILE"
            qmd collection rm "$DIR" 2>/dev/null || true
            qmd collection add "$WORKSPACE/$DIR" --name "$DIR" --mask "**/*.md" 2>&1 | tee -a "$LOG_FILE"
        else
            echo "   ⏭️  $DIR 集合无变化，跳过" | tee -a "$LOG_FILE"
        fi
    fi
done
REINDEX_TIME=$(( $(date +%s) - START_TIME ))
echo "   更新耗时：${REINDEX_TIME}秒" | tee -a "$LOG_FILE"

# 3. 增量嵌入向量（优化：只嵌入新文件）
echo "" | tee -a "$LOG_FILE"
echo "🧠 增量嵌入向量..." | tee -a "$LOG_FILE"
START_TIME=$(date +%s)
qmd embed 2>&1 | tee -a "$LOG_FILE"
REEMBED_TIME=$(( $(date +%s) - START_TIME ))
echo "   嵌入耗时：${REEMBED_TIME}秒" | tee -a "$LOG_FILE"

# 4. 检查文件完整性
echo "" | tee -a "$LOG_FILE"
echo "🔍 检查文件完整性..." | tee -a "$LOG_FILE"

INVALID_FILES=()
EMPTY_FILES=()
LARGE_FILES=()

for DIR in life memory workspace; do
    if [ -d "$DIR" ]; then
        while IFS= read -r FILE; do
            if [ -n "$FILE" ]; then
                # 检查文件大小
                FILE_SIZE=$(stat -f %z "$FILE" 2>/dev/null || echo 0)
                
                # 空文件
                if [ "$FILE_SIZE" -eq 0 ]; then
                    EMPTY_FILES+=("$FILE")
                # 大文件（>10MB）
                elif [ "$FILE_SIZE" -gt 10485760 ]; then
                    LARGE_FILES+=("$FILE")
                fi
                
                # 检查文件可读性
                if ! head -1 "$FILE" >/dev/null 2>&1; then
                    INVALID_FILES+=("$FILE")
                fi
            fi
        done < <(find "$DIR" -name "*.md" -type f 2>/dev/null)
    fi
done

# 5. 显示检查结果
echo "" | tee -a "$LOG_FILE"
echo "📋 完整性检查结果:" | tee -a "$LOG_FILE"

if [ ${#EMPTY_FILES[@]} -gt 0 ]; then
    echo "   ⚠️  空文件 (${#EMPTY_FILES[@]}个):" | tee -a "$LOG_FILE"
    for file in "${EMPTY_FILES[@]}"; do
        echo "      - $file" | tee -a "$LOG_FILE"
    done
fi

if [ ${#LARGE_FILES[@]} -gt 0 ]; then
    echo "   ⚠️  大文件 (${#LARGE_FILES[@]}个):" | tee -a "$LOG_FILE"
    for file in "${LARGE_FILES[@]}"; do
        echo "      - $file ($(echo "scale=2; $(stat -f %z "$file") / 1048576" | bc)MB)" | tee -a "$LOG_FILE"
    done
fi

if [ ${#INVALID_FILES[@]} -gt 0 ]; then
    echo "   ❌ 无效文件 (${#INVALID_FILES[@]}个):" | tee -a "$LOG_FILE"
    for file in "${INVALID_FILES[@]}"; do
        echo "      - $file" | tee -a "$LOG_FILE"
    done
fi

if [ ${#EMPTY_FILES[@]} -eq 0 ] && [ ${#LARGE_FILES[@]} -eq 0 ] && [ ${#INVALID_FILES[@]} -eq 0 ]; then
    echo "   ✅ 所有文件正常" | tee -a "$LOG_FILE"
fi

# 6. 显示维护后状态
echo "" | tee -a "$LOG_FILE"
echo "📊 维护后系统状态:" | tee -a "$LOG_FILE"
echo "-------------------" | tee -a "$LOG_FILE"
qmd status 2>&1 | tee -a "$LOG_FILE"

# 7. 计算总耗时
TOTAL_TIME=$(( CLEANUP_TIME + REINDEX_TIME + REEMBED_TIME ))
echo "" | tee -a "$LOG_FILE"
echo "🎉 维护完成!" | tee -a "$LOG_FILE"
echo "  总耗时：${TOTAL_TIME}秒" | tee -a "$LOG_FILE"
echo "  清理：${CLEANUP_TIME}秒" | tee -a "$LOG_FILE"
echo "  更新：${REINDEX_TIME}秒" | tee -a "$LOG_FILE"
echo "  嵌入：${REEMBED_TIME}秒" | tee -a "$LOG_FILE"
echo "  日志：$LOG_FILE" | tee -a "$LOG_FILE"
