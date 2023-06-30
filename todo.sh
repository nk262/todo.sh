#!/bin/sh
set -eu

trap '' 1 2 3 15

TODO="$HOME/.todo"
DEFAULT_CMD="list"

# functions
is_number() {
  for i in $(seq "${#1}") ; do
    case "$(echo "$1" | cut -c$i)" in
      [^0123456789] ) return 1 ;;
    esac
  done
}


# usage
usage() {
cat << EOF
  usage:
    $0 [command] [args]
  commands:
    help list add del clear
EOF
}

# set up todo file
setup_todo() {
  if ! [ -f "$TODO" ]; then
    if [ -e "$TODO" ] || [ -L "$TODO" ]; then
      echo "Could not create todo file."
      exit 1
    else
      : > "$TODO"
    fi
  fi
}

# add todo
add_todo() {
  if [ $# -lt 2 ] || [ $# -gt 3 ] ; then
    echo "Wrong number of arguments."
    exit 1
  fi
  
  todo_stat="t"
  todo_date="$(date "+%y-%m-%d_%H:%M:%S")"
  todo_tag="#"
  todo_text="$2"
  todo_line="$todo_stat $todo_date $todo_tag $todo_text"
  
  if [ $# -eq 3 ]; then
    if ! is_number "$3" ; then
      echo "Is NaN."
      exit 1
    fi
    echo "$(cat "$TODO" | sed "${3}i$todo_line")" > "$TODO"
  else
    echo "$todo_line" >> "$TODO"
  fi
}

# delete todo
del_todo() {
  if ! [ $# -eq 2 ]; then
    echo "Wrong number of arguments."
    exit 1
  fi
  if is_number "$2"; then
    echo "$(cat "$TODO" | sed "${2}d")" > "$TODO"
  else
    echo "Is NaN."
    exit 1
  fi
}

# clear todo
clear_todo() {
  if [ -f "$TODO" ]; then
    : > "$TODO"
  fi
}

# list todo
list_todo() {
  max_len=0
  while read line ; do
    todo_text="$(echo "$line" | cut -d" " -f4-)"
    if [ ${#todo_text} -gt $max_len ]; then
      max_len=${#todo_text}
    fi
  done < "$TODO"
  
  idx=1
  while read line ; do
    todo_stat="$(echo "$line" | cut -d" " -f1)"
    [ -z "$todo_stat" ] && continue
    
    todo_date="$(echo "$line" | cut -d" " -f2)"
    [ -z "$todo_date" ] && continue
    
    todo_tag="$(echo "$line" | cut -d" " -f3)"
    [ -z "$todo_tag" ] && continue
    todo_tag="$(echo "$todo_tag" | cut -c2-)"
    
    todo_text="$(echo "$line" | cut -d" " -f4-)"
    [ -z "$todo_text" ] && continue
    
    printf "($idx) "
    printf "$todo_stat : "
    printf "[$todo_text"
    yes " " | head -n $(($max_len-${#todo_text})) | tr -d "\n"
    printf "]"
    printf " # $todo_tag"
    printf " : $todo_date"
    echo
    
    idx=$(($idx+1))
  done < "$TODO"
}

# todo command
main() {
  setup_todo
  case "${1:-$DEFAULT_CMD}" in
    h* | -h* | --h* ) usage ;;
    a* ) add_todo "$@" ;;
    d* ) del_todo "$@" ;;
    c* ) clear_todo ;;
    l* ) list_todo ;;
    * )
      echo "Did not find command: \"${1}\""
      usage
      exit 1
      ;;
  esac
}

main "$@"

exit

