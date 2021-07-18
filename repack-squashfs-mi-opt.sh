#!/usr/bin/env bash
#
# unpack, modify and re-pack the Xiaomi R3600 firmware
# removes checks for release channel before starting dropbear
#
# 2020.07.20  darell tan
# 

set -e

IMG=$1
DNS_HOSTNAME=$2
SECRET=$3
ROOTPW='$1$qtLLI4cm$c0v3yxzYPI46s28rbAYG//'  # "password"

[ -e "$IMG" ] || { echo "rootfs img not found $IMG"; exit 1; }

# verify programs exist
command -v unsquashfs &>/dev/null || { echo "install unsquashfs"; exit 1; }
mksquashfs -version >/dev/null || { echo "install mksquashfs"; exit 1; }

FSDIR=`mktemp -d /tmp/resquash-rootfs.XXXXX`
trap "rm -rf $FSDIR" EXIT

# test mknod privileges
mknod "$FSDIR/foo" c 0 0 2>/dev/null || { echo "need to be run with fakeroot"; exit 1; }
rm -f "$FSDIR/foo"

>&2 echo "unpacking squashfs..."
unsquashfs -f -d "$FSDIR" "$IMG"

>&2 echo "patching squashfs..."

# create /opt dir
mkdir "$FSDIR/opt"
chmod 755 "$FSDIR/opt"

# add global firmware language packages
cp -R ./language-packages/opkg-info/. $FSDIR/usr/lib/opkg/"info"
cat ./language-packages/languages.txt >>$FSDIR/usr/lib/opkg/status
chmod +x $FSDIR/usr/lib/opkg/info/luci-i18n-spanish.prerm

# translate xiaomi stuff to Spanish
sed -i 's/连接设备数量/"Dispositivos conectados"/g' "$FSDIR/usr/lib/lua/luci/view/web/index.htm"
sed -i 's/连接设备数量/"Dispositivos conectados"/g' "$FSDIR/usr/lib/lua/luci/view/web/apindex.htm"

sed -i 's/Wi-Fi名称/"Nombre Wi-Fi"/g' "$FSDIR/usr/lib/lua/luci/view/web/index.htm"
sed -i 's/Wi-Fi名称/"Nombre Wi-Fi"/g' "$FSDIR/usr/lib/lua/luci/view/web/apindex.htm"

sed -i 's/Wi-Fi密码/"Contraseña"/g' "$FSDIR/usr/lib/lua/luci/view/web/apindex.htm"
sed -i 's/Wi-Fi密码/"Contraseña"/g' "$FSDIR/usr/lib/lua/luci/view/web/index.htm"

sed -i 's/>设置/">Ajustes"/g' "$FSDIR/usr/lib/lua/luci/view/web/index.htm"
sed -i 's/>设置/">Ajustes"/g' "$FSDIR/usr/lib/lua/luci/view/web/apindex.htm"

sed -i 's/小米AIoT路由器 AX3600/"Router AIoT Mi AX3600"/g' "$FSDIR/usr/lib/lua/luci/view/web/index.htm"
sed -i 's/小米AIoT路由器 AX3600/"Router AIoT Mi AX3600"/g' "$FSDIR/usr/lib/lua/luci/view/web/apindex.htm"

sed -i 's/开启后，2.4G和5G将合并显示为同一个名称，路由器将优先为终端选择5G网络。合并名称后部分终端可能离线，需重新连接。/"Cuando la función esté activada, las redes 2,4G y 5G compartirán el mismo nombre. El router elegirá la mejor señal disponible. Por ejemplo, cambiará a la red 5G si el dispositivo está cerca y a la red 2,4G si está lejos. Se pueden producir breves interrupciones durante el cambio."/g' "$FSDIR/usr/lib/lua/luci/view/web/setting/wifi.htm"
sed -i 's/开启后，2.4G和5G将合并显示为同一个名称，路由器将优先为终端选择5G网络。合并名称后部分终端可能离线，需重新连接。/"Cuando la función esté activada, las redes 2,4G y 5G compartirán el mismo nombre. El router elegirá la mejor señal disponible. Por ejemplo, cambiará a la red 5G si el dispositivo está cerca y a la red 2,4G si está lejos. Se pueden producir breves interrupciones durante el cambio."/g' "$FSDIR/usr/lib/lua/luci/view/web/apsetting/wifi.htm"

