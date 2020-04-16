# ---------------------------------------------------------------------------------------------------------------------------------------------------"
# ---------------------------------------------------------------------------------------------------------------------------------------------------"
# ---------------------------------------------------------------------------------------------------------------------------------------------------"
# Install Kubernetes Monitoring
#
# V1.0 
#
# ©2020 nikh@ch.ibm.com
# ---------------------------------------------------------------------------------------------------------------------------------------------------"
# ---------------------------------------------------------------------------------------------------------------------------------------------------"
# ---------------------------------------------------------------------------------------------------------------------------------------------------"
# ---------------------------------------------------------------------------------------------------------------------------------------------------"

source ./0_variables.sh


# ---------------------------------------------------------------------------------------------------------------------------------------------------"
# ---------------------------------------------------------------------------------------------------------------------------------------------------"
# Do Not Edit Below
# ---------------------------------------------------------------------------------------------------------------------------------------------------"
# ---------------------------------------------------------------------------------------------------------------------------------------------------"
echo "${GREEN}***************************************************************************************************************************************************${NC}"
echo "${GREEN}***************************************************************************************************************************************************${NC}"
echo "${GREEN}***************************************************************************************************************************************************${NC}"
echo "  "
echo " ${CYAN}  Register Kubernetes Monitoring for OpenShift 4.3${NC}"
echo "  "
echo "${GREEN}***************************************************************************************************************************************************${NC}"
echo "${GREEN}***************************************************************************************************************************************************${NC}"
echo "${GREEN}***************************************************************************************************************************************************${NC}"
echo "  "
echo "  "
echo "  "



# ------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# ------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# GET PARAMETERS
# ------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# ------------------------------------------------------------------------------------------------------------------------------------------------------------------------
echo "---------------------------------------------------------------------------------------------------------------------------"
echo "---------------------------------------------------------------------------------------------------------------------------"
echo " ${PURPLE}Input Parameters${NC}"
echo "---------------------------------------------------------------------------------------------------------------------------"



        while getopts "d:n:f:" opt
        do
          case "$opt" in
              d ) INPUT_DOCKER_DOMAIN="$OPTARG" ;;
              n ) INPUT_IMPORT_NAME="$OPTARG" ;;
              f ) INPUT_CONFIG="$OPTARG" ;;
          esac
        done


        if [[ $INPUT_DOCKER_DOMAIN == "" ]];
        then
            echo "    ${RED}ERROR${NC}: Please provide the Docker Hub Domain"
            echo "    USAGE: $0 -d <DOCKER_DOMAIN>  -n <CLUSTER_IMPORT_NAME> -f <CONFIGURATION_FILE>  "
            exit 1
        else
          echo "    ${GREEN}Docker Hub Domain OK:${NC}                $INPUT_DOCKER_DOMAIN"
          K8M_DOMAIN=$INPUT_DOCKER_DOMAIN
        fi


        if [[ $INPUT_CONFIG == "" ]];
        then
            echo "    ${RED}ERROR${NC}: Please provide the ibm-cloud-apm-dc-configpack.tar file"
            echo "    USAGE: $0 -d <DOCKER_DOMAIN>  -n <CLUSTER_IMPORT_NAME> -f <CONFIGURATION_FILE>   "
            exit 1
        else
          echo "    ${GREEN}Config File OK:${NC}                      $INPUT_CONFIG"
          K8M_CONFIG=$INPUT_CONFIG
        fi



        if [[ $INPUT_IMPORT_NAME == "" ]];
        then
            echo "    ${RED}ERROR${NC}: Please provide the Import Name"
            echo "    USAGE: $0 -d <DOCKER_DOMAIN>  -n <CLUSTER_IMPORT_NAME> -f <CONFIGURATION_FILE>   "
            exit 1
        else
          echo "    ${GREEN}Import Name OK:${NC}                     '$INPUT_IMPORT_NAME'"
          K8M_IMPORT_NAME=$INPUT_IMPORT_NAME
        fi


     


echo "---------------------------------------------------------------------------------------------------------------------------"
echo "---------------------------------------------------------------------------------------------------------------------------"
echo "  "
echo "  "
echo "  "
echo "  "




