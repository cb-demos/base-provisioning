#!/bin/bash

echo '----> Provisioning cluster '$1'-core in region '$2'.'

# provision a GKE cluster
gcloud container clusters create $1-core \
--cluster-version=1.13.12-gke.8 \
--issue-client-certificate \
--machine-type=n1-standard-8 \
--num-nodes=1 \
--password=cloudbeesdemoenv \
--region=$2 \
--username=admin \
--verbosity=none

# with the cluster provisioned, get its credentials and set up kubectl
# probably need to change the project name. not sure if it should be a parameter.
echo '----> Setting up kubectl'
gcloud container clusters get-credentials $1-core --zone $2 

# Create the Core namespace
kubectl create namespace cloudbees-core
kubectl config set-context --current --namespace cloudbees-core

# set up tiller so we can use Helm
echo '----> Setting up Tiller'
kubectl -n kube-system create serviceaccount tiller

kubectl create clusterrolebinding tiller \
  --clusterrole=cluster-admin \
  --serviceaccount=kube-system:tiller

# kubectl rollout status deployment tiller-deploy --namespace kube-system 
sleep 120

echo '----> Initializing Helm'
helm init --service-account tiller
helm repo add cloudbees https://charts.cloudbees.com/public/cloudbees
helm repo update

sleep 120

# Now install the nginx ingress controller
echo '----> Installing the nginx-ingress controller'

helm install \
--wait \
--name nginx-ingress \
stable/nginx-ingress

sleep 60

INGRESS_URL=$(kubectl get svc | grep nginx-ingress-controller | awk '{print $4}').nip.io

# Now install Core with the Helm chart
echo '----> Installing Core with the Helm chart'
helm install \
--wait \
--set OperationsCenter.HostName=$(echo $INGRESS_URL) \
--set nginx-ingress.Enabled=false \
--set OperationsCenter.ServiceType='ClusterIP' \
--name core \
cloudbees/cloudbees-core

# kubectl rollout status deployment cloudbees-core

# Get the initialAdminPassword from the Core instance
kubectl rollout status sts cjoc 
CORE_PASSWORD=$(kubectl exec cjoc-0 -- sh -c "until cat /var/jenkins_home/secrets/initialAdminPassword 2>&-; do sleep 5; done")

# echo '----> Waiting to install Flow'
# sleep 120

# ===================================================================================
# Provisioning the Flow cluster
# ===================================================================================

echo '----> Provisioning cluster '$1'-flow in region '$2'.'

# provision a GKE cluster
gcloud container clusters create $1-flow \
--cluster-version=1.13.12-gke.8 \
--issue-client-certificate \
--machine-type=n1-standard-8 \
--num-nodes=1 \
--password=cloudbeesdemoenv \
--region=$2 \
--username=admin \
--verbosity=none

# with the cluster provisioned, get its credentials and set up kubectl
# probably need to change the project name. not sure if it should be a parameter.
echo '----> Setting up kubectl'
gcloud container clusters get-credentials $1-flow --zone $2 

# Create the Flow namespace 
echo '----> Creating the flow namespace and making it the default'
kubectl create namespace flow 
kubectl config set-context --current --namespace=flow

# set up tiller so we can use Helm to install Flow
echo '----> Setting up Tiller'
kubectl -n kube-system create serviceaccount tiller

kubectl create clusterrolebinding tiller \
  --clusterrole=cluster-admin \
  --serviceaccount=kube-system:tiller

sleep 60

echo '----> Reinitializing Helm for the new cluster'
helm init --service-account tiller
helm repo add cloudbees https://charts.cloudbees.com/public/cloudbees
helm repo update

sleep 120

# Now install Flow with the Helm chart
echo '----> Installing Flow with the Helm chart'
helm install \
--wait \
-f https://raw.githubusercontent.com/cloudbees/cloudbees-examples/master/flow-on-kubernetes/cloudbees-flow-demo.yaml \
--dep-up \
--name cloudbees-flow \
--timeout 10000 \
cloudbees/cloudbees-flow

