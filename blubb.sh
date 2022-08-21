#!/usr/bin/env zsh

${accentText:s/colour/}
primaryTile="$(tput setab ${primaryBg:s/colour/})$(tput setaf ${primaryFg:s/colour/})"
primary="$(tput setaf ${primaryText:s/colour/})"
secondaryTile="$(tput setab ${secondaryBg:s/colour/})$(tput setaf ${secondaryFg:s/colour/})"
secondary="$(tput setaf ${secondaryText:s/colour/})"
accentTile="$(tput setab ${accentBg:s/colour/})$(tput setaf ${accentFg:s/colour/})"
accent="$(tput setaf ${accentText:s/colour/})"
reset="$(tput sgr0)"
nl=$'\n'

tput civis

# Test Area to build digit strings
#
#    XXXX.
#    X...X
#    XXXX.
#    X.X..
#    X..X.
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
digits[.]="00000,00000,00000,00000,10000"
digits[-]="00000,00000,11111,00000,00000"
digits[A]="11111,10001,11111,10001,10001"
digits[B]="11110,10001,11110,10001,11110"
digits[C]="11111,10000,10000,10000,11111"
digits[D]="11110,10001,10001,10001,11110"
digits[E]="11111,10000,11111,10000,11111"
digits[F]="11111,10000,11111,10000,10000"
digits[G]="01111,10000,10011,10001,01111"
digits[H]="10001,10001,11111,10001,10001"
digits[I]="01110,00100,00100,00100,01110"
digits[J]="11110,00010,00010,10010,01100"
digits[K]="10001,10010,11000,10010,10001"
digits[L]="10000,10000,10000,10000,11111"
digits[M]="11011,10101,10001,10001,10001"
digits[N]="10001,11001,10101,10011,10001"
digits[O]="01110,10001,10001,10001,01110"
digits[P]="11110,10001,11110,10000,10000"
digits[Q]="01110,10001,10101,10011,01110"
digits[R]="11110,10001,11110,10010,10001"
digits[S]="01111,10000,01100,00011,11110"
digits[T]="11111,00100,00100,00100,00100"
digits[U]="10001,10001,10001,10001,01110"
digits[V]="10001,10001,10001,01010,00100"
digits[W]="10001,10001,10101,11011,01010"
digits[X]="10001,01010,00100,01010,10001"
digits[Y]="10001,01010,00100,00100,00100"
digits[Z]="11111,00010,00100,01000,11111"

renderString() {
  string=$1
  stringRow=$2
  colour=${3:-$primaryTile}

  if [ "$stringRow" = "top" ]
  then 
    stringRow=2
  elif [ "$stringRow" = "centre" ]
  then 
    stringRow=$(($(tput lines) / 2 - 3))
  elif [ "$stringRow" = "bottom" ]
  then 
    stringRow=$(($(tput lines) - 6))
  fi

  stringCol=$(($(tput cols) / 2 - $((${#string} * 6 / 2))))

  for (( i=0; i<${#string}; i++ )); do
    value="${string:$i:1}"

    for ((row = 0; row < 5; row++))
    do 
      for ((col = $((i * 6)); col < $((i * 6 + 5)); col++))
      do 
        index=$((( $row * 6 ) + $(($col - i * 6))))
        tput cup $(($stringRow + $row)) $(($stringCol + $col))
        if [[ "${digits[$value]:$index:1}" = "1" ]] 
        then
          echo -ne "$colour $reset"
        else
          echo -ne "$reset "
        fi
      done
    done
  done
}

# For small pane
# echo -ne "$reset$(date "+%H:%M:%S")"

while true
do
  tput cup 0 0
  echo -ne "$primaryTile$(printf "%$(tput cols)s")$reset"

  renderString $(date "+%H:%M") centre $secondaryTile
  renderString "S.H.I.E.L.D." top
  renderString "0-8-4" bottom $accentTile

  #ssid="$(iwgetid -r)"
  #tput cup $(($(tput lines) - 3)) $(($(tput cols) / 2 - ${#ssid} / 2))
  #echo -ne "$ssid"

  tput cup $(($(tput lines) - 3)) $(($(tput cols) / 2 + 20))
  echo -ne "$(tput setaf ${accentText:s/colour/})blubb"
  #strength="$(iwconfig wlp0s20f3 | awk -F'[ =]+' '/Signal level/ {print $7}')"
  #tput cup $(($(tput lines) - 2)) $(($(tput cols) / 2 - ${#strength} / 2))
  #echo -ne "$strength"

  if read -k 1 -s -t 1 char
  then
    if [ "$char" = "r" ]
    then
      tput clear
      continue
    else
      break
    fi
  fi  
  sleep 0.2
done

clear
tput cnorm

# TODO
# Appointments
# GH notifications
# Mails
# SSID (iwgetid -r)
# Signal strength (iwconfig <interface> | awk -F'[ =]+' '/Signal level/ {print $7}', https://eyesaas.com/wi-fi-signal-strength/)

