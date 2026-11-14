# Electrik Laravel 13 SaaS — Antigravity & Google ADK 2.0 A2A Starter

基于 **Laravel 13**、**Electrik 5.x** 与 **Electrik Slate 3** 构建的多租户 SaaS 应用工程底座，内置面向 **Google Antigravity 2.0 / CLI (`agy`)** 与 **Laravel Boost** 的 AI 代理工程规范，并通过 **Agent2Agent (A2A)** 协议在 Laravel AI SDK 适配层与 **Google ADK 2.0 (Python)** 多智能体编排服务之间建立租户隔离的双向桥接。

---

## 目录

- [核心架构与设计动机](#核心架构与设计动机)
- [核心技术栈](#核心技术栈)
- [快速开始](#快速开始)
- [常用命令速查表](#常用命令速查表)
- [目录与核心文件结构](#目录与核心文件结构)
- [AI Agent 工程规范与 MCP 工具链](#ai-agent-工程规范与-mcp-工具链)
- [双向 A2A 协议与 Google ADK 2.0 集成](#双向-a2a-协议与-google-adk-20-集成)
- [环境变量参考](#环境变量参考)
- [权威文档与 LLM 索引](#权威文档与-llm-索引)

---

## 核心架构与设计动机

本项目在标准 Laravel 13 骨架之上引入了四个核心工程不变量（由 [`tests/Feature/ArchitectureTest.php`](tests/Feature/ArchitectureTest.php)、[`tests/Feature/ElectrikInstallationTest.php`](tests/Feature/ElectrikInstallationTest.php) 与 [`tests/Feature/AgentHarnessConfigTest.php`](tests/Feature/AgentHarnessConfigTest.php) 持续守卫）：

1. **包封装隔离（`Electrik\` vs `App\`）**
   - 认证（Fortify、2FA、Passkeys、Socialite、Magic Link、登录告警）、团队多租户（`Electrik\Models\Team`）、团队级 RBAC（Spatie Permission）、Stripe Cashier 计费、Onboarding 向导与 `/ops` 运维后台全部封装在 `vendor/electrik/electrik` 中。
   - **禁止**将 Jetstream/Breeze 风格的认证控制器或 `Electrik\` 代码复制到 `App\`；所有壳层定制均通过 [`config/electrik.php`](config/electrik.php) 与 `ELECTRIK_*` 环境变量完成，`App\` 仅存放业务领域代码。
2. **团队即租户边界（`BelongsToTeam` & Team-Scoped Billing）**
   - 租户边界是 `Electrik\Models\Team`（而非 `App\Models\User`），Cashier `Billable` 与按量计量同样绑定在 `Team` 上。
   - 所有新增租户模型与资源通过 `php artisan electrik:make:model` 或 `php artisan electrik:make:resource` 生成（仅全局系统实体使用 `--no-team`）。
3. **Electrik Slate 3 原生 Blade UI 体系**
   - 前端界面采用 [`electrik/slate`](https://slate.electrik.dev/llms.txt) 匿名 Blade 组件（`<x-slate::*>` 与 `<x-slate-block::*>`）、Livewire 4 与 Tailwind CSS v4 令牌（配置于 [`resources/css/app.css`](resources/css/app.css)），不引入 React、Vue、Inertia 或 Flux UI。
4. **Laravel 13 单入口内聚与防漂移（Anti-Drift）**
   - 保持 [`bootstrap/app.php`](bootstrap/app.php) 单入口结构，禁止重建 `app/Http/Kernel.php` / `app/Console/Kernel.php`。
   - 禁止建立 `app/Services/`、`app/Repositories/`、`app/Actions/` 等额外抽象目录；领域逻辑内聚于 Eloquent Models、FormRequests、Policies、Queued Jobs 与 Livewire Components。

---

## 核心技术栈

| 领域 | 组件 / 版本 | 说明 |
| :--- | :--- | :--- |
| **后端框架** | PHP `^8.3`（验证环境 PHP `8.5.12`，遵循 PHP 8.4+ 规范）、Laravel Framework `^13.17`（`13.42.0`） | 严格模式 `declare(strict_types=1);` 与 `bootstrap/app.php` 单入口配置 |
| **SaaS 核心壳层** | `electrik/electrik` `^5.5`（`5.5.0`） | 多租户团队、权限、Stripe Cashier 订阅、Onboarding、`/ops` 管理台 |
| **UI 与前端构建** | `electrik/slate`（`3.0.3`）、Livewire 4、Tailwind CSS v4 (`@tailwindcss/vite` `^4.0.0`)、Vite `^8.0.0` | 原生 Blade 令牌样式与响应式暗黑模式支持 |
| **AI & A2A 桥接** | `bootstrap/laravel_ai_shims.php`（`Laravel\Ai\*` 契约适配）、Google ADK `>=2.0.0`、FastAPI + Uvicorn | 团队隔离的双向 A2A JSON 接口与 ADK `SequentialAgent` 流水线 |
| **测试与代码质量** | Pest `^5.3`（`5.3.5`）、Laravel Pint `^1.27`（`1.32.3`）、Laravel Boost `^2.2`（`2.10.4`）、Playwright `^1.65.0` | 架构测试、A2A 契约测试、安装与沙箱配置守卫、迁移校验脚本 |

---

## 快速开始

### 1. 环境准备

- **PHP `>= 8.3`**（含 `pdo_sqlite` / `mbstring` / `openssl` / `bcmath` 等常用扩展）与 **Composer**
- **Node.js & npm**（用于 Tailwind CSS v4 与 Vite 资源构建）
- **Python `>= 3.11`**（可选，仅在本地联调 `adk_service/` Google ADK 2.0 服务时需要）

### 2. 安装依赖与初始化应用

```bash
# 1. 安装 PHP 与前端依赖
composer install
npm install

# 2. 生成环境变量与应用密钥（如尚未存在 .env）
cp .env.example .env
php artisan key:generate

# 3. 安装 Electrik 5.x 壳层并执行数据库迁移
php artisan electrik:install --migrate

# 4. 构建前端静态资源
npm run build
```

如需体验内置示例数据（示例用户、团队、Studio 示例项目与活动日志），可运行：

```bash
php artisan electrik:seed-demo
```

> **运维后台 `/ops` 权限**：在 `.env` 中设置 `ELECTRIK_OPERATOR_EMAILS="admin@example.com"` 即可授权指定邮箱访问 `/ops`。

### 3. 配置 Stripe 计费（可选）

1. 在 `.env` 中配置 `STRIPE_KEY`、`STRIPE_SECRET`、`STRIPE_WEBHOOK_SECRET`。
2. 同步 Stripe 产品与价格到本地目录：
   ```bash
   php artisan electrik:stripe:sync
   ```
3. 如需修复遗漏的 Webhook 订阅状态，可运行：
   ```bash
   php artisan electrik:stripe:sync-subscriptions
   ```

### 4. 启动本地开发环境与 Python ADK 2.0 服务

```bash
# 启动 Laravel 开发服务集群（composer run dev）
composer run dev
```

如需运行本地 **Google ADK 2.0 A2A 微服务**（默认监听 `http://127.0.0.1:8080`）：

```bash
pip install -r adk_service/requirements.txt
ADK_ENV=local uvicorn adk_service.agent:app --host 127.0.0.1 --port 8080
```

---

## 常用命令速查表

| 场景 | 命令 | 说明 |
| :--- | :--- | :--- |
| **启动开发环境** | `composer run dev` | 调用 `php artisan dev` 启动本地服务 |
| **前端资源构建** | `npm run build` | 构建 Tailwind CSS v4 与 Vite Manifest |
| **生成租户模型** | `php artisan electrik:make:model <Name>` | 自动注入 `BelongsToTeam` 与团队作用域迁移 |
| **生成完整租户资源** | `php artisan electrik:make:resource <Name>` | 生成 Model、Migration、Livewire Index/Show 与 Policy |
| **生成 Slate Livewire 组件** | `php artisan electrik:make:livewire <Name>` | 生成带有 Slate 样式的 Livewire 组件与视图 |
| **同步角色与权限目录** | `php artisan electrik:permissions:sync` | 根据 `config/electrik.php` 同步权限与系统角色 |
| **同步 Stripe 目录** | `php artisan electrik:stripe:sync` | 同步 Stripe Products 与 Plans 到本地数据库 |
| **运行全部 Pest 测试** | `vendor/bin/pest` | 执行所有功能测试与架构测试（共 34 项测试） |
| **按测试文件精细验证** | `vendor/bin/pest tests/Feature/A2aProtocolTest.php` | 单独验证 `ArchitectureTest` / `A2aProtocolTest` / `ElectrikInstallationTest` / `AgentHarnessConfigTest` |
| **验证迁移租户安全** | `python3 .agents/skills/laravel-migration-validator/scripts/validate_migration.py database/migrations` | 检查 `team_id` 约束、外键索引与无破坏性迁移 |
| **运行 Python ADK 测试** | `python3 -m unittest adk_service/test_agent_a2a.py` | 验证 ADK 2.0 Discovery、鉴权、团队隔离与会话执行 |
| **代码风格格式化** | `vendor/bin/pint --dirty --format agent` | 使用 Laravel Pint 格式化已修改的 PHP 文件 |
| **重同步 Agent Kit** | `bash setup_electrik_agent_kit.sh` | 幂等同步 `.ai/rules/`、`.agents/skills/`、`.gemini/settings.json` 与 A2A 骨架（覆盖前请确认本地修改） |

---

## 目录与核心文件结构

```text
.
├── AGENTS.md / CLAUDE.md                 # AI Agent 工程宪法与规范总入口（包含 Laravel Boost 指南）
├── boost.json / .mcp.json                # Laravel Boost 配置与基础 MCP 定义
├── setup_electrik_agent_kit.sh           # Antigravity + Electrik + ADK A2A 工程套件安装脚本
├── .gemini/
│   └── settings.json                     # Antigravity CLI 沙箱模式、状态栏与单调递增权限策略（allow/deny/ask）
├── .agents/
│   ├── bin/statusline.sh                 # Antigravity 状态栏提示脚本（分支 / Sandbox / A2A 状态）
│   ├── mcp_config.json                   # laravel-boost 与 electrik-slate MCP Server 配置
│   └── skills/                           # 项目级可加载 Agent Skills（由 AppServiceProvider 注册）
├── .ai/rules/                            # 按路径作用域生效的架构规则（package boundary / tenancy / slate / controllers）
├── adk_service/
│   ├── agent.py                          # Google ADK 2.0 FastAPI A2A 服务（SequentialAgent 流水线）
│   ├── requirements.txt                  # Python 依赖（google-adk>=2.0.0, fastapi, uvicorn, httpx, pydantic）
│   └── test_agent_a2a.py                 # Python unittest 契约与租户隔离测试
├── app/
│   ├── Ai/
│   │   ├── SkillRegistry.php             # 扫描并加载 .agents/skills/*/SKILL.md 的 Markdown 正文
│   │   ├── Agents/TenantCopilotAgent.php # 租户隔离 Copilot Agent（绑定 RemoteAdkAgentTool）
│   │   └── A2a/
│   │       ├── A2aServerController.php   # Laravel 入站 A2A Discovery 与任务执行控制器
│   │       └── RemoteAdkAgentTool.php    # Laravel 出站调用 Python ADK A2A 服务的 Tool 封装
│   ├── Jobs/RunTenantAdkWorkflowJob.php  # 异步执行 Skill 增强的 ADK 任务并向 Team 上报 Cashier 用量
│   ├── Models/User.php                   # 挂载 Electrik 多租户/RBAC/Passkey/导出 Trait（不含 Billable）
│   └── Providers/AppServiceProvider.php  # 单例绑定 SkillRegistry
├── bootstrap/
│   ├── app.php                           # Laravel 13 单入口配置（加载 routes/a2a.php 与 Electrik 中间件）
│   └── laravel_ai_shims.php              # Laravel\Ai 契约/属性/枚举轻量垫片（保证无外部 AI SDK 时完整类型契约）
├── config/
│   ├── electrik.php                      # Electrik 品牌、认证、Onboarding、团队、权限、API Token、计费配置
│   └── services.php                      # ADK A2A 端点与密钥配置（services.adk.*）
├── routes/
│   ├── web.php                           # 应用产品路由（Auth/Billing/Teams/Ops 路由由 vendor/electrik/electrik 提供）
│   └── a2a.php                           # A2A Agent Card 与任务接收路由
└── tests/Feature/
    ├── ArchitectureTest.php              # Pest Architecture 规则（strict_types、禁止 App\Services 等漂移层）
    ├── AgentHarnessConfigTest.php        # .gemini/settings.json、MCP、AGENTS.md、.ai/rules 一致性测试
    ├── A2aProtocolTest.php               # 双向 A2A 鉴权、team_id 校验、RemoteAdkAgentTool 与 Job 测试
    └── ElectrikInstallationTest.php      # Electrik 5.x 安装、配置、Trait 与 vendor 路由边界测试
```

---

## AI Agent 工程规范与 MCP 工具链

仓库内建完整的 AI 辅助研发基础设施，保证多代理或长会话迭代时不发生架构漂移：

- **Antigravity CLI 沙箱与权限门禁（[`.gemini/settings.json`](.gemini/settings.json)）**
  - 默认开启 `enableTerminalSandbox: true` 与 `agentMode: "accept-edits"`。
  - **显式禁止（`deny`）**写入 `.env*`、`.git/`、`vendor/`、`composer.json`、`package.json`、`bootstrap/app.php`、`app/Http/Kernel.php`、`app/Console/Kernel.php` 以及 `app/Services/`、`app/Repositories/`、`app/Actions/`。
  - **敏感确认（`ask`）**涵盖 `mcp(laravel-boost/tinker)`、`php artisan migrate`、`electrik:install`、`electrik:stripe:sync`、`composer require/update`、`npm install/build` 与 `config/` 修改。
- **MCP Servers（[`.agents/mcp_config.json`](.agents/mcp_config.json)）**
  - `laravel-boost`（`php artisan boost:mcp`）：提供数据库 Schema 查询、只读 SQL、`search-docs` 等应用上下文工具。
  - `electrik-slate`（`npx -y @electrik/slate-mcp`）：查询 Electrik Slate 3 组件文档、区块（Blocks）与源码。
- **路径作用域规则（[`.ai/rules/`](.ai/rules/index.md)）**
  - `electrik-package-boundary.md`（`config/**`, `routes/**`, `app/Providers/**`）
  - `team-tenancy-models.md`（`app/Models/**`, `database/migrations/**`）
  - `slate-livewire-views.md`（`resources/views/**`, `app/Livewire/**`）
  - `controllers-and-requests.md`（`app/Http/**`）
- **可编程工作流 Skills（`.agents/skills/`）**
  - Electrik & A2A 专属 Skills：`adk-a2a-bridge`、`electrik-cashier-billing`、`electrik-tenant-scaffold`、`laravel-migration-validator`、`laravel-pest-verify`、`laravel-pint-fix`、`slate-blade-ui`。
  - Laravel Boost Skills：`infer-conventions`、`laravel-best-practices`、`socialite-development`、`tailwindcss-development`、`testing-best-practices`。
  - 以上 Skill 文件由 [`AppServiceProvider`](app/Providers/AppServiceProvider.php) 自动注册进 [`SkillRegistry`](app/Ai/SkillRegistry.php)，供 Laravel 与 ADK 智能体按需加载执行指令。

---

## 双向 A2A 协议与 Google ADK 2.0 集成

本应用实现了覆盖 **发现 -> 鉴权 -> 团队上下文校对 -> 任务执行 -> 用量上报** 的双向 A2A 闭环：

### 1. 入站方向：外部 Agent -> Laravel（[`routes/a2a.php`](routes/a2a.php) & [`A2aServerController`](app/Ai/A2a/A2aServerController.php)）

- **Agent Discovery**：`GET /.well-known/agent.json`（路由名 `a2a.agent-card`），返回符合 `https://a2a-protocol.org/schemas/v1/agent.json` 的能力卡片（`tenant-query`、`cashier-billing-status`）。
- **任务执行端点**：`POST /api/a2a/tasks/send`（路由名 `a2a.tasks.send`）：
  1. **密钥校验（Fail-Closed）**：比对 `X-A2A-Api-Key` 与 `config('services.adk.server_api_key')`；在非 `local`/`testing` 环境未配置密钥时直接返回 HTTP `503`（`A2A_AUTH_NOT_CONFIGURED`），密钥不匹配返回 HTTP `401`。
  2. **严格租户校验**：解析正整数 `X-Electrik-Team-Id` 请求头与 `metadata.team_id`，拒绝非正整数或布尔伪造（HTTP `422` `MISSING_TENANT_CONTEXT`），并在两者冲突时返回 `TENANT_CONTEXT_MISMATCH`。当 `teams` 表存在时校验团队存在性（不存在返回 HTTP `404`）。
  3. **代理执行**：通过 `SkillRegistry` 加载请求指定的 Skill（默认 `adk-a2a-bridge`），实例化 [`TenantCopilotAgent`](app/Ai/Agents/TenantCopilotAgent.php) 并返回标准 A2A `completed` 响应体。

### 2. 出站方向：Laravel -> Python Google ADK 2.0（[`RemoteAdkAgentTool`](app/Ai/A2a/RemoteAdkAgentTool.php) & [`RunTenantAdkWorkflowJob`](app/Jobs/RunTenantAdkWorkflowJob.php)）

- **同步工具委派**：`TenantCopilotAgent` 暴露 `RemoteAdkAgentTool`，自动附带 `X-Electrik-Team-Id`、`X-A2A-Api-Key` 与 `metadata.team_id` 请求 ADK 端点（默认 `http://127.0.0.1:8080/a2a/tasks/send`）。
- **异步队列编排与计量计费**：`RunTenantAdkWorkflowJob` 将本地 Skill Markdown 指令注入任务 Prompt 后发往 ADK；任务完成后读取响应中的 `metadata.usage.total_tokens`，在 `teams` 表存在且团队具备 Stripe ID 时，调用 `$team->reportMeterEvent('ai_workflow_tokens', quantity: $totalTokens)`（或回退到 Cashier 用量上报）。
- **Python ADK 2.0 编排流水线（[`adk_service/agent.py`](adk_service/agent.py)）**：
  - 提供 `GET /.well-known/agent.json`（`adk-electrik-orchestrator`）与 `POST /a2a/tasks/send`。
  - 实施与 Laravel 侧对等的 `X-A2A-Api-Key` Fail-Closed 鉴权及 `X-Electrik-Team-Id` / `metadata.team_id` 一致性校验。
  - 使用 `google.adk.agents.SequentialAgent`（`electrik_saas_orchestrator`）串联 `electrik_triage_agent`（`output_key="triage_plan"`）与 `electrik_synthesis_agent`（`output_key="final_output"`），并以 `user_id = f"team-{team_id}"` 隔离 `InMemorySessionService` 会话状态。

---

## 环境变量参考

除标准 Laravel（`APP_*`、`DB_*`、`QUEUE_CONNECTION`）与 Stripe Cashier（`STRIPE_KEY`、`STRIPE_SECRET`、`STRIPE_WEBHOOK_SECRET`）变量外，常用扩展配置如下：

| 变量名 | 默认值 | 用途 |
| :--- | :--- | :--- |
| `ELECTRIK_NAME` | `'Electrik'` | 应用与白标显示名称（[`config/electrik.php`](config/electrik.php)） |
| `ELECTRIK_OPERATOR_EMAILS` | `''` | 逗号分隔的 `/ops` 运维台访问邮箱列表 |
| `ELECTRIK_SOCIALITE_PROVIDERS` | `'google,github'` | 启用的 OAuth 登录提供商列表 |
| `ELECTRIK_REQUIRE_SUBSCRIPTION` | `false` | 是否强制要求团队有效订阅方可访问受保护区 |
| `ELECTRIK_SAMPLE_PROJECTS` | `true` | 是否启用内置 Studio（Clients/Projects/Tasks）示例模块 |
| `ADK_A2A_ENDPOINT` | `'http://127.0.0.1:8080/a2a/tasks/send'` | Laravel 出站调用 Python ADK A2A 的目标 URL（[`config/services.php`](config/services.php)） |
| `ADK_A2A_API_KEY` | `''` | Laravel 调用 ADK 与 Python ADK 校验入站请求的共享 API Key |
| `A2A_SERVER_API_KEY` | `''` | Laravel 入站端点 `/api/a2a/tasks/send` 校验 `X-A2A-Api-Key` 的密钥 |
| `ADK_ENV` | `'production'` | Python ADK 运行环境（非 `local`/`development`/`testing` 时强制校验 `ADK_A2A_API_KEY`） |
| `ADK_GEMINI_MODEL` | `'gemini-2.5-flash'` | Python ADK 2.0 `LlmAgent` 使用的 Gemini 模型名称 |
| `LARAVEL_A2A_ENDPOINT` | `'http://127.0.0.1:8000/api/a2a/tasks/send'` | ADK 服务反向回调 Laravel A2A 端点的地址 |

---

## 权威文档与 LLM 索引

在进行路由规划、Slate 组件开发、Cashier 计费或 ADK 集成前，建议优先查阅以下机器可读索引与官方文档：

- **Electrik Core Index**: https://electrik.dev/llms.txt
- **Electrik Full Reference**: https://electrik.dev/llms-full.txt
- **Electrik AI & Agents Guide**: https://electrik.dev/docs/getting-started/ai
- **Electrik Slate 3 UI Index**: https://slate.electrik.dev/llms.txt
- **Electrik Slate 3 Full Dump**: https://slate.electrik.dev/llms-full.txt
- **Electrik Slate MCP Guide**: https://slate.electrik.dev/docs/ai
- **Google ADK 2.0 Guide**: https://adk.dev/2.0/
- **Agent2Agent (A2A) Protocol**: https://github.com/google-a2a/a2a-python

---

## 许可证

本项目遵循 [MIT License](https://opensource.org/licenses/MIT) 开源许可。
