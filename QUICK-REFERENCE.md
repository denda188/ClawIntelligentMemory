# 智能记忆系统 3.3 - 快速参考

**版本**: v3.3  
**更新**: 2026-03-13  
**维护者**: Denda 🦞

---

## 🚀 快速启动

### 查看系统状态
```bash
# 定时任务状态
openclaw cron list

# QMD 搜索状态
qmd status

# 记忆健康
./para-system/memory-health-dashboard.sh

# 两级摘要状态
./two-level-memory/scripts/enhanced-monitor.sh
```

### 手动运行维护
```bash
# 记忆系统维护 (每 6 小时)
./docs/Scripts/memory-maintenance-combined.sh

# QMD 完整维护 (每天 06:00)
./docs/Scripts/qmd-full-maintenance.sh

# 夜间深度分析 (每天 03:00)
./docs/Scripts/nightly-deep-analysis.sh

# 预压缩钩子检查 (每 2 小时)
./docs/Scripts/pre-compression-hook-optimized.sh
```

---

## 📝 两级摘要使用

### 生成任务摘要
```bash
# 任务完成后生成 m1
./docs/Scripts/two-level-memory-integration.sh \
  generate-m1 "task-123" \
  "优化记忆系统" \
  "实施了两级摘要，上下文从 67% 降至 15%"

# 查看系统状态
./docs/Scripts/two-level-memory-integration.sh status

# 手动生成 m2
./docs/Scripts/two-level-memory-integration.sh generate-m2

# 运行测试
./docs/Scripts/two-level-memory-integration.sh test
```

### 监控摘要系统
```bash
# 完整监控 (每 4 小时)
./docs/Scripts/enhanced-monitor.sh

# 查看监控日志
tail -f path../Space/two-level-memory/logs/enhanced-monitor-*.log
```

---

## 🔍 搜索记忆

### QMD 搜索命令
```bash
# 全文搜索
qmd search "关键词" -n 10

# 向量搜索
qmd search "概念描述" --vector -n 10

# 混合搜索
qmd search "关键词" --hybrid -n 10

# 限定集合
qmd search "记忆" --collection memory -n 5
```

### 搜索技巧
- 使用具体关键词，避免模糊词
- 向量搜索适合概念查询
- 混合搜索最全面 (但较慢)
- 限制结果数量提高速度

---

## ⚙️ 定时任务配置

### 查看任务
```bash
# 所有任务
openclaw cron list

# 搜索特定任务
openclaw cron list | grep -i "记忆"
```

### 关键任务
| 任务名称 | 频率 | 说明 |
|---------|------|------|
| 记忆系统维护 | 每 6 小时 | 衰减更新 + 检查点 |
| QMD 综合维护 | 每天 06:00 | 索引更新 + 向量嵌入 |
| 夜间深度分析 | 每天 03:00 | LLM 分析 + 战略建议 |
| 预压缩钩子 | 每 2 小时 | 上下文监控 + 紧急保存 |
| 两级摘要监控 | 每 4 小时 | m1/m2 监控 + 自动生成 |
| Moltbook 检测 | 每 8 小时 | 资源感知社区参与 |

### 手动触发任务
```bash
# 运行特定任务
openclaw cron run --name "记忆系统维护 (合并版)"

# 查看任务历史
openclaw cron runs --name "QMD 综合维护"
```

---

## 🛠️ 故障排除

### 常见问题速查

#### 定时任务未执行
```bash
# 检查服务
openclaw status

# 检查 cron
openclaw cron status

# 手动测试
openclaw cron run --name "任务名称"

# 查看日志
tail -50 path../Space/para-system/logs/*.log
```

#### QMD 搜索无结果
```bash
# 重建索引
qmd collection rm life memory workspace
qmd collection add life --name life --mask "**/*.md"
qmd collection add memory --name memory --mask "**/*.md"
qmd collection add workspace --name workspace --mask "**/*.md"

# 重新嵌入
qmd embed

# 测试搜索
qmd search "测试" -n 5
```

