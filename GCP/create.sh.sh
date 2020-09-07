#!/bin/bash

BASEDIR=$(cd $(dirname $0) && pwd)
source $BASEDIR/config.sh

# log封装
function echo_tips(){
    local what=$*
    echo -e "\e[1;33m${what}\e[0m" | tee -a $BASEDIR/gcloud.log
}
function echo_err(){
    local prefix="[Error][$(date +%FT%T)]"
    local what=$*
    echo -e "\e[1;31m${prefix}${what}\e[0m" | tee -a $BASEDIR/gcloud.log
}
function echo_warn(){
    local prefix="[Warn][$(date +%FT%T)]"
    local what=$*
    echo -e "\e[1;33m${prefix}${what}\e[0m" | tee -a $BASEDIR/gcloud.log
}
function echo_info(){
    local prefix="[Info][$(date +%FT%T)]"
    local what=$*
    echo -e "\e[1;32m${prefix}${what}\e[0m" | tee -a $BASEDIR/gcloud.log
}
function check(){
    if [ $? -eq 0 ];then
        local prefix="[Succ][$(date +%FT%T)]"
        local what=${FUNCNAME[1]}
        echo -e "\e[1;32m${prefix}${what}\e[0m" | tee -a $BASEDIR/gcloud.log
    else
        local prefix="[Fail][$(date +%FT%T)]"
        local what=${FUNCNAME[1]}
        echo -e "\e[1;31m${prefix}${what}\e[0m" | tee -a $BASEDIR/gcloud.log
    fi
}
function log(){
    local prefix="[Info][$(date +%FT%T)]Execute function: ${FUNCNAME[1]}"
    local what=$*
    echo -e "\e[1;32m${prefix}${what}\e[0m" | tee -a $BASEDIR/gcloud.log
}

###############################

# 1. 创建虚拟机模板
create_vm_template(){
    log
    gcloud beta compute instance-templates create $VM_TEMPLATE_NAME --machine-type=e2-highcpu-4 --subnet=projects/west-edge-tech-service-inc/regions/asia-southeast1/subnetworks/subnet-web-1 --no-address --can-ip-forward --maintenance-policy=MIGRATE --region=$REGION --tags=http-server --image=centos-7-v20200811 --image-project=centos-cloud --boot-disk-size=100GB --boot-disk-type=pd-standard --boot-disk-device-name=$VM_DISK_NAME --no-shielded-secure-boot --shielded-vtpm --shielded-integrity-monitoring --reservation-affinity=any --metadata=startup-script='#!/bin/bash
ln -sf /usr/share/zoneinfo/Asia/Singapore /etc/localtime
yum -y install nfs-utils wget nc telnet jq
systemctl enable rpcbind
systemctl start rpcbind
sed -i "/^SELINUX/{s/enforcing/disabled/}" /etc/selinux/config
[ -d  /web ] || mkdir /web
echo "/usr/bin/mount -t nfs 10.193.234.138:/vol1 /web" >> /etc/rc.local
tar xf /web/init/openresty.tgz -C /usr/local/
\cp -R /web/init/env.sh /etc/profile.d/
\cp -R /web/init/libGeoIP.so.1 /lib64/
\cp -R /web/init/vimrc /etc/vimrc
/bin/bash /web/init/init_sys.sh
/usr/local/openresty/nginx/sbin/nginx -t && /usr/local/openresty/nginx/sbin/nginx
systemctl disable firewalld
systemctl stop firewalld
/usr/sbin/setenforce 0
[ -d  /root/.ssh ] || mkdir /root/.ssh
echo "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDrb9X6hoscFJaYqjlGzqV42ZbSyYzwzsKtCPhXOBYBgmRZFHuJei7gkcDbX+8V8cXbc2Mez55s48BrqeN661sxnYduwND1YpN7cXsKvd3fjOX27Vr9iIEz/9yS5Eho/cl1Zd/OlHdVKyCa+tfohfpq4c7QcHlpuKoorzOQ1gXVy1xNAiuR0SuRZXTdGi/JDGQSSjX9/44176j6yE2+G84DVSiekzYPXnJPfn1h4/nLN8z+20v58TEHEWOcf2oQ3dlnV09Gw8fpGWrCAJhyx8Q+Gocg2IZr9wVE6XYGXz9ktLJvXAPY9oB87ZZ5qlfN6ubrLbtJ3Ogz3KyRYJ1FctbP root@gcp-sg-c-jump-001" >> /root/.ssh/authorized_keys
sed -i "/PermitRootLogin/{s/no/yes/}" /etc/ssh/sshd_config
systemctl reload sshd
'
    check
}

# 2. 根据模板创建实例组
create_vm_group(){
    log
    gcloud compute instance-groups managed create $VM_GROUP_NAME \
   --template=$VM_TEMPLATE_NAME --size=$VM_SIZE --zone=$ZONE
    check
}

