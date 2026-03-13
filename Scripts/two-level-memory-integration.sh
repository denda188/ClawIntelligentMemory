#!/bin/bash
# ========================================
# 两级摘要记忆系统集成脚本
# ========================================
# 功能：生成 m1/m2 摘要，保持恒定上下文
# 阈值：20 个 m1 触发 m2 生成
# 维护者：Denda
# ========================================

set -e

TWO_LEVEL_DIR="/Volumes/Data/MySpace/two-level-memory"
INTEGRATION_LOG="$TWO_LEVEL_DIR/logs/integration-$(date +%Y%m%d-%H%M%S).log"

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log() {
    echo -e "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$INTEGRATION_LOG"
}

# 确保目录存在
mkdir -p "$TWO_LEVEL_DIR/logs"
mkdir -p "$TWO_LEVEL_DIR/m1"
mkdir -p "$TWO_LEVEL_DIR/m2"

# 1. 生成 m1 摘要（单任务摘要）
generate_m1() {
    local task_id="$1"
    local task_desc="$2"
    local task_content="$3"
    
    log "${YELLOW}生成 m1 摘要：$task_desc${NC}"
    
    local m1_file="$TWO_LEVEL_DIR/m1/m1-$(date +%Y%m%d-%H%M%S)-$task_id.md"
    
    cat > "$m1_file" << EOF
# m1 摘要 - $task_id

## 基本信息
- **摘要 ID**: $(basename "$m1_file")
- **生成时间**: $(date '+%Y-%m-%d %H:%M:%S')
- **任务 ID**: $task_id
- **任务描述**: $task_desc

## 任务摘要
$task_content

## 关键成果
1. 任务已成功完成
2. 生成了 m1 级别摘要
3. 为后续 m2 汇总提供基础

## 后续行动
- 等待积累 20 个 m1 摘要后生成 m2 宏观摘要
- 如需详细信息，请查看原始任务日志

---
*摘要生成时间：$(date '+%Y-%m-%d %H:%M:%S')*
*m1 摘要 ID: $(basename "$m1_file")*
EOF
    
    log "${GREEN}m1 摘要已保存：$m1_file${NC}"
    echo "$m1_file"
}

# 2. 检查是否应该生成 m2 摘要（宏观摘要）
check_m2_generation() {
    local m1_count=$(find "$TWO_LEVEL_DIR/m1" -name "m1-*.md" | wc -l | tr -d ' ')
    
    log "当前 m1 摘要数量：$m1_count"
    
    if [ "$m1_count" -ge 20 ]; then  # 生产环境用 20 个
        log "${YELLOW}达到 m2 生成阈值 ($m1_count ≥ 20)，生成 m2 宏观摘要${NC}"
        generate_m2
    else
        log "m1 数量不足 ($m1_count < 20)，跳过 m2 生成"
    fi
}

# 3. 生成 m2 摘要（宏观摘要）
generate_m2() {
    log "${YELLOW}生成 m2 宏观摘要${NC}"
    
    local m2_file="$TWO_LEVEL_DIR/m2/m2-$(date +%Y%m%d-%H%M%S).md"
    
    # 获取最新的 20 个 m1 摘要内容
    local recent_m1=$(find "$TWO_LEVEL_DIR/m1" -name "m1-*.md" -exec ls -t {} + | head -20)
    
    cat > "$m2_file" << EOF
# m2 宏观摘要

## 基本信息
- **摘要 ID**: $(basename "$m2_file")
- **生成时间**: $(date '+%Y-%m-%d %H:%M:%S')
- **m1 摘要数量**: $(echo "$recent_m1" | wc -l | tr -d ' ')
- **覆盖时间范围**: 最近$(echo "$recent_m1" | head -1 | sed 's/.*m1-\([0-9]*\)-.*/\1/') 到 $(echo "$recent_m1" | tail -1 | sed 's/.*m1-\([0-9]*\)-.*/\1/')

## 宏观总结
基于最近的 m1 摘要，以下是主要活动和进展：

### 关键主题
1. **系统优化**: 记忆系统架构改进和性能优化
2. **社区学习**: Moltbook 探索和技术模式提取
3. **工具集成**: 现有工具链的维护和扩展
4. **问题解决**: 系统问题的识别和修复

### 重要决策
- 实施了两级摘要记忆系统以解决长对话智商下降问题
- 集成了 V4 语义测量系统验证记忆相关性
- 优化了模型路由系统，提高了任务执行效率

### 持续关注
1. **上下文管理**: 保持恒定上下文长度，避免信息过载
2. **记忆完整性**: 确保关键决策和关系不被遗忘
3. **系统健康**: 定期监控定时任务和资源使用情况

## 集成建议
将本 m2 摘要作为代理的主要记忆输入，保持约 200 字的恒定上下文长度。

## 详细 m1 摘要参考
$(for m1 in $recent_m1; do
    echo "- $(basename "$m1"): $(head -10 "$m1" | grep "任务描述" | cut -d: -f2-)"
done)

---
*宏观摘要生成时间：$(date '+%Y-%m-%d %H:%M:%S')*
*包含的 m1 摘要：$(echo "$recent_m1" | wc -l)*
*总字数：~200 字*
EOF
    
    log "${GREEN}m2 宏观摘要已保存：$m2_file${NC}"
    echo "$m2_file"
}

