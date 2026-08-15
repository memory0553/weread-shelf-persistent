# 微信读书书架（持久化版）安装说明

## 安装

1. 解压安装包，得到 `weread-shelf-persistent` 文件夹。
2. 打开你的 Obsidian 仓库目录。
3. 将整个文件夹复制到：

   ```text
   <你的仓库>/.obsidian/plugins/
   ```

4. 确认文件路径如下：

   ```text
   <你的仓库>/.obsidian/plugins/weread-shelf-persistent/main.js
   <你的仓库>/.obsidian/plugins/weread-shelf-persistent/manifest.json
   ```

5. 打开 Obsidian，进入“设置 → 第三方插件”。
6. 如果插件列表中暂时没有出现，点击刷新或重启 Obsidian。
7. 启用“微信读书书架（持久化版）”。
8. 打开插件设置，配置微信读书 API Key。

## 更新

1. 先在 Obsidian 中停用插件。
2. 用新安装包中的 `main.js`、`manifest.json`、`style.css` 和 `themes`
   覆盖旧文件。
3. 不要删除已有的 `data.json` 和 `bookshelf-cache.json`，否则插件设置或
   书架缓存会丢失。
4. 重新启用插件。

## 注意事项

- 本插件是非官方分支。
- 桌面端可以扫码获取 API Key；移动端需要手动粘贴 API Key。
- 请勿把包含 API Key 或 Cookie 的 `data.json` 发送给其他人。
- 安装或更新前建议备份 Obsidian 仓库。
