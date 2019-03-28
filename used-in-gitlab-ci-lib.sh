function err(){
  echo "Error: $@"
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