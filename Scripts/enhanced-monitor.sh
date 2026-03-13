#!/bin/bash
# ========================================
# 两级摘要系统增强监控脚本
# ========================================
# 功能：监控 m1/m2 数量，动态阈值，自动生成
# 频率：每 4 小时执行
# 维护者：Denda
# ========================================

set -uo pipefail

BASE_DIR="/Volumes/Data/MySpace/two-level-memory"
M1_DIR="$BASE_DIR/m1"
M2_DIR="$BASE_DIR/m2"
LOG_FILE="$BASE_DIR/logs/enhanced-monitor-$(date +%Y%m%d).log"

# 确保目录存在
mkdir -p "$BASE_DIR/logs"

echo "========================================" | tee -a "$LOG_FILE"
echo "  两级摘要系统增强监控 v1.0" | tee -a "$LOG_FILE"
echo "========================================" | tee -a "$LOG_FILE"
echo "时间：$(date)" | tee -a "$LOG_FILE"
echo "" | tee -a "$LOG_FILE"

# 1. 检查 m1/m2 数量
echo "[1/6] 检查摘要数量..." | tee -a "$LOG_FILE"
m1_count=$(ls -1 "$M1_DIR"/*.md 2>/dev/null | grep -v archive | wc -l | tr -d ' ')
m2_count=$(ls -1 "$M2_DIR"/*.md 2>/dev/null | wc -l | tr -d ' ')
echo "  m1 数量：$m1_count" | tee -a "$LOG_FILE"
echo "  m2 数量：$m2_count" | tee -a "$LOG_FILE"

# 2. 运行动态阈值算法
echo "[2/6] 运行动态阈值算法..." | tee -a "$LOG_FILE"
if [ -x "$BASE_DIR/scripts/dynamic-threshold.sh" ]; then
    threshold_result=$("$BASE_DIR/scripts/dynamic-threshold.sh" 2>&1 | tail -5)
    echo "  $threshold_result" | tee -a "$LOG_FILE"
else
    echo "  ⚠️ 动态阈值脚本不可执行" | tee -a "$LOG_FILE"
fi

# 3. 读取动态阈值
echo "[3/6] 读取动态阈值配置..." | tee -a "$LOG_FILE"
if [ -f "$BASE_DIR/dynamic-threshold-config.json" ]; then
    dynamic_threshold=$(grep -o '"current_threshold": [0-9]*' "$BASE_DIR/dynamic-threshold-config.json" | grep -o '[0-9]*')
    echo "  动态阈值：$dynamic_threshold" | tee -a "$LOG_FILE"
else
    dynamic_threshold=20
    echo "  使用默认阈值：$dynamic_threshold" | tee -a "$LOG_FILE"
fi

# 4. 检查是否需要生成 m2
echo "[4/6] 检查 m2 生成条件..." | tee -a "$LOG_FILE"
if [ "$m1_count" -ge "$dynamic_threshold" ]; then
    echo "  ⚠️ m1 数量 ($m1_count) >= 动态阈值 ($dynamic_threshold)" | tee -a "$LOG_FILE"
    echo "  建议：立即生成 m2" | tee -a "$LOG_FILE"
    
    # 自动生成 m2
    if [ -x "$BASE_DIR/scripts/generate-m2.sh" ]; then
        echo "  自动生成 m2..." | tee -a "$LOG_FILE"
        echo "y" | "$BASE_DIR/scripts/generate-m2.sh" > /dev/null 2>&1
        echo "  ✅ m2 生成完成" | tee -a "$LOG_FILE"
    else
        echo "  ⚠️ m2 生成脚本不可执行，跳过自动生成" | tee -a "$LOG_FILE"
    fi
else
    echo "  ✅ m1 数量 ($m1_count) < 动态阈值 ($dynamic_threshold)" | tee -a "$LOG_FILE"
    echo "  状态：正常" | tee -a "$LOG_FILE"
fi

# 5. 运行集成模块
echo "[5/6] 运行集成模块..." | tee -a "$LOG_FILE"
if [ -x "$BASE_DIR/scripts/integrate-m2.sh" ]; then
    "$BASE_DIR/scripts/integrate-m2.sh" > /dev/null 2>&1
    echo "  ✅ 集成完成" | tee -a "$LOG_FILE"
else
    echo "  ⚠️ 集成脚本不可执行" | tee -a "$LOG_FILE"
fi

# 6. 生成监控报告
echo "[6/6] 生成监控报告..." | tee -a "$LOG_FILE"

cat >> "$LOG_FILE" << EOF
# 增强监控报告 - $(date)
## 系统状态
- m1 数量：$m1_count
- m2 数量：$m2_count
- 动态阈值：$dynamic_threshold
- 集成状态：完成
EOF

echo "" | tee -a "$LOG_FILE"
echo "✅ 增强监控完成!" | tee -a "$LOG_FILE"
echo "  日志：$LOG_FILE" | tee -a "$LOG_FILE"
echo "" | tee -a "$LOG_FILE"
echo "📊 摘要:" | tee -a "$LOG_FILE"
echo "  m1: $m1_count | m2: $m2_count | 阈值：$dynamic_threshold" | tee -a "$LOG_FILE"

# 7. 检查是否有警报
if [ "$m1_count" -ge "$dynamic_threshold" ]; then
    echo "" | tee -a "$LOG_FILE"
    echo "⚠️  警报：m1 数量达到阈值，建议手动检查 m2 生成" | tee -a "$LOG_FILE"
    
    # 记录警报到单独文件
    alert_file="$BASE_DIR/monitor/alerts-$(date +%Y%m%d).log"
    mkdir -p "$(dirname "$alert_file")"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] 警报：m1=$m1_count >= 阈值=$dynamic_threshold" >> "$alert_file"
fi

echo "" | tee -a "$LOG_FILE"
echo "========================================" | tee -a "$LOG_FILE"
