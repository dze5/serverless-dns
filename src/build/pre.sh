#!/bin/sh

wk="$1"
mm="$2"
yyyy="$3"

# stackoverflow.com/a/24753942
hasfwslash() {
case "$1" in
*/*) echo yes ;;
*   ) echo no ;;
esac
}

burl="https://cfstore.rethinkdns.com/blocklists"
dir="bc"
codec="u6"
f="basicconfig.json"
f2="filetag.json"
cwd=$(pwd)
# exec this script from npm or project root
out="./src/${codec}-${f}"
out2="./src/${codec}-${f2}"
name=$(uname)

if [ "$name" = "Darwin" ]
then
    now=$(date -u +"%s")
else
    now=$(date --utc +"%s")
fi

if [ "$name" = "Darwin" ]
then
    day=$(date -r "$now" "+%d")
else
    day=$(date -d "@$now" "+%d")
fi
day=${day#0}
wkdef=$(((day + 7 -1) / 7))
if [ "$name" = "Darwin" ]
then
    yyyydef=$(date -r "$now" "+%Y")
else
    yyyydef=$(date -d "@$now" "+%Y")
fi
if [ "$name" = "Darwin" ]
then
    mmdef=$(date -r "$now" "+%m")
else
    mmdef=$(date -d "@$now" "+%m")
fi
mmdef=${mmdef#0}

: "${wk:=$wkdef}" "${mm:=$mmdef}" "${yyyy:=$yyyydef}"

max=4
for i in $(seq 0 $max)
do
    echo "x=== pre.sh: $i try $yyyy/$mm-$wk at $now from $cwd"

    if [ -f "${out}" ] || [ -L "${out}" ]; then
        echo "=x== pre.sh: no op ${out}"
        exit 0
    else
        # 用 curl 替代 wget
        curl -fsSL --retry 3 --retry-delay 3 \
            "${burl}/${yyyy}/${dir}/${mm}-${wk}/${codec}/${f}" -o "${out}"
        wcode=$?

        if [ $wcode -eq 0 ]; then
            fulltimestamp=$(cut -d"," -f9 "$out" | cut -d":" -f2 | tr -dc '0-9/')
            if [ "$(hasfwslash "$fulltimestamp")" = "no" ]; then
                echo "==x= pre.sh: $i filetag at f8"
                fulltimestamp=$(cut -d"," -f8 "$out" | cut -d":" -f2 | tr -dc '0-9/')
            fi
            echo "==x= pre.sh: $i ok $wcode; filetag? ${fulltimestamp}"
            curl -fsSL --retry 3 --retry-delay 3 \
                "${burl}/${fulltimestamp}/${codec}/${f2}" -o "${out2}"
            wcode2=$?
            if [ $wcode2 -eq 0 ]; then
                echo "===x pre.sh: $i filetag ok $wcode2"
                exit 0
            else
                echo "===x pre.sh: $i not ok $wcode2"
                rm -f "${out}" "${out2}"
                exit 1
            fi
        else
            rm -f "${out}"
            echo "==x= pre.sh: $i not ok $wcode"
        fi
    fi

    wk=$((wk - 1))
    if [ $wk -eq 0 ]; then
        wk="5"
        mm=$((mm - 1))
    fi
    if [ $mm -eq 0 ]; then
        mm="12"
        yyyy=$((yyyy - 1))
    fi
done

exit 1