FLOW_SERVER_POD=$(kubectl get pods | grep flow-server | awk '{print $1}')

# Can't figure out how to tell when Flow is finished initializing. I'm sure
# there's a way, but sleep 600 and some patience does the job. 
echo '----> Waiting for Flow to initialize itself'
sleep 15
echo '----> You might want to grab a beverage now.'
sleep 585 

# This, or something like it, should do the job, but I haven't figured it out yet. 
# Probably due to my lack of bash scripting expertise. 
# SERVER_STATE=$(kubectl exec $FLOW_SERVER_POD -- ectool getServerStatus | xmlstarlet sel -t -v '/response/serverStatus/serverState')
# until ($SERVER_STATE = 'running'); do 
#   SERVER_STATE=$(kubectl exec $FLOW_SERVER_POD -- ectool getServerStatus | xmlstarlet sel -t -v '/response/serverStatus/serverState');
# done

# first, get the pod name and copy all of the setup files to it
# wildcard copy wasn't added until K8s 1.14. the current GKE default 
# is 1.13.12, so we've got all of these clumsy kubectl cp commands.
echo '----> Copying files'
# echo '----> $FLOW_SERVER_POD='$FLOW_SERVER_POD

# set up the Flow workshop
# I disabled the cp and exec commands for now because the exercises don't 
# work (probably some missing components in the Flow cluster). 

# kubectl cp deploy/administration_catalog.dsl $FLOW_SERVER_POD:/home/cbflow/
# kubectl cp deploy/administration_project.dsl $FLOW_SERVER_POD:/home/cbflow/
# kubectl cp deploy/artifacts.groovy $FLOW_SERVER_POD:/home/cbflow/
# kubectl cp deploy/awsvpc.groovy $FLOW_SERVER_POD:/home/cbflow/
# kubectl cp deploy/catalog_application.groovy $FLOW_SERVER_POD:/home/cbflow/
# kubectl cp deploy/catalog_pipeline.groovy $FLOW_SERVER_POD:/home/cbflow/
# kubectl cp deploy/catalog_release.groovy $FLOW_SERVER_POD:/home/cbflow/
# kubectl cp deploy/cloudbees-flow-demo.yaml $FLOW_SERVER_POD:/home/cbflow/
# kubectl cp deploy/dynamicEnvironment.groovy $FLOW_SERVER_POD:/home/cbflow/
# kubectl cp deploy/EF-14.groovy $FLOW_SERVER_POD:/home/cbflow/
# kubectl cp deploy/EF-14_solutions.groovy $FLOW_SERVER_POD:/home/cbflow/
# kubectl cp deploy/EF-29.groovy $FLOW_SERVER_POD:/home/cbflow/
# kubectl cp deploy/environment.prop $FLOW_SERVER_POD:/home/cbflow/
# kubectl cp deploy/Feature\ release\ template_10-28-2019_12-13-20.groovy $FLOW_SERVER_POD:/home/cbflow/
# kubectl cp deploy/setup.groovy $FLOW_SERVER_POD:/home/cbflow/
# kubectl cp deploy/setup.sh $FLOW_SERVER_POD:/home/cbflow/
# kubectl cp deploy/setup_Cloudbees.groovy $FLOW_SERVER_POD:/home/cbflow/
# kubectl cp deploy/setup_JWDW.groovy $FLOW_SERVER_POD:/home/cbflow/
# kubectl cp deploy/Training.dsl $FLOW_SERVER_POD:/home/cbflow/
# kubectl cp deploy/teardown.groovy $FLOW_SERVER_POD:/home/cbflow/

