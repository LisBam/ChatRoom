# ChatRoom

本项目包含 Godot 聊天客户端、`Scripts/python_server.py` 中的 Flask 数据接口，以及 `MySQL/` 中的空数据库初始化脚本。游戏场景、客户端脚本和资源仍通过 `project.godot` 打开。

## 本机凭据配置

真实凭据通过启动进程的操作系统环境变量提供，不写入源码、场景或共享配置。

| 环境变量 | 使用方 | 使用条件 |
| --- | --- | --- |
| `CHATROOM_SILICONFLOW_API_KEY` | `Scripts/AIChat.gd` 的 `cloud_api_key` | 云端 AI 模式需要；本地 Ollama 模式不需要 |
| `CHATROOM_DB_PASSWORD` | `Scripts/python_server.py` 的 `DB_CONFIG['password']` | Flask 数据接口连接 MySQL 时需要 |

云端模式保留现有 SiliconFlow 地址和模型配置；本地模式保留现有 Ollama 地址和模型配置。缺少云端密钥时，客户端通过 `ai_error` 信号提示配置问题，并返回 `ERR_UNCONFIGURED`，不会发送云端 HTTP 请求。缺少数据库密码时，`get_db_connection()` 打印缺失的环境变量名并返回 `None`，不会尝试连接 MySQL；现有数据接口继续沿用原来的连接失败处理方式。

PowerShell 中可以分别为后端、客户端设置环境变量，再从相同终端启动程序。下列值都是占位说明，应在本机替换为新凭据：

```powershell
# 后端终端
$env:CHATROOM_DB_PASSWORD = "在本机填写新的数据库密码"
python .\Scripts\python_server.py
```

```powershell
# 客户端终端；Godot 可执行文件路径按本机安装位置替换
$env:CHATROOM_SILICONFLOW_API_KEY = "在本机填写新的云端密钥"
& "C:\path\to\Godot_console.exe" --editor --path .
```

环境变量由新启动的进程继承。修改配置后，需要重新启动对应的 Python 服务或 Godot 编辑器；直接从桌面打开的已有 Godot 进程不会获得另一个 PowerShell 进程中刚设置的环境变量。数据库的主机、用户名和库名仍由现有 `DB_CONFIG` 配置，默认分别为 `127.0.0.1`、`lisbam` 和 `chat_room`。

`cloud_api_key` 允许在检查器中为本机调试覆盖，但保存场景会将覆盖值序列化到场景文件中。真实密钥优先使用环境变量，不应随 `.tscn`、`.tres` 或导出包共享。

`.env.example` 只列出配置名称，不含可用凭据。当前代码读取操作系统环境，**不会自动加载 `.env` 或 `.env.example`**；复制或填写这些文件本身不会完成配置。真实 `.env` 仅供本地使用，应由忽略规则排除，不能提交。

## 初始化空数据库

后端依赖 Flask 和 `mysql-connector-python`，并需要可连接的 MySQL 服务。使用本机管理账号在项目根目录启动 MySQL 客户端：

```text
mysql -u root -p
```

在 MySQL 客户端中执行：

```sql
SOURCE MySQL/setup.sql;
USE chat_room;
SOURCE MySQL/schema.sql;
```

`setup.sql` 创建 `chat_room` 数据库，`schema.sql` 建立 `Users` 与 `Messages` 表，不导入真实用户或聊天记录。为 `DB_CONFIG` 指定的本机数据库账号授予相应访问权限，并确保该账号的新密码与 `CHATROOM_DB_PASSWORD` 一致。已有数据库应先按本机数据库维护流程备份，再判断是否需要执行建表脚本，避免重复建表。

真实用户、聊天记录及整库备份不属于项目源码，不通过仓库分发；部署或开发只依赖上述空库结构脚本。

## 从旧版本迁移

1. 撤销已在旧版本源码中公开的云端 API 密钥，并创建新密钥。
2. 更换曾在源码或备份中出现的 MySQL 密码。
3. 将新凭据设置到对应进程的操作系统环境变量，再重新启动程序。
4. 保留本机所需数据备份，但不将真实数据库导出、环境文件或含密钥的场景重新提交。

清理 Git 历史不能使已公开的旧凭据失效；凭据撤销和密码更换需要分别在对应服务中完成。
