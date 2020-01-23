# Install kubectl on Flow agent

# Login into flow-bound-agent pod

apt-get update

# Get basic unix tools
apt-get -y install curl
apt-get -y install vim
apt-get -y install git

# Install kubectl
apt-get install -y apt-transport-https
apt-get install -y gnupg
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg |  apt-key add -
echo "deb https://apt.kubernetes.io/ kubernetes-xenial main" |  tee -a /etc/apt/sources.list.d/kubernetes.list
apt-get update
apt-get install -y kubectl

# Install python3 needed for gcloud
apt-get -y install python3
apt-get -y install python3-pip

# Install gcloud
apt-get install apt-transport-https ca-certificates gnupg
curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key --keyring /usr/share/keyrings/cloud.google.gpg add -
curl https://sdk.cloud.google.com > gcloud_install.sh
bash gcloud_install.sh --disable-prompts --install-dir=/usr/lib

# Configure kubectl
su - cbflow
echo 'export PATH=$PATH:/opt/google-cloud-sdk/bin' >> ~/.bashrc
source ~/.bashrc
mkdir .kube && cd .kube
cat << EOF > config
apiVersion: v1
clusters:
- cluster:
    certificate-authority-data: LS0tLS1CRUdJTiBDRVJUSUZJQ0FURS0tLS0tCk1JSURERENDQWZTZ0F3SUJBZ0lSQUs0YjdGOUVybzVNUk9wNlpyNFB0RVl3RFFZSktvWklodmNOQVFFTEJRQXcKTHpFdE1Dc0dBMVVFQXhNa1lUYzBZV1JtWXpVdE1HRTVZUzAwTkdabUxXSTRaVGt0TXpVek5XUmtOek5pTjJRMwpNQjRYRFRJd01ERXdPVEl3TVRRMU5sb1hEVEkxTURFd056SXhNVFExTmxvd0x6RXRNQ3NHQTFVRUF4TWtZVGMwCllXUm1ZelV0TUdFNVlTMDBOR1ptTFdJNFpUa3RNelV6TldSa056TmlOMlEzTUlJQklqQU5CZ2txaGtpRzl3MEIKQVFFRkFBT0NBUThBTUlJQkNnS0NBUUVBMjVSQWFrQmlWTzVqN2MwRklnNmNaQzVobVljSjdLUEhvVEV6bW84aQo4TFB5WGNnbGthZHB6WUNhV1V0OGFXZ0YzYWpTSk1kVXRuRStrZEo3UG4zYzRuZFl5Y1pvUmxLaDlOQ2ZqMEdyClg0b2RvZEV4TUVPWm9rTnlIL3VSMXRSRU4vRit6NlNZZFhMZlVkMTZEdnhPdTJ2TVZXZjdBVG8yQlpBTXVsS00KMEFUekhoenhKN3EySzlTTVU3MmxGSFB1eFBRM3NTKzQxbGV0TGxLUmFNRW5sUS9jb0JDUXAwSXFwNitOdnc3eApsTGNCUEVaUkFQRHljaGV6NTNUMEVXeFREUEErelJSVENUa0lTK2hVTDIvRmMvZTg5Y041RnkzUUxicEUyajM5CkVqanhZUjcwTHZKd0J2ZndCVW5WdEdicFowZ1doWmNmeFZEYjA1SmQxL21OZHdJREFRQUJveU13SVRBT0JnTlYKSFE4QkFmOEVCQU1DQWdRd0R3WURWUjBUQVFIL0JBVXdBd0VCL3pBTkJna3Foa2lHOXcwQkFRc0ZBQU9DQVFFQQpCVCt2dzJrWVFQeVBNRXVQcWM5MnJDVCthSnZoSHgxcmtQWTZVYkRCM250ZCt0TzBqM2k1Q2F2TVo4R1I3SUUzCmZyNUJEOTd6Uzc5bDhValB0eWRoaU5HZDMwTnV4WjhPQUJpZDd1QVRMb0VpM01wK1I3SFBIcWJTUmtFSGx6b28KVy9JbWlpTlB2eXdHUWxIWGVFangvek9xN1hMRDYybDZmY0ptczQvUVZwaDVnMnAyd1FuckxMRzhCTVdBdE9RYgplZDhidHhIMkN5Z0hKbzY4N2VKUlM1S1JiT0lubW4vcFM0V1pvMDcvc1ZqSzNxeGhVSm5lRVdEQlFxSndhYzM2CkF2NytEM0w3Qy9laWZZUFkreXhHNDI5VGpJbzlTOWF2Nkw0SDBKNGNPbmhKbmdrWGptR1F0UGhxa2hnUkFlaE0KK3JCamhYdmhtRG1leW1Ma1YzTGtEdz09Ci0tLS0tRU5EIENFUlRJRklDQVRFLS0tLS0K
    server: https://34.73.59.153
  name: gke_core-flow-research_us-east1-b_zero-point-one
contexts:
- context:
    cluster: gke_core-flow-research_us-east1-b_zero-point-one
    namespace: dev
    user: gke_core-flow-research_us-east1-b_zero-point-one
  name: dev
- context:
    cluster: gke_core-flow-research_us-east1-b_zero-point-one
    namespace: preprod
    user: gke_core-flow-research_us-east1-b_zero-point-one
  name: preprod
- context:
    cluster: gke_core-flow-research_us-east1-b_zero-point-one
    namespace: qa
    user: gke_core-flow-research_us-east1-b_zero-point-one
  name: qa
current-context: qa
kind: Config
preferences: {}
users:
- name: gke_core-flow-research_us-east1-b_zero-point-one
  user:
    auth-provider:
      config:
        access-token: ya29.Ime6By8hNLrQKFm10lcWwiSOtOqFyweQwM9kWuqa5PNQ57xJ8b4lioVYMo5OXXrqDkskzdv5Hy-crKahWRcQwUr0amv_SUIShhlxSOzRi62U7yz6Ve0d0O1kKJ6VtAX68giVFwzGf--w
        cmd-args: config config-helper --format=json
        cmd-path: /opt/google-cloud-sdk/bin/gcloud
        expiry: "2020-01-21T20:48:06Z"
        expiry-key: '{.credential.token_expiry}'
        token-key: '{.credential.access_token}'
      name: gcp
EOF
# 

gcloud auth login
# Some manual stuff

# create qa and preprod contexts
kubectl create namespace dev
kubectl create namespace qa
kubectl create namespace preprod