# Now install the artifact files
# echo '----> Copying the artifact files'
# kubectl exec $FLOW_SERVER_POD -- mkdir -p /home/cbflow/artifacts/com.ec/userportal
# kubectl exec $FLOW_SERVER_POD -- mkdir -p /home/cbflow/artifacts/com.ec/userportal/1.0.0
# kubectl cp ./artifacts/com.ec/userportal/1.0.0/artifact.tar.gz \
#   $FLOW_SERVER_POD:/home/cbflow/artifacts/com.ec/userportal/1.0.0/
# kubectl cp ./artifacts/com.ec/userportal/1.0.0/manifest \
#   $FLOW_SERVER_POD:/home/cbflow/artifacts/com.ec/userportal/1.0.0/

# kubectl exec $FLOW_SERVER_POD -- mkdir -p /home/cbflow/artifacts/com.ec/userportal/2.0.0
# kubectl cp ./artifacts/com.ec/userportal/2.0.0/artifact.tar.gz \
#   $FLOW_SERVER_POD:/home/cbflow/artifacts/com.ec/userportal/2.0.0/
# kubectl cp ./artifacts/com.ec/userportal/2.0.0/manifest \
#   $FLOW_SERVER_POD:/home/cbflow/artifacts/com.ec/userportal/2.0.0/

# kubectl exec $FLOW_SERVER_POD -- mkdir -p /home/cbflow/artifacts/com.ec/userportal/3.0.0
# kubectl cp ./artifacts/com.ec/userportal/3.0.0/artifact.tar.gz \
#   $FLOW_SERVER_POD:/home/cbflow/artifacts/com.ec/userportal/3.0.0/
# kubectl cp ./artifacts/com.ec/userportal/3.0.0/manifest \
#   $FLOW_SERVER_POD:/home/cbflow/artifacts/com.ec/userportal/3.0.0/

# kubectl exec $FLOW_SERVER_POD -- mkdir -p /home/cbflow/artifacts/com.ec/userportal_schema/1.0.0
# kubectl cp ./artifacts/com.ec/userportal_schema/1.0.0/artifact.tar.gz \
#   $FLOW_SERVER_POD:/home/cbflow/artifacts/com.ec/userportal_schema/1.0.0/
# kubectl cp ./artifacts/com.ec/userportal_schema/1.0.0/manifest \
#   $FLOW_SERVER_POD:/home/cbflow/artifacts/com.ec/userportal_schema/1.0.0/

# kubectl exec $FLOW_SERVER_POD -- mkdir -p /home/cbflow/artifacts/com.ec/userportal_schema/2.0.0
# kubectl cp ./artifacts/com.ec/userportal_schema/2.0.0/artifact.tar.gz \
#   $FLOW_SERVER_POD:/home/cbflow/artifacts/com.ec/userportal_schema/2.0.0/
# kubectl cp ./artifacts/com.ec/userportal_schema/2.0.0/manifest \
#   $FLOW_SERVER_POD:/home/cbflow/artifacts/com.ec/userportal_schema/2.0.0/

# kubectl exec $FLOW_SERVER_POD -- mkdir -p /home/cbflow/artifacts/com.ec/userportal_schema/3.0.0
# kubectl cp ./artifacts/com.ec/userportal_schema/3.0.0/artifact.tar.gz \
#   $FLOW_SERVER_POD:/home/cbflow/artifacts/com.ec/userportal_schema/3.0.0/
# kubectl cp ./artifacts/com.ec/userportal_schema/3.0.0/manifest \
#   $FLOW_SERVER_POD:/home/cbflow/artifacts/com.ec/userportal_schema/3.0.0/

# Delete old Artifact Repository directory
# echo '----> Deleting old artifacts'
# kubectl exec $FLOW_SERVER_POD -- rm -rf /opt/electriccloud/electriccommander/repository-data

# Create Users and resourcePools
echo '----> Adding users to Flow'
kubectl exec $FLOW_SERVER_POD -- groupadd flow
kubectl exec $FLOW_SERVER_POD -- useradd -g flow flow

# echo '----> Invoking ectool to set up the Flow workshop'
# kubectl exec $FLOW_SERVER_POD -- ectool evalDsl --dslFile /home/cbflow/setup.groovy
# kubectl exec $FLOW_SERVER_POD -- ectool --silent setProperty /server/unplug/v1 --valueFile /home/cbflow/environment.prop

