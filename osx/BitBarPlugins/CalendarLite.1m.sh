#!/usr/bin/env bash

# <bitbar.title>Clock with calendar</bitbar.title>
# <bitbar.version>v1.0</bitbar.version>
# <bitbar.author>Weibing Chen</bitbar.author>
# <bitbar.author.github>WeibingChen17</bitbar.author.github>
# <bitbar.desc>A clock with a simple calendar</bitbar.desc>
# <bitbar.image>http://i65.tinypic.com/260sz1t.png</bitbar.image>
# <bitbar.dependencies>bash</bitbar.dependencies>
# <bitbar.abouturl>https://github.com/WeibingChen17/</bitbar.abouturl>

function print-month() {
  local month_offset="$1"
  local month=$(date -v${month_offset}m +%m)
  local year=$(date -v${month_offset}m +%Y)
  local month_name=$(date -jf %Y-%m-%d "$year"-"$month"-01 '+%b')

  echo "---"
  echo "$month_name $year|trim=false font=$font"
  cal -d "$year"-"$month" |awk 'NF'|sed 's/ *$//'| while IFS= read -r i; do echo "--$i|trim=false font=$font"; done
}

font="Monaco"
color="blue"

echo "$(date "+%l:%M %p")|size=12"

# For a flat 3-month view: uncomment the line below and comment out all the lines below
#echo "---"
#cal -3 |awk 'NF'|sed 's/ $//' |while IFS= read -r i; do echo " $i|trim=false font=$font color=$color"|  perl -pe '$b="\b";s/ _$b(\d)_$b(\d) /(\1\2)/' |perl -pe '$b="\b";s/_$b _$b(\d) /(\1)/'  ; done

print-month "-3"
print-month "-2"
print-month "-1"

echo "---"
#cal |awk 'NF'|while IFS= read -r i; do echo " $i|trim=false font=$font color=$color"|  perl -pe '$b="\b";s/ _$b(\d)_$b(\d) /(\1\2)/' |perl -pe '$b="\b";s/_$b _$b(\d) /(\1)/' |sed 's/ *$//'; done
cal |awk 'NF'|while IFS= read -r i; do echo " $i"|perl -pe '$b="\b";s/ _$b(\d)_$b(\d) /(\1\2)/' |perl -pe '$b="\b";s/_$b _$b(\d) /(\1)/' |sed 's/ *$//' |sed "s/$/|trim=false font=$font color=$color/"; done

print-month "+1"
print-month "+2"
print-month "+3"
