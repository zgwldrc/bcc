function err(){
  echo "Error: $@"
}
function include_url_lib() {
  local t="$(mktemp)"
  local url="$1"
  curl -s -o "$t" "$1"
  . "$t"
  rm -f "$t"
}
function check_env(){
  local r
  for i do
    eval "r=\${${i}:-undefined}"
    if [ "$r" == "undefined" ];then
      return 1
    fi
  done
}