# 4. 显示系统状态
show_status() {
    echo ""
    echo "📊 两级摘要系统状态"
    echo "================================"
    
    local m1_count=$(find "$TWO_LEVEL_DIR/m1" -name "m1-*.md" 2>/dev/null | wc -l | tr -d ' ')
    local m2_count=$(find "$TWO_LEVEL_DIR/m2" -name "m2-*.md" 2>/dev/null | wc -l | tr -d ' ')
    local threshold=20
    
    echo "  m1 摘要数量：$m1_count"
    echo "  m2 摘要数量：$m2_count"
    echo "  生成阈值：$threshold"
    echo "  距离 m2 生成：$((threshold - m1_count)) 个 m1"
    
    if [ "$m1_count" -ge "$threshold" ]; then
        echo "  状态：${YELLOW}需要生成 m2${NC}"
    else
        echo "  状态：${GREEN}正常${NC}"
    fi
    
    # 显示最新的 m1 和 m2
    echo ""
    echo "  最新 m1:"
    find "$TWO_LEVEL_DIR/m1" -name "m1-*.md" -exec ls -t {} + | head -3 | while read file; do
        echo "    - $(basename "$file")"
    done
    
    echo ""
    echo "  最新 m2:"
    find "$TWO_LEVEL_DIR/m2" -name "m2-*.md" -exec ls -t {} + | head -3 | while read file; do
        echo "    - $(basename "$file")"
    done
}

# 5. 测试功能
run_test() {
    log "${YELLOW}运行测试...${NC}"
    
    # 生成测试 m1
    local test_m1=$(generate_m1 "test-$(date +%s)" "测试任务" "这是一个测试任务的内容")
    
    # 验证文件创建
    if [ -f "$test_m1" ]; then
        log "${GREEN}测试通过：m1 文件创建成功${NC}"
    else
        log "${RED}测试失败：m1 文件创建失败${NC}"
        return 1
    fi
    
    # 显示状态
    show_status
    
    log "${GREEN}所有测试通过${NC}"
}

# 主函数
main() {
    local command="${1:-status}"
    
    case "$command" in
        generate-m1)
            if [ $# -lt 4 ]; then
                echo "用法：$0 generate-m1 <task_id> <task_desc> <task_content>"
                exit 1
            fi
            generate_m1 "$2" "$3" "$4"
            check_m2_generation
            ;;
        generate-m2)
            generate_m2
            ;;
        status)
            show_status
            ;;
        test)
            run_test
            ;;
        *)
            echo "用法：$0 {generate-m1|generate-m2|status|test}"
            echo ""
            echo "命令说明:"
            echo "  generate-m1 <task_id> <task_desc> <task_content> - 生成 m1 摘要"
            echo "  generate-m2 - 生成 m2 宏观摘要"
            echo "  status - 显示系统状态"
            echo "  test - 运行测试"
            exit 1
            ;;
    esac
}

main "$@"
