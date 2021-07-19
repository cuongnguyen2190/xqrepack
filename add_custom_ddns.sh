#!/usr/bin/env bash
# adding custom DDNS for xiaomi router 
# 

function remove_pre_selected_ddns() {
    # remove pre-selected DNS option
    export DNS="                    <option value="2"><%:花生壳（oray.com）%></option>"
    sed -i '98s|.*|'"$DNS"'|' $FSDIR/usr/lib/lua/luci/view/web/setting/ddns.htm
    >&2 echo "done remove pre-selected DNS option"
}

function change_ddns_form_value() {
    # changing dns form value
    export SUBMIT_DNS='                <input type="text" id="eservername" name="eservername" {if($id == 1)}value="<%:No-ip.com%>"{/if} {if($id == 2)}value="<%:花生壳（oray.com）%>"{/if} {if($id == 3)}value="<%:公云（3322.org）%>"{/if} {if($id == 4)}value="<%:Dyndns.com%>"{/if} {if($id == 5)}value="<%:Custom DNS%>"{/if} class="ipt-text" data-postvalue="{$id}" disabled="disabled" />'
    sed -i '154s|.*|'"$SUBMIT_DNS"'|' $FSDIR/usr/lib/lua/luci/view/web/setting/ddns.htm
    >&2 echo "done changing dns form value"
}

function add_custom_ddns_option_to_web_form() {
    # adding more ddns option and set it as pre-selected
    export DNS_CUSTOM="                    <option value="5" selected="selected"><%:Custom DNS%></option> \n                    </select>"
    sed -i '102s|.*|'"$DNS_CUSTOM"'|' $FSDIR/usr/lib/lua/luci/view/web/setting/ddns.htm
    >&2 echo "done adding more ddns option and set it as pre-selected"
}

# cat "$FSDIR/usr/lib/lua/luci/view/web/setting/ddns.htm"

function add_custom_ddns_option_to_ddns_service() {
    # adding new option in dns service
    echo "\"dyndns.fr\"	\"update_custom_dns.sh\"" >> "$FSDIR/etc/ddns/services"
    >&2 echo "done adding new option in dns service"
}

function create_custom_ddns_update_shell_script() {
    # cat "$FSDIR/etc/ddns/services"

    touch "$FSDIR/usr/lib/ddns/update_custom_dns.sh"

    # prepare ddns update sh file
    >&2 echo "prepare ddns update sh file"

    cat <<'DNS' >> "$FSDIR/usr/lib/ddns/update_custom_dns.sh"
    #.Distributed under the terms of the GNU General Public License (GPL) version 2.0
    #.2014-2015 Christian Schoenebeck <christian dot schoenebeck at gmail dot com>
    local __DUMMY
    local __UPDURL="https://ns.DNS_HOSTNAME/update?secret=SECRET&domain=[DOMAIN]&addr=[IP]"
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

}

function update_ddns_hostname_value() {
    DNS_HOSTNAME=$1
    SECRET=$2
    sed -i 's|DNS_HOSTNAME|'"$DNS_HOSTNAME"'|' "$FSDIR/usr/lib/ddns/update_custom_dns.sh"
    sed -i 's|SECRET|'"$SECRET"'|' "$FSDIR/usr/lib/ddns/update_custom_dns.sh"
    >&2 cat "$FSDIR/usr/lib/ddns/update_custom_dns.sh"
    >&2 echo "Done preparing custon update_custom_dns.sh file"
}

function adding_new_custom_ddns() {
    DNS_HOSTNAME=$1
    SECRET=$2
    # replace luci from international firmware
    cp -r lua/luci $FSDIR/usr/lib/lua/
    remove_pre_selected_ddns
    change_ddns_form_value
    add_custom_ddns_option_to_web_form
    add_custom_ddns_option_to_ddns_service
    create_custom_ddns_update_shell_script
    update_ddns_hostname_value $DNS_HOSTNAME $SECRET
}



