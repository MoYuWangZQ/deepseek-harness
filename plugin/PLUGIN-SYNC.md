# 插件跨设备同步

git clone **不会自动安装插件**(git 不执行代码)。仓库提供幂等脚本把“装插件”变成一条命令:

每台新设备:

1. `git clone git@github.com:MoYuWangZQ/dsp.git && cd dsp`
2. 运行 `plugin\setup-dsh-plugins.cmd`(可重复执行)
3. 重启 `dsh web` 生效

当前插件清单(**自动维护**:在插件市场安装/卸载后运行 `plugin\sync-plugin-docs.cmd` 即可重写下面清单与 `setup-dsh-plugins.cmd` 的 `PLUGINS` 行,请勿手改清单):

<!-- PLUGIN-LIST-START -->
- `dsh-plugin` — 应用内插件市场
- `dsh-ui-appearance` — 个性化外观(背景/毛玻璃/主题色)
- `dsh-whale-widget`
<!-- PLUGIN-LIST-END -->

> 注:`dsh-base` / `dsh-web-app` 是模板自带层,`dsh-token-stats` 由平台自动插入,均无需手动安装。

## 维护约定

- **在市场(或命令行)安装/卸载任意插件后,运行一次 `plugin\sync-plugin-docs.cmd`**,它会自动重写 `setup-dsh-plugins.cmd` 的 `PLUGINS` 行与本页清单(以 `%DSH_HOME%\profiles\web\package.json` 的 dependencies 为准,幂等);再把改动 git 提交推送,其他设备 clone 后运行 `plugin\setup-dsh-plugins.cmd` 即复现同一套插件;
- 插件本体来自 npm 仓库,装机即可复现;但**壁纸图片与配色设置存在各设备本地**(浏览器/`%DSH_HOME%`),需手动同步:配色用插件内「导出/导入 JSON」,图片各设备分别上传或共用同一 URL;
- 想彻底卸载某插件:`dsh plugin --profile web remove <包名>`(或市场里卸载),重启后生效。
