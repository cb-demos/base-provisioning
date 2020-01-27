#!/bin/bash

echo '----> Provisioning cluster '$1' in region '$2' in project '$3'.'

# provision a GKE cluster
gcloud beta container clusters create $1 \
--cluster-version=1.13.12-gke.8 \
--issue-client-certificate \
--machine-type=n1-standard-8 \
--num-nodes=1 \
--region=$2 \
--username=admin \
--verbosity=none \
--scopes=cloud-platform \
--identity-namespace=$3.svc.id.goog

# with the cluster provisioned, get its credentials and set up kubectl
# probably need to change the project name. not sure if it should be a parameter.
echo '----> Setting up kubectl'
gcloud container clusters get-credentials $1 --zone $2 --project $3

# set up tiller so we can use Helm
echo '----> Setting up Tiller'
kubectl -n kube-system create serviceaccount tiller

kubectl create clusterrolebinding tiller \
  --clusterrole=cluster-admin \
  --serviceaccount=kube-system:tiller

# kubectl rollout status deployment tiller-deploy --namespace kube-system 
# sleep 120

echo '----> Initializing Helm'
helm init --wait --service-account tiller
helm repo add cloudbees https://charts.cloudbees.com/public/cloudbees
helm repo update

# sleep 120

echo '----> Creating the nginx namespace'
kubectl create namespace nginx 
kubectl config set-context --current --namespace nginx

# Now install the nginx ingress controller
echo '----> Installing the nginx-ingress controller'

helm install \
--wait \
--name nginx-ingress \
stable/nginx-ingress

sleep 60

INGRESS_URL=$(kubectl get svc | grep nginx-ingress-controller | awk '{print $4}').nip.io

# Create the Core namespace
kubectl create namespace cloudbees-core
kubectl config set-context --current --namespace cloudbees-core

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

echo '----> Creating the nexus namespace'
kubectl create namespace nexus 
kubectl config set-context --current --namespace=nexus

echo '----> Installing Nexus via a YAML file'
kubectl apply -f doug-nexus.yaml

# echo '----> Installing Nexus with a Helm chart'
# helm install --name nexus --set nexus.service.type=LoadBalancer stable/sonatype-nexus

# echo '----> Creating the openldap namespace'
# kubectl create namespace openldap
# kubectl config set-context --current --namespace=openldap

# echo '----> Installing OpenLDAP with a Helm chart'
# helm install --name openldap --set service.type=LoadBalancer stable/openldap

# Create the Flow namespace 
echo '----> Creating the flow namespace'
kubectl create namespace flow 
kubectl config set-context --current --namespace=flow

# Create service account so gcloud commands can run
kubectl create serviceaccount gcloud-sa -n flow
gcloud iam service-accounts add-iam-policy-binding \
  --role roles/iam.workloadIdentityUser \
  --member "serviceAccount:$3.svc.id.goog[flow/gcloud-sa]" \
  gcloud-sa@$3.iam.gserviceaccount.com
kubectl annotate serviceaccount -n flow gcloud-sa \
  iam.gke.io/gcp-service-account=gcloud-sa@$3.iam.gserviceaccount.com
  
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

FLOW_SERVER_STATUS=$(kubectl exec $FLOW_SERVER_POD -- /opt/cbflow/health-check)
TARGET_STATUS="OK Server status: 'running'"

echo '----> Waiting for the Flow server to come online'
until [ "$FLOW_SERVER_STATUS" == "$TARGET_STATUS" ]; do 
  sleep 15;
  FLOW_SERVER_STATUS=$(kubectl exec $FLOW_SERVER_POD -- /opt/cbflow/health-check);
done

# Patching agent deployment
kubectl patch deployment flow-bound-agent -p "$(cat flowAgentPatch.yaml)"


# Create Users and resourcePools
echo '----> Adding users to Flow'
kubectl exec $FLOW_SERVER_POD -- groupadd flow
kubectl exec $FLOW_SERVER_POD -- useradd -g flow flow

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

# echo '------------------------------------------------------------------'
# echo '----> A Kuberenetes cluster has been provisioned. It contains '
# echo '      Core, Flow, and a sample application that uses Rollout.' 
echo '------------------------------------------------------------------'
echo '----> Using Core: '
echo '      Your initial password is '$CORE_PASSWORD
echo '      Visit https://'$INGRESS_URL'/cjoc to log in.'
echo '------------------------------------------------------------------'
echo '----> Using Flow: '
echo '      Your username and password are admin / changeme'
echo '      Visit https://'$FLOW_URL'/auth/# to log in.'
echo '------------------------------------------------------------------'
echo '----> Using Nexus: '
echo '      Your initial password is '$NEXUS_PASSWORD
echo '      Visit https://'$NEXUS_URL 'to log in.'
echo '------------------------------------------------------------------'
