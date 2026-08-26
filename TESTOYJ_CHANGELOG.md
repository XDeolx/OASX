# testoyj 更新日志

本文件只记录 `zHydeol/OASX` 的 `testoyj` 分支改动，独立于上游 `CHANGELOG.md`、README 和许可证。

当前版本：`testoyj-v0.3.12.1`

## 2026-08-26

### 周计划页面

- 在配置工作区新增独立的“周计划”标签页。
- 支持添加、编辑和删除任务计划，并可按全部、周一至周日筛选查看。
- 支持启用或停用周计划，并显示 OAS 服务端当前时间、本周周一和今日最后同步时间。
- 每条计划同时显示星期、时间和按当前周换算后的实际日期，避免复制计划后日期与星期不一致。
- 支持将某一天的整套计划复制到另一天，复制后按照目标星期重新计算实际日期。
- 支持从当前主调度器整体导入已启用任务，可选择先清空现有周计划条目。
- “从当前调度器导入”只复制数据到周计划，不会清空或停用 OAS 主调度器。
- 支持“补跑今日已过计划”选项，以及“立即同步今日计划”操作。
- 新增计划内和未计划任务列表，便于检查哪些任务受周计划管理。

### 界面修复

- 修复周计划条目区域在窄窗口和较长状态文本下的横向溢出。
- 限制状态标签宽度并优化日期布局，改善 Windows 桌面端显示。
- 修复周计划相关组件测试和静态分析问题。

### Windows 构建

- 新增 `testoyj` 分支专用的 Windows GitHub Actions 构建流程。
- 构建流程执行 Flutter 分析、测试和 Windows 打包，并上传测试构建产物。
- `testoyj-v*` 版本标签会创建 GitHub Release，并附带带版本号的 Windows ZIP 安装包。
- `testoyj` 不部署独立 Web 版本，README 中的 Web 链接仅指向上游在线版。
- 优化 Actions 错误输出，使分析或测试失败时能够直接看到有效诊断。

### 兼容说明

- 周计划功能需要配套使用 `zHydeol/OnmyojiAutoScript` 的 `testoyj` 分支；仅更新 OASX 无法获得后端周计划接口。
- 周计划启用后由 OAS 每日自动同步，不需要每天重新执行“从当前调度器导入”。
- 默认同步行为不会清空主调度器；任务执行后的成功间隔和失败重试继续由 OAS 调度器维护。
- OASX 构建包不包含本机的 OAS 账号配置文件。

## 分支基线

- 上游仓库：<https://github.com/AzurTian/OASX>
- 分支仓库：<https://github.com/zHydeol/OASX/tree/testoyj>
- 本轮改动基于上游 OASX `v0.3.12`（提交 `035aece`）。
- 配套 OAS 更新日志：<https://github.com/zHydeol/OnmyojiAutoScript/blob/testoyj/TESTOYJ_CHANGELOG.md>
