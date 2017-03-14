#!/bin/bash

#----Operation openshift api----
#$1 https ca file
#$2 server cert file
#$3 server key file
#$4 openshift master url
#$5 dc namespace
#$6 api action: "PUT | GET | DELETE"
#$7 resource name
#$8 file path
function Request_ose_api(){
  local ca_file=$1
  local cert_file=$2
  local key_file=$3
  local master_url=$4
  local namespace=$5
  local api_action=$6
  local resource_name=$7
  local resource_file_path=$8
  local timeout_opts="-m 1 --connect-timeout 1"
  local api_response_code
  case "$api_action" in
    GET)
      local api_response_code=$(curl $timeout_opts -s -o ${resource_file_path}  -w "%{http_code}"  -XGET --cacert $ca_file --cert $cert_file --key $key_file  -H "Content-type:application/json" ${master_url}/oapi/v1/namespaces/${namespace}/deploymentconfigs/${resource_name})
      ;;
    PUT)
      local api_response_code=$(curl $timeout_opts -s -o /dev/null -w "%{http_code}" -XPUT --cacert $ca_file --cert $cert_file --key $key_file -H "Content-type:application/json" ${master_url}/oapi/v1/namespaces/${namespace}/deploymentconfigs/${resource_name} --data  "@${resource_file_path}")
      ;;
    DELETE)
      local api_response_code=$(curl $timeout_opts -s -o /dev/null -w "%{http_code}" -XDELETE --cacert $ca_file --cert $cert_file --key $key_file -H "Content-type:application/json" ${master_url}/oapi/v1/namespaces/${namespace}/deploymentconfigs/${resource_name})
      ;;
  esac
  echo $api_response_code
}

#$1 dc info like test/pod-a:2
function Get_dc_info(){
  local dc_info=$1
  local ns_name=`echo $dc_info | cut -d '/' -f 1`
  local dc_name=`echo $dc_info | cut -d ':' -f 1 | cut -d '/' -f 2`
  local scale_pod_num=`echo $dc_info | cut -d ':' -f 2`
  local dc_info_list=($ns_name $dc_name $scale_pod_num)
  echo "${dc_info_list[@]}" 
}

#$1 scale_pod_num
#$2 dc_file_path
function Change_dc_replicas(){
  local scale_pod_num=$1
  local dc_file_path=$2
  local line_num=`grep -n 'replicas' $dc_file_path |head -1 | cut -d ':' -f 1`
  sed -i "${line_num}s#    \"replicas\":.*#    \"replicas\": ${scale_pod_num},#" $dc_file_path
}
