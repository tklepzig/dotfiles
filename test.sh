profiles="basic,extended"

hasProfile() {
  IFS=','
  echo $profiles
  for i in $profiles
  do
    echo $i
    echo $1
    if [ "$i" = "$1" ]
    then
      return 0
    fi
  done
  return 1
}

if hasProfile extended
then
  echo "extended"
fi