#### 上下文使用率过高
```bash
# 立即执行预压缩
./docs/Scripts/pre-compression-hook-optimized.sh

# 手动紧急保存
cp MEMORY.md .cache/memory-system/emergency/emergency-$(date +%Y%m%d-%H%M%S).md

# 查看使用率
openclaw status --json | jq '.sessions.recent[] | {key, percentUsed}'
```

#### 两级摘要未生成
```bash
# 检查 m1 数量
ls -1 two-level-memory/m1/*.md | wc -l

# 检查阈值
cat two-level-memory/dynamic-threshold-config.json

# 手动生成 m2
./docs/Scripts/two-level-memory-integration.sh generate-m2
```

---

## 📊 性能指标

### 目标值
| 指标 | 目标 | 检查命令 |
|------|------|---------|
| MEMORY.md 大小 | < 3000 字符 | `wc -c MEMORY.md` |
| 上下文使用率 | < 20% | `openclaw status` |
| 定时任务正常 | 100% | `openclaw cron list` |
| QMD 搜索时间 | < 3 秒 | `time qmd search "测试"` |
| m1 积累阈值 | 20 个 | `ls m1/*.md \| wc -l` |

### 健康检查清单
- [ ] MEMORY.md < 3000 字符
- [ ] 所有定时任务正常
- [ ] QMD 搜索正常
- [ ] 上下文使用率 < 60%
- [ ] m1/m2 正常生成
- [ ] 日志文件正常增长

---

## 📁 文件结构

```
path../Space/
├── docs/
│   ├── memory-system-sharing.md    # 完整实施指南
│   └── Scripts/                     # 关键脚本
│       ├── memory-maintenance-combined.sh
│       ├── two-level-memory-integration.sh
│       ├── qmd-full-maintenance.sh
│       ├── nightly-deep-analysis.sh
│       ├── pre-compression-hook-optimized.sh
│       └── enhanced-monitor.sh
├── memory/                          # 每日记忆日志
│   └── YYYY-MM-DD.md
├── two-level-memory/                # 两级摘要
│   ├── m1/                          # 任务级摘要
│   ├── m2/                          # 宏观摘要
│   └── logs/                        # 日志
├── para-system/                     # 系统脚本
│   ├── scripts/
│   ├── maintenance/
│   └── config/
└── life/                            # PARA 结构
    ├── projects/
    ├── areas/
    ├── resources/
    └── archives/
```

---

## 🔑 关键配置

### 记忆类型衰减率
```json
{
  "决策": { "decay_rate": -0.3, "archive_days": null },
  "偏好": { "decay_rate": -0.2, "archive_days": null },
  "关系": { "decay_rate": -0.1, "archive_days": null },
  "技能": { "decay_rate": 0.5, "archive_days": 180 },
  "事件": { "decay_rate": 0.7, "archive_days": 90 },
  "事实": { "decay_rate": 0.8, "archive_days": 30 },
  "上下文": { "decay_rate": 0.9, "archive_days": 7 }
}
```

### 两级摘要配置
```json
{
  "m1_threshold": 20,
  "m1_max_words": 150,
  "m2_max_words": 200,
  "auto_generate": true
}
```

### 预压缩阈值
```bash
WARNING_THRESHOLD=60    # 警告线
CRITICAL_THRESHOLD=75   # 紧急线
COOLDOWN_MINUTES=60     # 冷却时间
```

---

## 📞 获取帮助

### 查看文档
- 完整指南：`path../Space/docs/memory-system-sharing.md`
- 快速参考：`path../Space/docs/QUICK-REFERENCE.md`
- HEARTBEAT.md: `path../Space/HEARTBEAT.md`

### 查看日志
```bash
# 最新日志
tail -50 path../Space/para-system/logs/*.log

# 实时日志
tail -f path../Space/para-system/logs/*.log
```

---

**最后更新**: 2026-03-13  
**系统状态**: ✅ 所有系统正常运行  
**维护者**: Denda 🦞
