#!/usr/bin/env bash

# <xbar.title>JK Meta Plugin</xbar.title>
# <xbar.version>v1.0</xbar.version>
# <xbar.author>Jivko Kolev</xbar.author>
# <xbar.author.github>jivkok</xbar.author.github>
# <xbar.desc>Displays JK's custom bitbar plugins: calendar, utilization (CPU, processes), network.</xbar.desc>
# <xbar.image>https://media.giphy.com/media/zzz/giphy.gif</xbar.image>
# <xbar.dependencies>bash</xbar.dependencies>

# Function helpers

function print-offset-month() {
  local month_offset="$1"
  local month=$(date -v${month_offset}m +%m)
  local year=$(date -v${month_offset}m +%Y)
  local month_name=$(date -jf %Y-%m-%d "$year"-"$month"-01 '+%b')

  echo "-----"
  echo "--$month_name $year|trim=false font=$font"
  cal -d "$year"-"$month" |awk 'NF'|sed 's/ *$//'| while IFS= read -r i; do echo "----$i|trim=false font=$font"; done
}

# Constants / variables
font="Monaco"
color="blue"
action_start_activity_monitor="start_am"
action_copy_to_clipboard="copy_to_clipboard"
action_speedtest="speedtest"
tmp_speedtest="/tmp/speedtest.txt"

# Action callbacks (i.e. menu clicks)

# Function to notify the user via Aple Script
apple_notify () {
  osascript -e "display notification \"$1\" with title \"$2\""
}

# Top: Start Activity Monitor
if [ "$1" = "$action_start_activity_monitor" ]; then
  osascript << END
  tell application "Activity Monitor"
    reopen
    activate
  end tell
END
  exit 0
fi

# NetInfo: copy to clipboard
if [ "$1" = "$action_copy_to_clipboard" ]; then
  echo "$2" | pbcopy
  apple_notify "Copied $2 to clipboard" "Net Info"
  exit 0
fi

# NetInfo: speedtest check
if [ "$1" = "$action_speedtest" ]; then
  if command -v speedtest-cli &> /dev/null; then
    if speedtest-cli --simple --share > "$tmp_speedtest"; then
      apple_notify "Speedtest completed" "Net Info"
    else
      apple_notify "Speedtest failed" "Net Info"
    fi
  else
     apple_notify "speedtest-cli not found" "Net Info"
  fi
  exit 0
fi

# Main content

# Content in OSX top menu bar
no_ip="No IP"
external_ip4=$(curl -4 --connect-timeout 3 -s http://v4.ipv6-test.com/api/myip.php || echo "$no_ip")
external_ip6=$(curl -6 --connect-timeout 3 -s http://v6.ipv6-test.com/api/myip.php || echo "$no_ip")
netinfo_has_ip="🌐"
[[ "$external_ip4" == "$no_ip" && "$external_ip6" == "$no_ip" ]]  && netinfo_has_ip="❌"
echo "$netinfo_has_ip | size=12"

# Calendar

echo "---"
echo "Calendar"

print-offset-month "-3"
print-offset-month "-2"
print-offset-month "-1"

echo "-----"
#cal |awk 'NF'|while IFS= read -r i; do echo " $i|trim=false font=$font color=$color"|  perl -pe '$b="\b";s/ _$b(\d)_$b(\d) /(\1\2)/' |perl -pe '$b="\b";s/_$b _$b(\d) /(\1)/' |sed 's/ *$//'; done
cal |awk 'NF'|while IFS= read -r i; do echo "-- $i"|perl -pe '$b="\b";s/ _$b(\d)_$b(\d) /(\1\2)/' |perl -pe '$b="\b";s/_$b _$b(\d) /(\1)/' |sed 's/ *$//' |sed "s/$/|trim=false font=$font color=$color/"; done

print-offset-month "+1"
print-offset-month "+2"
print-offset-month "+3"

# Top

# mapfile -t < <(top -F -R -l2 -o cpu -n 5 -s 2 -stats pid,command,cpu)
IFS=$'\n'
topdata=($(top -F -R -l2 -o cpu -n 5 -s 2 -stats pid,command,cpu))
top_line_load_avg=(${topdata[17]})
top_line_cpu_usage=(${topdata[18]})
top_line_pid_0=(${topdata[24]})
top_line_pid_1=(${topdata[25]})
top_line_pid_2=(${topdata[26]})
top_line_pid_3=(${topdata[27]})
top_line_pid_4=(${topdata[28]})
top_line_pid_5=(${topdata[29]})

echo "---"
echo "Top"
echo "--$top_line_cpu_usage | color=black refresh=true"
echo "--$top_line_load_avg | color=black refresh=true"
echo "-----"
echo "--$top_line_pid_0"
echo "--$top_line_pid_1"
echo "--$top_line_pid_2"
echo "--$top_line_pid_3"
echo "--$top_line_pid_4"
echo "--$top_line_pid_5"
echo "-----"
echo "--Open Activity Monitor | bash='$0' param1=$action_start_activity_monitor terminal=false"

# Net info

echo "---"
echo "Net Info"
echo "-----"
echo "--🔄 Refresh | color=black refresh=true"
echo "-----"
echo "--Public IP:"
echo "--IPv4: ${external_ip4} | bash='$0' param1=$action_copy_to_clipboard param2=$external_ip4 terminal=false"
echo "--IPv6: ${external_ip6} | bash='$0' param1=$action_copy_to_clipboard param2=$external_ip6 terminal=false"
echo "-----"
echo "--📈 Perform Speedtest | terminal=false refresh=true bash='$0' param1=$action_speedtest"
# Pretty format the last speedtest if the tmp file is found
if [[ -e "$tmp_speedtest" ]]; then
     LAST=$(stat -f "%Sm" -t "%Y-%m-%d %H:%M:%S" "$tmp_speedtest")
     PING=$(awk '/Ping: / { $1=""; print $0 }' "$tmp_speedtest")
     UP=$(awk '/Upload: / { $1=""; print $0 }' "$tmp_speedtest")
     DOWN=$(awk '/Download: / { $1=""; print $0 }' "$tmp_speedtest")
     echo "--Last checked: $LAST"
     [[ "$PING" != "" ]] && echo "--⏱$PING ▼$DOWN ▲$UP" || echo "--No results..."
else
     echo "--Last checked: Never"
fi

# Find active interfaces
INTERFACES=$(ifconfig | grep UP | egrep -o '(^en[0-9]*|^utun[0-9]*)' | sort -n)
# Loop through the interfaces and output MAC, IPv4 and IPv6 information
echo "-----"
for INT in $INTERFACES; do
     echo "--$INT:"
     ifconfig "$INT" | awk "/ether/ { print \"--MAC: \" \$2 \" | terminal=false bash='$0' param1=copy param2=\" \$2 }; /inet / { print \"--IPv4: \" \$2 \" | terminal=false bash='$0' param1=copy param2=\" \$2 };  /inet6/ { print \"--IPv6: \" \$2 \" | terminal=false bash='$0' param1=copy param2=\" \$2 }" | sed -e 's/%utun[0-9]*//g' -e 's/%en[0-9]*//g' | sort
     echo "-----"
done
