#!/bin/bash
#must set env DEPLOY_INFO_MAPPING: namespaces1/dc_name1:desired_num1,namespaces2/dc_name2:desired_num2
#export DEPLOY_INFO_MAPPING="test/pod-a:2,test/pod-b:3"


function find_env() {
  var=`printenv "$1"`
  if [ -n "$var" ]; then
    echo $var
  else
    echo $2
  fi
}
script_path=$(find_env "SCRIPT_PATH" /opt)
#script_path=$(find_env "SCRIPT_PATH" /root/scheduledjob-scaler/scheduledjob)
dc_info_mapping=$(find_env "DEPLOY_INFO_MAPPING")
retry_times=$(find_env "RETRY_TIMES" 20)

CA_FILE=${script_path}/ca.crt
CERT_FILE=${script_path}/admin.crt
KEY_FILE=${script_path}/admin.key
MASTER_URL='https://kubernetes.default.svc.cluster.local'

if [ ! -f $script_path/scheduledjob-utils.sh ];then
  echo "not find $script_path/scheduledjob-utils.sh"
  exit 217
fi
. $script_path/scheduledjob-utils.sh

#--------main---------------
if [ ! -n "$dc_info_mapping" ];then
  echo "no DEPLOY_INFO_MAPPING set"
  exit 0
fi
#test ose api
i=0
while (( i++ < retry_times ));do
  response_code=$(curl -m 1 --connect-timeout 1 -s -o /dev/null -w "%{http_code}"  -XGET --cacert $CA_FILE --cert $CERT_FILE --key $KEY_FILE ${MASTER_URL}/)
  if [ "$response_code" == "200" ];then
     break
  fi
done
if [ "$response_code" != "200" ];then
   echo "[Fatal]: GET ${MASTER_URL} ERROR,Please check!"
   exit 200
fi
IFS=',' read -a all_dc_info_list <<< $dc_info_mapping
for dc_info in ${all_dc_info_list[@]};do
   dc_info_context=$(Get_dc_info $dc_info)
   dc_info_list=($dc_info_context)
   if [ ${#dc_info_list[@]} != "3" ];then
       echo "${dc_info_list[@]} format error,skip scaler"
       continue
   else
       namespace=${dc_info_list[0]}
       dc_name=${dc_info_list[1]}
       scale_pod_num=${dc_info_list[2]}
       dc_file_path=/tmp/${dc_name}.dc.info.json
       i=0
       while (( i++ < retry_times ));do
       response_code=$(Request_ose_api $CA_FILE $CERT_FILE $KEY_FILE $MASTER_URL $namespace GET $dc_name $dc_file_path)
       if [ "$response_code" != "200" ];then
          continue
       fi
       Change_dc_replicas $scale_pod_num $dc_file_path
       response_code=$(Request_ose_api $CA_FILE $CERT_FILE $KEY_FILE $MASTER_URL $namespace PUT $dc_name $dc_file_path)
       if [ "$response_code" == "200" ];then
          break
       fi
       done
       if [ "$response_code" != "200" ];then
          echo "[Error]: scale ${dc_name} failed,http code:${response_code}."
       fi
   fi
done




