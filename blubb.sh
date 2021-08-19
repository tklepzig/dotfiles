#!/usr/bin/env zsh

default="$(tput setab 172)$(tput setaf 0)"
fg="$(tput setaf 172)"
accent="$(tput setab 32)$(tput setaf 15)"
light="$(tput setab 179)$(tput setaf 0)"
lighter="$(tput setab 222)$(tput setaf 0)"
reset="$(tput sgr0)"
nl=$'\n'
width=$(tput cols)

tmux set -g status
tput civis

# Test Area to build digit strings
#
#    XXXXX
#    X...X
#    XXXXX
#    ....X
#    XXXXX
#

declare -A digits
digits[0]="11111,10001,10001,10001,11111"
digits[1]="00001,00001,00001,00001,00001"
digits[2]="11111,00001,11111,10000,11111"
digits[3]="11111,00001,11111,00001,11111"
digits[4]="10001,10001,11111,00001,00001"
digits[5]="11111,10000,11111,00001,11111"
digits[6]="11111,10000,11111,10001,11111"
digits[7]="11111,00001,00001,00001,00001"
digits[8]="11111,10001,11111,10001,11111"
digits[9]="11111,10001,11111,00001,11111"
digits[:]="00000,00100,00000,00100,00000"

renderTimeString() {
  timeString=$(date "+%H:%M")
  timeRow=$(($(tput lines) / 2 - 3))
  timeCol=$(($(tput cols) / 2 - 15))

  for (( i=0; i<${#timeString}; i++ )); do
    value="${timeString:$i:1}"

    for ((row = 0; row < 5; row++))
    do 
      for ((col = $((i * 6)); col < $((i * 6 + 5)); col++))
      do 
        index=$((( $row * 6 ) + $(($col - i * 6))))
        tput cup $(($timeRow + $row)) $(($timeCol + $col))
        if [[ "${digits[$value]:$index:1}" = "1" ]] 
        then
          echo -ne "$default $reset"
        else
          echo -ne "$reset "
        fi
      done
    done
  done
}

# For small pane
# echo -ne "$reset$(date "+%H:%M:%S")"

bar="$default$(printf "%${width}s")$reset"

tput cup 0 0
echo -ne "$bar"

tput cup $(tput lines) 0
echo -ne "$bar"

while true
do
  renderTimeString

  if read -k1 -s -t 1
  then
    break
  fi  
done

tmux set -g status
