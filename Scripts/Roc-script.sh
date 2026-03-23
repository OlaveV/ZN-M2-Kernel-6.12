#!/bin/bash

# 1. 修改默认管理 IP 为 192.168.2.1
sed -i 's/192.168.1.1/192.168.2.1/g' package/base-files/files/bin/config_generate

# 2. NSS 内存适配 (针对 ZN-M2 1GB 硬件版本)
DTS_FILE="target/linux/qualcommax/files/arch/arm64/boot/dts/qcom/ipq6018-512m.dtsi"
if [ -f "$DTS_FILE" ]; then
    echo "Adapting NSS Memory for 1GB RAM..."
    # 扩大内存映射范围至 0x04000000
    sed -i 's/reg = <0x0 0x4ab00000 0x0 0x[0-9a-f]\+>/reg = <0x0 0x4ab00000 0x0 0x04000000>/' "$DTS_FILE"
fi

# 3. 插件环境清理与拉取
# 移除旧版插件，确保使用最新源码
rm -rf feeds/luci/themes/luci-theme-argon
rm -rf feeds/luci/applications/luci-app-argon-config
rm -rf feeds/luci/applications/luci-app-openclash
./scripts/feeds uninstall luci-app-openclash

git clone --depth=1 https://github.com/jerrykuku/luci-theme-argon feeds/luci/themes/luci-theme-argon
git clone --depth=1 https://github.com/vernesong/OpenClash package/luci-app-openclash

# 4. Golang 强制替换 (解决 OpenClash 编译依赖)
rm -rf feeds/packages/lang/golang
git clone --depth=1 https://github.com/sbwml/packages_lang_golang feeds/packages/lang/golang

# 5. Docker 优化：预设根目录为 /opt/docker
if [ -d "feeds/luci/applications/luci-app-dockerman" ]; then
    sed -i 's/docker_root=.*/docker_root=\/opt\/docker/g' feeds/luci/applications/luci-app-dockerman/root/etc/config/dockerman || true
fi