# ------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# ------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# PRE-INSTALL CHECKS
# ------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# ------------------------------------------------------------------------------------------------------------------------------------------------------------------------
echo "----------------------------------------------------------------------------------------------------------------------------------------------------"
echo "----------------------------------------------------------------------------------------------------------------------------------------------------"
echo " ${PURPLE}Pre-Install Checks${NC}"
echo "----------------------------------------------------------------------------------------------------------------------------------------------------"
echo "----------------------------------------------------------------------------------------------------------------------------------------------------"

        checkOpenshiftReachable

        #checkHelmChartInstalled "icam-kubernetes-resources"

        echo "    Check if ${CYAN}$K8M_CONFIG${NC} exists"
        if test -f "$K8M_CONFIG"; then
            echo "    ${GREEN}  OK${NC}"
        else 
            echo "    ${RED}  ERROR${NC}: ${ORANGE}ibm-cloud-apm-dc-configpack.tar${NC} does not exist in your Path"
            echo "           ${RED}Aborting.${NC}"
            exit 1
        fi

echo "---------------------------------------------------------------------------------------------------------------------------"
echo "---------------------------------------------------------------------------------------------------------------------------"
echo "  "
echo "  "
echo "  "
echo "  "



# ---------------------------------------------------------------------------------------------------------------------------------------------------"
# ---------------------------------------------------------------------------------------------------------------------------------------------------"
# Define some Stuff
# ---------------------------------------------------------------------------------------------------------------------------------------------------"
# ---------------------------------------------------------------------------------------------------------------------------------------------------"
echo "---------------------------------------------------------------------------------------------------------------------------"
echo "---------------------------------------------------------------------------------------------------------------------------"
echo " ${PURPLE}Define some Stuff${NC}"
echo "---------------------------------------------------------------------------------------------------------------------------"
echo "----------------------------------------------------------------------------------------------------------------------------------------------------"

        getClusterFQDN

echo "---------------------------------------------------------------------------------------------------------------------------"
echo "---------------------------------------------------------------------------------------------------------------------------"
echo "  "
echo "  "
echo "  "
echo "  "




# ------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# ------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# CONFIG SUMMARY
# ------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# ------------------------------------------------------------------------------------------------------------------------------------------------------------------------
echo "${GREEN}----------------------------------------------------------------------------------------------------------------------------------------------------${NC}"
echo "${GREEN}----------------------------------------------------------------------------------------------------------------------------------------------------${NC}"
echo "${GREEN}----------------------------------------------------------------------------------------------------------------------------------------------------${NC}"
echo " ${GREEN}  Cluster ${ORANGE}'$CLUSTER_NAME'${NC} will be registered with the Monitoring Module (APM)"
echo "----------------------------------------------------------------------------------------------------------------------------------------------------"
echo " ${BLUE}Your configuration${NC}"
echo "----------------------------------------------------------------------------------------------------------------------------------------------------"
echo "    ${GREEN}CLUSTER TO BE REGISTERED :${NC}   $CLUSTER_NAME"
echo "    ----------------------------------------------------------------------------------------------------------------------------------------------------"
echo "    ${GREEN}IMPORT NAME :${NC}                $K8M_IMPORT_NAME"
echo "    ----------------------------------------------------------------------------------------------------------------------------------------------------"
echo "    ${GREEN}Docker Domain for images:${NC}    $K8M_DOMAIN"
echo "    ${GREEN}Config File:${NC}                 $K8M_CONFIG"
echo "----------------------------------------------------------------------------------------------------------------------------------------------------"
echo "----------------------------------------------------------------------------------------------------------------------------------------------------"
echo "---------------------------------------------------------------------------------------------------------------------------"
echo "---------------------------------------------------------------------------------------------------------------------------"
echo "  "
echo "  "
echo "  "
echo "  "


echo "${GREEN}---------------------------------------------------------------------------------------------------------------------------${NC}"
echo "${GREEN}---------------------------------------------------------------------------------------------------------------------------${NC}"
echo "${RED}Continue Installation with these Parameters? [y,N]${NC}"
echo "${GREEN}---------------------------------------------------------------------------------------------------------------------------${NC}"
echo "${GREEN}---------------------------------------------------------------------------------------------------------------------------${NC}"
        read -p "[y,N]" DO_COMM
        if [[ $DO_COMM == "y" ||  $DO_COMM == "Y" ]]; then
          echo "${GREEN}Continue...${NC}"
        else
          echo "${RED}Installation Aborted${NC}"
          exit 2
        fi