sed -i 's/Wi-Fi 5 兼容模式/"Modo compatible con Wi-Fi 5 (802.11ac)"/g' "$FSDIR/usr/lib/lua/luci/view/web/setting/wifi.htm"
sed -i 's/Wi-Fi 5 兼容模式/"Modo compatible con Wi-Fi 5 (802.11ac)"/g' "$FSDIR/usr/lib/lua/luci/view/web/apsetting/wifi.htm"

sed -i 's/某些老设备对Wi-Fi6支持不好，可能扫描不到信号或者连接不上等。开启此开关后，将会切换到Wi-Fi5模式，解决兼容问题。但同时会关闭Wi-Fi6的相关功能，如OFDMA，BSS Coloring等。/"Algunos dispositivos antiguos no son compatibles con Wi-Fi 6 y pueden tener problemas de compatibilidad, como errores de escaneo o de conexión Wi-Fi. Una vez que se haya encendido este interruptor, el router funcionará en el modo compatible con Wi-Fi 5 para solucionar los problemas de compatibilidad. También desactivará las funciones relacionadas con Wi-Fi 6, como OFDMA, colores de BSS, etc."/g' "$FSDIR/usr/lib/lua/luci/view/web/setting/wifi.htm"
sed -i 's/某些老设备对Wi-Fi6支持不好，可能扫描不到信号或者连接不上等。开启此开关后，将会切换到Wi-Fi5模式，解决兼容问题。但同时会关闭Wi-Fi6的相关功能，如OFDMA，BSS Coloring等。/"Algunos dispositivos antiguos no son compatibles con Wi-Fi 6 y pueden tener problemas de compatibilidad, como errores de escaneo o de conexión Wi-Fi. Una vez que se haya encendido este interruptor, el router funcionará en el modo compatible con Wi-Fi 5 para solucionar los problemas de compatibilidad. También desactivará las funciones relacionadas con Wi-Fi 6, como OFDMA, colores de BSS, etc."/g' "$FSDIR/usr/lib/lua/luci/view/web/apsetting/wifi.htm"

sed -i 's/AIoT智能天线自动扫描功能可以自动发现未初始化的小米智能设备，通过米家APP快速入网。/"El escaneo automático de antena inteligente AIoT puede encontrar automáticamente dispositivos inteligentes Mi que no han sido iniciados y conectar rápidamente con ellos a través de la aplicación Mi Home."/g' "$FSDIR/usr/lib/lua/luci/view/web/setting/wifi.htm"
sed -i 's/AIoT智能天线自动扫描功能可以自动发现未初始化的小米智能设备，通过米家APP快速入网。/"El escaneo automático de antena inteligente AIoT puede encontrar automáticamente dispositivos inteligentes Mi que no han sido iniciados y conectar rápidamente con ellos a través de la aplicación Mi Home."/g' "$FSDIR/usr/lib/lua/luci/view/web/apsetting/wifi.htm"

sed -i 's/:畅快连/":Conexión rápida"/g' "$FSDIR/usr/lib/lua/luci/view/web/setting/wifi.htm"
sed -i 's/:畅快连/":Conexión rápida"/g' "$FSDIR/usr/lib/lua/luci/view/web/apsetting/wifi.htm"

sed -i 's/此功能可能在网络拥塞的环境下导致网络出现一定的丢包变多及延时提高的问题。/"Esta característica puede causar algunos problemas de red de más pérdida de paquetes y mayor latencia en un entorno de red congestionado."/g' "$FSDIR/usr/lib/lua/luci/view/web/setting/wifi.htm"
sed -i 's/此功能可能在网络拥塞的环境下导致网络出现一定的丢包变多及延时提高的问题。/"Esta característica puede causar algunos problemas de red de más pérdida de paquetes y mayor latencia en un entorno de red congestionado."/g' "$FSDIR/usr/lib/lua/luci/view/web/apsetting/wifi.htm"

sed -i 's/时区设置/"Región y hora"/g' "$FSDIR/usr/lib/lua/luci/view/web/inc/sysinfo_ap.htm"
sed -i 's/时区设置/"Región y hora"/g' "$FSDIR/usr/lib/lua/luci/view/web/inc/sysinfo.htm"

