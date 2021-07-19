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
command -v unsquashfs || { echo "install unsquashfs"; exit 1; }
mksquashfs -version || { echo "install mksquashfs"; exit 1; }

FSDIR=`mktemp -d /tmp/resquash-rootfs.XXXXX`
trap "rm -rf $FSDIR" EXIT

# test mknod privileges
mknod "$FSDIR/foo" c 0 0 || { echo "need to be run with fakeroot"; exit 1; }
rm -f "$FSDIR/foo"

>&2 echo "unpacking squashfs..."
unsquashfs -f -d "$FSDIR" "$IMG"

>&2 echo "patching squashfs..."

# create /opt dir
mkdir "$FSDIR/opt"
chmod 755 "$FSDIR/opt"

# modify dropbear init
sed -i 's/channel=.*/channel=release2/' "$FSDIR/etc/init.d/dropbear"
sed -i 's/flg_ssh=.*/flg_ssh=1/' "$FSDIR/etc/init.d/dropbear"

# mark web footer so that users can confirm the right version has been flashed
sed -i 's/romVersion%>/& xqrepack/;' "$FSDIR/usr/lib/lua/luci/view/web/inc/footer.htm"

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

boot_hook_add preinit_main enable__access
NVRAM

# modify root password
sed -i "s@root:[^:]*@root:${ROOTPW}@" "$FSDIR/etc/shadow"

# stop phone-home in web UI
cat <<JS >> "$FSDIR/www/js/miwifi-monitor.js"
(function(){ if (typeof window.MIWIFI_MONITOR !== "undefined") window.MIWIFI_MONITOR.log = function(a,b) {}; })();
JS

# add xqflash tool into firmware for easy upgrades
cp xqflash "$FSDIR/sbin"
chmod 0755      "$FSDIR/sbin/xqflash"
chown root:root "$FSDIR/sbin/xqflash"

# dont start crap services
for SVC in stat_points statisticsservice \
		datacenter \
		smartcontroller \
		wan_check \
		plugincenter plugin_start_script.sh cp_preinstall_plugins.sh; do
	rm -f $FSDIR/etc/rc.d/[SK]*$SVC
done

# prevent stats phone home & auto-update
for f in StatPoints mtd_crash_log logupload.lua otapredownload wanip_check.sh; do > $FSDIR/usr/sbin/$f; done

rm -f $FSDIR/etc/hotplug.d/iface/*wanip_check

sed -i '/start_service(/a return 0' $FSDIR/etc/init.d/messagingagent.sh

# cron jobs are mostly non-OpenWRT stuff
for f in $FSDIR/etc/crontabs/*; do
	sed -i 's/^/#/' $f
done

# as a last-ditch effort, change the *.miwifi.com hostnames to localhost
sed -i 's@\w\+.miwifi.com@localhost@g' $FSDIR/etc/config/miwifi

# replace luci from international firmware
cp -r lua/luci/view $FSDIR/usr/lib/lua/luci/

# remove pre-selected DNS option
export DNS="                    <option value="2"><%:花生壳（oray.com）%></option>"
sed -i '98s|.*|'"$DNS"'|' $FSDIR/usr/lib/lua/luci/view/web/setting/ddns.htm

>&2 echo "done remove pre-selected DNS option"

# changing dns form value
export SUBMIT_DNS='                <input type="text" id="eservername" name="eservername" {if($id == 1)}value="<%:No-ip.com%>"{/if} {if($id == 2)}value="<%:花生壳（oray.com）%>"{/if} {if($id == 3)}value="<%:公云（3322.org）%>"{/if} {if($id == 4)}value="<%:Dyndns.com%>"{/if} {if($id == 5)}value="<%:Custom DNS%>"{/if} class="ipt-text" data-postvalue="{$id}" disabled="disabled" />'
sed -i '154s|.*|'"$SUBMIT_DNS"'|' $FSDIR/usr/lib/lua/luci/view/web/setting/ddns.htm

>&2 echo "done changing dns form value"

# adding more ddns option and set it as pre-selected
export DNS_CUSTOM="                    <option value="5" selected="selected"><%:Custom DNS%></option> \n                    </select>"
sed -i '102s|.*|'"$DNS_CUSTOM"'|' $FSDIR/usr/lib/lua/luci/view/web/setting/ddns.htm

>&2 echo "done adding more ddns option and set it as pre-selected"

cat $FSDIR/usr/lib/lua/luci/view/web/setting/ddns.htm

# adding new option in dns service
echo "\"dyndns.fr\"	\"update_custom_dns.sh\"" >> "$FSDIR/etc/ddns/services"
>&2 echo "done adding new option in dns service"

# cat "$FSDIR/etc/ddns/services"

touch "$FSDIR/usr/lib/ddns/update_custom_dns.sh"

# prepare ddns update sh file
>&2 echo "prepare ddns update sh file"

cat <<'DNS' >> "$FSDIR/usr/lib/ddns/update_custom_dns.sh"
#.Distributed under the terms of the GNU General Public License (GPL) version 2.0
#.2014-2015 Christian Schoenebeck <christian dot schoenebeck at gmail dot com>
local __DUMMY
local __UPDURL="http://ns.DNS_HOSTNAME/update?secret=SECRET&domain=[DOMAIN]&addr=[IP]"
[ -z "$username" ] && write_log 14 "Service section not configured correctly! Missing 'username'"
[ -z "$password" ] && write_log 14 "Service section not configured correctly! Missing 'password'"
[ $use_ipv6 -eq 0 ] && __DUMMY="127.0.0.1" || __DUMMY="::1"
write_log 7 "sending dummy IP to DNS_HOSTNAME"
__URL=$(echo $__UPDURL | sed -e "s#\[USERNAME\]#$URL_USER#g" -e "s#\[PASSWORD\]#$URL_PASS#g" \
-e "s#\[DOMAIN\]#$domain#g" -e "s#\[IP\]#$__DUMMY#g")
[ $use_https -ne 0 ] && __URL=$(echo $__URL | sed -e 's#^http:#https:#')
do_transfer "$__URL" || return 1
write_log 7 "DNS_HOSTNAME answered:${N}$(cat $DATFILE)"
grep -E "\"Success\":true" $DATFILE >/dev/null 2>&1 || return 1
sleep 1
write_log 7 "sending real IP to DNS_HOSTNAME"
__URL=$(echo $__UPDURL | sed -e "s#\[USERNAME\]#$URL_USER#g" -e "s#\[PASSWORD\]#$URL_PASS#g" \
-e "s#\[DOMAIN\]#$domain#g" -e "s#\[IP\]#$__IP#g")
[ $use_https -ne 0 ] && __URL=$(echo $__URL | sed -e 's#^http:#https:#')
do_transfer "$__URL" || return 1
write_log 7 "DNS_HOSTNAME answered:${N}$(cat $DATFILE)"
grep -E "\"Success\":true" $DATFILE >/dev/null 2>&1
return $?
DNS

chmod +x "$FSDIR/usr/lib/ddns/update_custom_dns.sh"

sed -i 's|DNS_HOSTNAME|'"$DNS_HOSTNAME"'|' "$FSDIR/usr/lib/ddns/update_custom_dns.sh"

sed -i 's|SECRET|'"$SECRET"'|' "$FSDIR/usr/lib/ddns/update_custom_dns.sh"

>&2 cat "$FSDIR/usr/lib/ddns/update_custom_dns.sh"

>&2 echo "Done preparing custon update_custom_dns.sh file"

>&2 echo "repacking squashfs..."
rm -f "$IMG.new"
mksquashfs "$FSDIR" "$IMG.new" -comp xz -b 256K -no-xattrs