echo "---------------------------------------------------------------------------------------------------------------------------"
echo "---------------------------------------------------------------------------------------------------------------------------"
echo "  "
echo "  "
echo "  "
echo "  "




# ------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# ------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# PREREQUISITES
# ------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# ------------------------------------------------------------------------------------------------------------------------------------------------------------------------
echo "---------------------------------------------------------------------------------------------------------------------------"
echo "---------------------------------------------------------------------------------------------------------------------------"
echo " ${CYAN}Running Prerequisites${NC}"
echo "---------------------------------------------------------------------------------------------------------------------------"
echo "---------------------------------------------------------------------------------------------------------------------------"

        echo "----------------------------------------------------------------------------------------------------------------------------------------------------"
        echo " ${wrench} Unpack ${CYAN}Configpack${NC}"
        cp $K8M_CONFIG ./tools/apm/ibm-cloud-apm-dc-configpack.tar 
        tar -xvf ./tools/apm/ibm-cloud-apm-dc-configpack.tar --directory ./tools/apm/

        echo "----------------------------------------------------------------------------------------------------------------------------------------------------"
        echo " ${wrench} Create ${CYAN}Cluster Roles${NC}"
        oc create clusterrolebinding icamklust-binding --clusterrole=cluster-admin \
        --serviceaccount=multicluster-endpoint:icamklust -n multicluster-endpoint

        oc create clusterrolebinding icamklust-binding_default --clusterrole=cluster-admin \
          --serviceaccount=multicluster-endpoint:default -n multicluster-endpoint
        oc adm policy add-cluster-role-to-user cluster-admin IAM#nikh@ch.ibm.com --as=system:admin

        echo "----------------------------------------------------------------------------------------------------------------------------------------------------"
        echo " ${wrench} Create ${CYAN}Secrets${NC}"
        kubectl -n multicluster-endpoint create -f ./tools/apm/ibm-cloud-apm-dc-configpack/dc-secret.yaml

        kubectl -n multicluster-endpoint create secret generic ibm-agent-https-secret --from-file=./tools/apm/ibm-cloud-apm-dc-configpack/keyfiles/cert.pem --from-file=./tools/apm/ibm-cloud-apm-dc-configpack/keyfiles/ca.pem --from-file=./tools/apm/ibm-cloud-apm-dc-configpack/keyfiles/key.pem


echo "---------------------------------------------------------------------------------------------------------------------------"
echo "---------------------------------------------------------------------------------------------------------------------------"
echo "  "
echo "  "
echo "  "
echo "  "




# ------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# ------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# INSTALL
# ------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# ------------------------------------------------------------------------------------------------------------------------------------------------------------------------
echo "---------------------------------------------------------------------------------------------------------------------------"
echo "---------------------------------------------------------------------------------------------------------------------------"
echo " ${ORANGE}Installing....${NC}"
echo ""
echo "---------------------------------------------------------------------------------------------------------------------------"
echo "---------------------------------------------------------------------------------------------------------------------------"


        kubectl apply -n multicluster-endpoint -f ./tools/apm/deploy/crds/k8sdc_crd.yaml
        kubectl apply -n multicluster-endpoint -f ./tools/apm/deploy/agentoperator.yaml
        kubectl apply -n multicluster-endpoint -f ./tools/apm/deploy/icam-reloader.yaml
        kubectl apply -n multicluster-endpoint -f ./tools/apm/deploy/operator.yaml
        kubectl apply -n multicluster-endpoint -f ./tools/apm/deploy/role.yaml
        kubectl apply -n multicluster-endpoint -f ./tools/apm/deploy/role_binding.yaml
        kubectl apply -n multicluster-endpoint -f ./tools/apm/deploy/service_account.yaml

        waitForPodsReady "multicluster-endpoint"