sed -i 's/开启此功能，路由器可自动发现支持畅快连的未初始化Wi-Fi设备，通过米家APP快速配网；修改路由器密码也将自动同步给支持畅快连的设备。/"Con esta función activada, el router puede descubrir automáticamente los dispositivos Wi-Fi no inicializados que admiten Smooth Connect y emparejarlos rápidamente con la red a través de Mi Home App; el cambio de la contraseña del router también se sincronizará automáticamente con los dispositivos que admiten Smooth Connect."/g' "$FSDIR/usr/lib/lua/luci/view/web/setting/wifi.htm"
sed -i 's/开启此功能，路由器可自动发现支持畅快连的未初始化Wi-Fi设备，通过米家APP快速配网；修改路由器密码也将自动同步给支持畅快连的设备。/"Con esta función activada, el router puede descubrir automáticamente los dispositivos Wi-Fi no inicializados que admiten Smooth Connect y emparejarlos rápidamente con la red a través de Mi Home App; el cambio de la contraseña del router también se sincronizará automáticamente con los dispositivos que admiten Smooth Connect."/g' "$FSDIR/usr/lib/lua/luci/view/web/apsetting/wifi.htm"

# modify dropbear init
sed -i 's/channel=.*/channel=release2/' "$FSDIR/etc/init.d/dropbear"
sed -i 's/flg_ssh=.*/flg_ssh=1/' "$FSDIR/etc/init.d/dropbear"

# mark web footer so that users can confirm the right version has been flashed
sed -i 's/romVersion%>/& xqrepack-mi-opt-translated/;' "$FSDIR/usr/lib/lua/luci/view/web/inc/footer.htm"

# stop resetting root password
sed -i '/set_user(/a return 0' "$FSDIR/etc/init.d/system"

# make sure our backdoors are always enabled by default
sed -i '/ssh_en/d;' "$FSDIR/usr/share/xiaoqiang/xiaoqiang-reserved.txt"
sed -i '/ssh_en=/d; /uart_en=/d; /boot_wait=/d;' "$FSDIR/usr/share/xiaoqiang/xiaoqiang-defaults.txt"
cat <<XQDEF >> "$FSDIR/usr/share/xiaoqiang/xiaoqiang-defaults.txt"
uart_en=1
ssh_en=1
boot_wait=on
XQDEF

# always reset our access nvram variables
grep -q -w enable_dev_access "$FSDIR/lib/preinit/31_restore_nvram" || \
 cat <<NVRAM >> "$FSDIR/lib/preinit/31_restore_nvram"
enable_dev_access() {
	nvram set uart_en=1
	nvram set ssh_en=1
	nvram set boot_wait=on
	nvram commit
}

boot_hook_add preinit_main enable_dev_access
NVRAM

# modify root password
sed -i "s@root:[^:]*@root:${ROOTPW}@" "$FSDIR/etc/shadow"

# stop phone-home in web UI
#cat <<JS >> "$FSDIR/www/js/miwifi-monitor.js"
#(function(){ if (typeof window.MIWIFI_MONITOR !== "undefined") window.MIWIFI_MONITOR.log = function(a,b) {}; })();
#JS

# add xqflash tool into firmware for easy upgrades
cp xqflash "$FSDIR/sbin"
chmod 0755      "$FSDIR/sbin/xqflash"
chown root:root "$FSDIR/sbin/xqflash"

# dont start crap services
#for SVC in stat_points statisticsservice \
#		datacenter \
#		smartcontroller \
#		wan_check \
#		plugincenter plugin_start_script.sh cp_preinstall_plugins.sh; do
#	rm -f $FSDIR/etc/rc.d/[SK]*$SVC
#done

# prevent stats phone home & auto-update
#for f in StatPoints mtd_crash_log logupload.lua otapredownload wanip_check.sh; do > $FSDIR/usr/sbin/$f; done

# prevent auto-update
> $FSDIR/usr/sbin/otapredownload

#rm -f $FSDIR/etc/hotplug.d/iface/*wanip_check

#sed -i '/start_service(/a return 0' $FSDIR/etc/init.d/messagingagent.sh

# cron jobs are mostly non-OpenWRT stuff
#for f in $FSDIR/etc/crontabs/*; do
#	sed -i 's/^/#/' $f
#done

# as a last-ditch effort, change the *.miwifi.com hostnames to localhost
#sed -i 's@\w\+.miwifi.com@localhost@g' $FSDIR/etc/config/miwifi

. ./add_custom_ddns.sh

adding_new_custom_ddns $DNS_HOSTNAME $SECRET

# apply patch from xqrepack repository
(cd "$FSDIR" && patch -p1) < 0001-Add-TX-power-in-dBm-options-in-web-interface.patch

>&2 echo "repacking squashfs..."
rm -f "$IMG.new"
mksquashfs "$FSDIR" "$IMG.new" -comp xz -b 256K -no-xattrs
