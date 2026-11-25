# dufs 文件共享（Ubuntu 服务器，仅 tailnet 可见）

## 1. 解决的痛点

服务器上 Claude 会话生成的 HTML 报告/方案页面，原先要用 Transmit 拷回 Mac 再打开——现在统一写进 `~/public`，Mac 浏览器打开 `http://ubuntu.tail28c408.ts.net:5000` 即可浏览/搜索/拖拽上传/整目录打包下载，替代双向手工拷文件

配套约定：`claude/CLAUDE.md`「禁止 Artifact 发布」一节规定 Claude 会话把页面类产物写入 `~/public` 并给出访问链接

## 2. 组成

1. **二进制**：从 [sigoden/dufs releases](https://github.com/sigoden/dufs/releases) 下载 musl 静态版放 `~/.local/bin/dufs`（一次性手动安装，`install.sh` 只负责链接与启用服务；检测到二进制存在才会启用）
2. **服务单元**：`dufs/dufs.service`（systemd 用户级），`install.sh` 把它链到 `~/.config/systemd/user/`，并自动 daemon-reload + enable + `loginctl enable-linger`（重启后无需登录即自启）
3. **绑定地址**：启动时 `$(tailscale ip -4)` 动态取 Tailscale 虚拟网卡 IP——只在 tailnet 内可见，局域网不可达；IP 万一变化，`Restart=on-failure` 自愈，无需改配置

## 3. 代理注意事项

系统代理（clash 等）会把 `*.ts.net` 域名劫持走代理转发导致 502，两种解法：

1. 把 `*.ts.net` 与 `100.64.0.0/10` 加进代理 bypass
2. 直接用 IP 访问 `http://100.84.64.88:5000`（CGNAT 网段通常被 clash 判为 private 直连）

## 4. 常用操作

```bash
systemctl --user status dufs      # 查看服务状态
systemctl --user restart dufs     # 重启（改完 service 文件先 daemon-reload）
journalctl --user -u dufs -f      # 跟踪日志
```