# 3. 向实例组添加已命名端口
set_vm_group_port(){
    log
    gcloud compute instance-groups managed set-named-ports $VM_GROUP_NAME \
        --named-ports http:80 \
        --zone $ZONE
    check
}

# 4. 配置防火墙规则
create_fw_rule(){
    if [[ ! $(gcloud compute firewall-rules describe fw-allow-health-check 2>/dev/null) ]];then
        gcloud compute firewall-rules create fw-allow-health-check \
            --network=vpc-sg \
            --action=allow \
            --direction=ingress \
            --source-ranges=130.211.0.0/22,35.191.0.0/16 \
            --target-tags=allow-health-check \
            --rules=tcp
        check
    else
        echo_info "Check fw_rule already exist[ok]"
    fi
}

# 5. 预留外部 IP 地址
create_lb_ip(){
    log

    if [[ ! $(gcloud compute addresses describe $LB_IP_NAME --global 2>/dev/null) ]];then
        gcloud compute addresses create $LB_IP_NAME \
            --global
        check
    else
        echo_info "Check $LB_IP_NAME already exist[ok]"
    fi
    echo_info "LB 的 ip 地址如下："
    echo_tips $(gcloud compute addresses describe $LB_IP_NAME \
        --format="get(address)" \
        --global)

}

# 6. 设置负载平衡器
# 6.1 创建检查规则
create_health_check(){
    log
    if [[ ! $(gcloud compute health-checks describe $LB_HEALTH_CHECKS_NAME 2>/dev/null) ]];then
        gcloud compute health-checks create http http-basic-check --port 80
        check
    else
        echo_info "Check health-check already exist[ok]"
    fi
}

# 6.2 创建后端服务
create_backend_service(){
    log
    if [[ ! $(gcloud compute backend-services describe $LB_BACKEND_NAME --global 2>/dev/null) ]];then
        gcloud compute backend-services create $LB_BACKEND_NAME \
            --protocol=HTTP \
            --port-name=http \
            --health-checks=http-basic-check \
            --global
        check
    else
        echo_info "Check $LB_BACKEND_NAME already exist[ok]"
    fi

        #--region=$REGION
        # 这里是 GCP 的 bug，只支持 global
        # https://stackoverflow.com/questions/42975368/command-to-create-google-cloud-backend-service-fails-what-am-i-doing-wrong
}

# 6.3 实例组作为后端添加到后端服务
add_backend(){
    log
    if [[ ! $(gcloud compute backend-services list --filter="name=$LB_BACKEND_NAME" | grep $REGION 2>/dev/null) ]];then
        gcloud compute backend-services add-backend $LB_BACKEND_NAME \
            --instance-group=$VM_GROUP_NAME \
            --instance-group-zone=$ZONE \
            --global
        check
    else
        echo_info "Check add backend $LB_BACKEND_NAME already exist[ok]"
    fi
}

# 6.4 创建网址映射，将传入的请求路由到默认的后端服务
create_web_map(){
    log
    if [[ ! $(gcloud compute url-maps list --filter="name=$LB_WEB_MAP_NAME" | grep $LB_WEB_MAP_NAME  2>/dev/null) ]];then
        gcloud compute url-maps create $LB_WEB_MAP_NAME \
            --default-service $LB_BACKEND_NAME
        check
    else
        echo_info "Check create_web_map $LB_WEB_MAP_NAME already exist[ok]"
    fi
}

# 6.5 创建一个目标 HTTP 代理将请求路由到网址映射
create_lb_proxy(){
    log
    if [[ ! $(gcloud compute target-http-proxies list | grep -w $LB_PROXY_NAME 2>/dev/null) ]];then
        gcloud compute target-http-proxies create $LB_PROXY_NAME \
            --url-map $LB_WEB_MAP_NAME
        check
    else
        echo_info "Check create_lb_proxy $LB_PROXY_NAME already exist[ok]"
    fi
}

# 6.5 创建全局转发规则以将传入请求路由到代理
create_fwd_rule(){
    log
    if [[ ! $(gcloud compute forwarding-rules list | grep -w $LB_FWD_RULE 2>/dev/null) ]];then
        gcloud compute forwarding-rules create $LB_FWD_RULE \
            --address=$LB_IP_NAME \
            --target-http-proxy=$LB_PROXY_NAME \
            --ports=80 \
            --global
        check
    else
        echo_info "Check create_fwd_rule $LB_FWD_RULE already exist[ok]"
    fi
}

main(){
    create_vm_template
    create_vm_group
    set_vm_group_port
    create_fw_rule
    create_lb_ip
    create_health_check
    create_backend_service
    add_backend
    create_web_map
    create_lb_proxy
    create_fwd_rule
}

main