# delete old artifacts and create new ones
# kubectl exec $FLOW_SERVER_POD -- ectool evalDsl --dslFile /home/cbflow/artifacts.groovy

# Create New artifacts
#     com.ec:userportal
#     com.ec:userportal_schema
# echo '----> Creating new artifacts'
# kubectl exec $FLOW_SERVER_POD -- mkdir -p /opt/electriccloud/electriccommander/repository-data/com.ec/userportal/1.0.0
# kubectl cp ./artifacts/com.ec/userportal/1.0.0/artifact.tar.gz \
#   $FLOW_SERVER_POD:/opt/electriccloud/electriccommander/repository-data/com.ec/userportal/1.0.0
# kubectl cp ./artifacts/com.ec/userportal/1.0.0/manifest \
#   $FLOW_SERVER_POD:/opt/electriccloud/electriccommander/repository-data/com.ec/userportal/1.0.0

# kubectl exec $FLOW_SERVER_POD -- mkdir -p /opt/electriccloud/electriccommander/repository-data/com.ec/userportal/2.0.0
# kubectl cp ./artifacts/com.ec/userportal/1.0.0/artifact.tar.gz \
#   $FLOW_SERVER_POD:/opt/electriccloud/electriccommander/repository-data/com.ec/userportal/2.0.0
# kubectl cp ./artifacts/com.ec/userportal/1.0.0/manifest \
#   $FLOW_SERVER_POD:/opt/electriccloud/electriccommander/repository-data/com.ec/userportal/2.0.0

# kubectl exec $FLOW_SERVER_POD -- mkdir -p /opt/electriccloud/electriccommander/repository-data/com.ec/userportal/3.0.0
# kubectl cp ./artifacts/com.ec/userportal/1.0.0/artifact.tar.gz \
#   $FLOW_SERVER_POD:/opt/electriccloud/electriccommander/repository-data/com.ec/userportal/3.0.0
# kubectl cp ./artifacts/com.ec/userportal/1.0.0/manifest \
#   $FLOW_SERVER_POD:/opt/electriccloud/electriccommander/repository-data/com.ec/userportal/3.0.0

# kubectl exec $FLOW_SERVER_POD -- mkdir -p /opt/electriccloud/electriccommander/repository-data/com.ec/userportal_schema/1.0.0
# kubectl cp ./artifacts/com.ec/userportal/1.0.0/artifact.tar.gz \
#   $FLOW_SERVER_POD:/opt/electriccloud/electriccommander/repository-data/com.ec/userportal_schema/1.0.0
# kubectl cp ./artifacts/com.ec/userportal/1.0.0/manifest \
#   $FLOW_SERVER_POD:/opt/electriccloud/electriccommander/repository-data/com.ec/userportal_schema/1.0.0

# kubectl exec $FLOW_SERVER_POD -- mkdir -p /opt/electriccloud/electriccommander/repository-data/com.ec/userportal_schema/2.0.0
# kubectl cp ./artifacts/com.ec/userportal/1.0.0/artifact.tar.gz \
#   $FLOW_SERVER_POD:/opt/electriccloud/electriccommander/repository-data/com.ec/userportal_schema/2.0.0
# kubectl cp ./artifacts/com.ec/userportal/1.0.0/manifest \
#   $FLOW_SERVER_POD:/opt/electriccloud/electriccommander/repository-data/com.ec/userportal_schema/2.0.0

# kubectl exec $FLOW_SERVER_POD -- mkdir -p /opt/electriccloud/electriccommander/repository-data/com.ec/userportal_schema/3.0.0
# kubectl cp ./artifacts/com.ec/userportal/1.0.0/artifact.tar.gz \
#   $FLOW_SERVER_POD:/opt/electriccloud/electriccommander/repository-data/com.ec/userportal_schema/3.0.0
# kubectl cp ./artifacts/com.ec/userportal/1.0.0/manifest \
#   $FLOW_SERVER_POD:/opt/electriccloud/electriccommander/repository-data/com.ec/userportal_schema/3.0.0