echo "${GREEN}----------------------------------------------------------------------------------------------------------------------------------------------------${NC}"
echo "${GREEN}----------------------------------------------------------------------------------------------------------------------------------------------------${NC}"
echo " ${GREEN} Cluster ${ORANGE}'$CLUSTER_NAME'${NC} registered with the Monitoring Module.... DONE${NC}"
echo "${GREEN}----------------------------------------------------------------------------------------------------------------------------------------------------${NC}"
echo "${GREEN}----------------------------------------------------------------------------------------------------------------------------------------------------${NC}"
echo "${GREEN}----------------------------------------------------------------------------------------------------------------------------------------------------${NC}"
echo " ${GREEN}To remove release: "
echo "${GREEN}----------------------------------------------------------------------------------------------------------------------------------------------------${NC}"
echo "${GREEN}***************************************************************************************************************************************************${NC}"
echo "${GREEN}***************************************************************************************************************************************************${NC}"


exit 1

# PUSH IMAGES (RUN ONCE)
docker login -u niklaushirt -p xxxx
ansible-playbook helm-main.yaml --extra-vars="cluster_name=mcm-hub release_name=icam-kubernetes-resources namespace=k8-monitor docker_group=niklaushirt tls_enabled=true docker_registry=docker.io" 
docker tag icam-k8-monitor:APM_202003092352 docker.io/niklaushirt/k8-monitor:APM_202003092352
docker push docker.io/niklaushirt/k8-monitor:APM_202003092352




oc create clusterrolebinding icamklust-binding --clusterrole=cluster-admin \
 --serviceaccount=multicluster-endpoint:icamklust -n multicluster-endpoint

 oc create clusterrolebinding icamklust-binding_default --clusterrole=cluster-admin \
   --serviceaccount=multicluster-endpoint:default -n multicluster-endpoint
oc adm policy add-cluster-role-to-user cluster-admin IAM#nikh@ch.ibm.com --as=system:admin


kubectl -n multicluster-endpoint create -f /Users/nhirt/ibm-cloud-apm-dc-configpack/dc-secret.yaml

kubectl -n multicluster-endpoint create secret generic ibm-agent-https-secret --from-file=/Users/nhirt/ibm-cloud-apm-dc-configpack/keyfiles/cert.pem --from-file=/Users/nhirt/ibm-cloud-apm-dc-configpack/keyfiles/ca.pem --from-file=/Users/nhirt/ibm-cloud-apm-dc-configpack/keyfiles/key.pem

kubectl apply -n multicluster-endpoint -f ./tools/apm/deploy/crds/k8sdc_crd.yaml
kubectl apply -n multicluster-endpoint -f ./tools/apm/deploy/agentoperator.yaml
kubectl apply -n multicluster-endpoint -f ./tools/apm/deploy/icam-reloader.yaml
kubectl apply -n multicluster-endpoint -f ./tools/apm/deploy/operator.yaml
kubectl apply -n multicluster-endpoint -f ./tools/apm/deploy/role.yaml
kubectl apply -n multicluster-endpoint -f ./tools/apm/deploy/role_binding.yaml
kubectl apply -n multicluster-endpoint -f ./tools/apm/deploy/service_account.yaml
kubectl apply -n multicluster-endpoint -f ./tools/apm/deploy/crds/k8sdc_cr.yaml

kubectl delete -n multicluster-endpoint -f ./tools/apm/deploy/crds/k8sdc_cr.yaml
kubectl delete -n multicluster-endpoint -f ./tools/apm/deploy/agentoperator.yaml
kubectl delete -n multicluster-endpoint -f ./tools/apm/deploy/icam-reloader.yaml
kubectl delete -n multicluster-endpoint -f ./tools/apm/deploy/operator.yaml
kubectl delete -n multicluster-endpoint -f ./tools/apm/deploy/role.yaml
kubectl delete -n multicluster-endpoint -f ./tools/apm/deploy/role_binding.yaml
kubectl delete -f ./tools/apm/deploy/service_account.yaml
kubectl delete -f ./tools/apm/deploy/crds/k8sdc_crd.yaml

oc delete secret dc-secret -n multicluster-endpoint
oc delete secret ibm-agent-https-secret -n multicluster-endpoint

oc delete clusterrolebinding icamklust-binding -n multicluster-endpoint
oc delete clusterrolebinding icamklust-binding_default -n multicluster-endpoint



