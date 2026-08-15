# 微信读书书架（持久化版）

一个非官方的 Obsidian 微信读书插件分支，基于
[zhaohongxuan/obsidian-weread-plugin](https://github.com/zhaohongxuan/obsidian-weread-plugin)
2.2.0 修改。

这个版本主要解决书架数据源不准确的问题：书架页面以微信读书 Agent API
`/shelf/sync` 返回的当前真实书架为准，并将最近一次成功结果缓存在本地。

插件 ID 为 `weread-shelf-persistent`，可与官方插件区分，避免被官方插件更新覆盖。

## 当前版本

- 插件版本：`1.0.0`
- 最低 Obsidian 版本：`0.14.0`
- 许可证：MIT
- 状态：非官方分支，未提交到 Obsidian 社区插件市场

## 与上游版本的核心差异

| 数据或行为 | 当前实现 |
| --- | --- |
| 书架列表 | 使用 `/shelf/sync`，展示微信读书当前真实书架 |
| 笔记概览 | 使用 `/user/notebooks` 获取划线数和想法数，不再将它当作书架 |
| 笔记同步范围 | 仅同步“当前书架中，并且存在划线或想法”的书 |
| 书架缓存 | 最近一次成功书架保存到插件目录下的 `bookshelf-cache.json` |
| 接口失败 | 优先显示上次成功缓存；没有缓存时提示获取失败 |
| 已移出书架的书 | 不在书架页展示，也不再继续同步，但不会自动删除已经生成的 Markdown 笔记 |

同步候选集合可以简化为：

```text
当前真实书架 ∩ 有划线或想法的书 ∩ 当前同步设置允许的书
```

在此基础上，插件仍会应用公众号开关、最低划线数量、黑名单或白名单等设置。

## 主要功能

- 浏览微信读书当前真实书架。
- 搜索、筛选和排序书架，并查看阅读进度。
- 同步书籍元数据、划线、想法和书评到 Markdown。
- 强制同步指定范围内的笔记。
- 打开书籍详情、微信读书网页和阅读统计视图。
- 使用内置 Nunjucks 模板生成笔记。
- 配置黑名单、白名单、最低划线数量和定时同步。
- 在 API 暂时不可用时读取持久化书架缓存。

## 认证说明

真实书架功能需要微信读书 Agent API Key，格式为 `wrk-...`。

- 桌面端可以在插件设置中点击“扫码获取”。
- 移动端需要手动申请并粘贴 API Key。
- Cookie 不是获取真实书架的必要条件，但部分旧版接口和公众号内容仍依赖 Cookie。
- 只有 Cookie、没有 API Key 时，插件无法调用 `/shelf/sync` 获取真实书架。

请勿把 API Key、Cookie 或 Obsidian 插件的 `data.json` 上传到公开仓库。

## 从源码安装

当前仓库没有发布可直接下载的 Release，需要从源码构建。

### 从安装包安装

如果你拿到的是 `weread-shelf-persistent-1.0.0.zip`：

1. 解压压缩包，得到 `weread-shelf-persistent` 文件夹。
2. 将整个文件夹复制到 `<你的仓库>/.obsidian/plugins/`。
3. 确认最终路径中存在
   `.obsidian/plugins/weread-shelf-persistent/main.js`。
4. 在 Obsidian 的“设置 → 第三方插件”中刷新并启用插件。
5. 打开插件设置，配置微信读书 API Key。

安装包使用者不需要安装 Node.js，也不需要执行构建命令。

### 1. 安装依赖并构建

```bash
npm ci
npm run build
```

构建会执行 Svelte 检查、ESLint 和 webpack。产物位于 `dist/`：

```text
dist/
├── main.js
├── manifest.json
├── style.css
└── themes/
```

### 2. 安装到 Obsidian

在你的仓库中创建插件目录：

```text
<你的仓库>/.obsidian/plugins/weread-shelf-persistent/
```

将 `dist/` 中的全部文件和目录复制进去，然后在 Obsidian 中执行：

1. 打开“设置 → 第三方插件”。
2. 关闭安全模式（如果尚未关闭）。
3. 刷新已安装插件列表。
4. 启用“微信读书书架（持久化版）”。

如果同时安装了官方插件，请确认启用的是 ID 为 `weread-shelf-persistent` 的版本。

## 使用方法

1. 打开插件设置，配置微信读书 API Key；桌面端也可以扫码登录。
2. 点击左侧书本图标，或在命令面板运行“打开微信读书书架”。
3. 确认书架内容后，运行“同步微信读书笔记”。
4. 如需在本地划线/想法数量未变化时仍重新生成笔记，运行“强制同步微信读书笔记”。

可用命令包括：

- 同步微信读书笔记
- 强制同步微信读书笔记
- 打开微信读书书架
- 在新标签页打开微信读书
- 在新窗口打开微信读书
- 同步阅读统计数据

## 数据与缓存

插件会在本地保存以下数据：

| 路径 | 内容 |
| --- | --- |
| `.obsidian/plugins/weread-shelf-persistent/data.json` | 插件设置、认证信息及同步配置 |
| `.obsidian/plugins/weread-shelf-persistent/bookshelf-cache.json` | 最近一次成功获取的真实书架 |
| `.weread-cache/` | 热门划线和阅读统计等缓存 |
| 你在设置中选择的笔记目录 | 生成的微信读书 Markdown 笔记 |

书架缓存只是接口异常时的回退数据。重新成功获取 `/shelf/sync` 后，缓存会被最新书架覆盖。

## 同步边界

- 书架中没有划线或想法的书会显示在书架页，但不会生成笔记。
- `/user/notebooks` 中存在、但已不在 `/shelf/sync` 书架中的书不会继续同步。
- 插件不会自动删除已经生成的旧笔记，避免误删用户文件；如需删除，请先自行确认文件内容。
- 常规同步会跳过内容未发生变化的本地笔记；强制同步会重新生成符合当前同步范围的笔记。
- 同步生成的笔记采用覆盖式更新，不建议直接在同步区域内编辑长期内容。

## 开发

```bash
npm ci
npm run build
```

生成可分发安装包：

```powershell
npm run package:plugin
```

压缩包会生成到 `release/weread-shelf-persistent-<版本号>.zip`。该目录已被
Git 忽略，安装包应通过 GitHub Release、网盘或其他文件传输方式单独分发。

主要代码位置：

```text
main.ts                    插件入口和命令注册
src/api-v2.ts              微信读书 Agent API
src/api-router.ts          V1/V2 接口路由
src/shelfRepository.ts     真实书架读取和持久化缓存
src/bookshelf.ts           书架数据组装
src/syncNotebooks.ts       笔记同步流程
src/syncFilter.ts          黑白名单及同步过滤规则
src/components/            Obsidian 视图和设置界面
src/themes/                Nunjucks 笔记模板
```

## 上游项目与许可证

本项目是在
[Obsidian Weread Plugin](https://github.com/zhaohongxuan/obsidian-weread-plugin)
基础上修改的非官方分支，保留原项目的 MIT License 和版权声明。

MIT License 允许使用、修改、分发和商业使用，但发布衍生版本时必须保留许可证和原版权声明。

## 免责声明

本项目与微信读书、腾讯及上游插件作者不存在官方隶属关系。接口行为可能随微信读书服务调整而变化，请自行保管账号认证信息并在使用前备份 Obsidian 仓库。