# kubectl exec $FLOW_SERVER_POD -- chown -R flow.flow /opt/electriccloud/electriccommander/repository-data/

# Load DSL for EF-14
# echo '----> Creating the artifacts in Flow'
# kubectl exec $FLOW_SERVER_POD -- ectool evalDsl --dslFile /home/cbflow/EF-14.groovy
# kubectl exec $FLOW_SERVER_POD -- ectool evalDsl --dslFile /home/cbflow/EF-14_solutions.groovy

# Load DSL for EF-29 Dashboard
# kubectl exec $FLOW_SERVER_POD -- ectool evalDsl --dslFile /home/cbflow/Training.dsl
# kubectl exec $FLOW_SERVER_POD -- ectool evalDsl --dslFile /home/cbflow/EF-29.groovy

# Catalog items
# echo '----> Creating the catalog items'
# kubectl exec $FLOW_SERVER_POD -- ectool evalDsl --dslFile /home/cbflow/catalog_application.groovy
# kubectl exec $FLOW_SERVER_POD -- ectool evalDsl --dslFile /home/cbflow/catalog_pipeline.groovy
# kubectl exec $FLOW_SERVER_POD -- ectool evalDsl --dslFile /home/cbflow/catalog_release.groovy

# Copy a file to the Flow web server: 
# FLOW_WEB=$(kubectl get pods --namespace flow | grep flow-web | awk '{print $1}')
# kubectl cp ../../Flow\ experiments/Flow\ Workshop\ 20190813.pdf $FLOW_WEB:/opt/cbflow/apache/htdocs
# open https://$FLOW_URL/Flow%20Workshop%2020190813.pdf

echo '----> Setting up the data for the Release Command Center demo '
kubectl cp BeeZone_project.dsl $FLOW_SERVER_POD:/home/cbflow
kubectl exec $FLOW_SERVER_POD -- ectool evalDsl --dslFile /home/cbflow/BeeZone_project.dsl

kubectl cp BeeZone_demo.dsl $FLOW_SERVER_POD:/home/cbflow
kubectl exec $FLOW_SERVER_POD -- ectool evalDsl --dslFile /home/cbflow/BeeZone_demo.dsl

kubectl cp BeeZone.json $FLOW_SERVER_POD:/home/cbflow
kubectl cp rccContent.dsl $FLOW_SERVER_POD:/home/cbflow
kubectl exec $FLOW_SERVER_POD -- ectool evalDsl --dslFile /home/cbflow/rccContent.dsl \
  --parametersFile /home/cbflow/BeeZone.json

kubectl cp RetrieveArtifactFromTask.groovy $FLOW_SERVER_POD:/home/cbflow
kubectl exec $FLOW_SERVER_POD \
  -- ectool evalDsl --dslFile /home/cbflow/RetrieveArtifactFromTask.groovy

sleep 120

FLOW_URL=$(kubectl get svc | grep nginx-ingress-controller | awk '{print $4}')

echo '------------------------------------------------------------------'
echo '----> Two Kuberenetes clusters have been provisioned, one with '
echo '      Core ('$1'-core) and one with Flow ('$1'-flow). '
echo '------------------------------------------------------------------'
echo '----> Using Core: '
echo '      Your initial password is '$CORE_PASSWORD
echo '      Visit https://'$INGRESS_URL'/cjoc to log in.'
echo '------------------------------------------------------------------'
echo '----> Using Flow: '
echo '      Your username and password are admin / changeme'
echo '      Visit https://'$FLOW_URL'/auth/# to log in.'
echo '------------------------------------------------------------------'
# echo '----> The login pages for the two products will open in 15 '
# cho '      seconds in your browser.'
# echo '------------------------------------------------------------------'

# sleep 15

# open https://$INGRESS_URL/cjoc 
# open https://$FLOW_URL/auth/\#
