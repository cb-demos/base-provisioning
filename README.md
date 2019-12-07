# Thunder Demo deployment script

This is the depository for the shell scripts, tools, resources needed to provision a new 
demo environment. The script provisions two clusters in GKE, then installs Core in one and 
Flow in the other. With the products installed, it uses some DSL, Groovy, and JSON files
to initialize a project, release, and pipeline (as well as associated data) in Flow. 

## Feedback

Please send your feedback in any way you can, including PRs, Slack messages 
(our CloudBees Slack channel is `#project-thunder-demo`), comments on 
[our Confluence pages](https://cloudbees.atlassian.net/wiki/spaces/PMT/pages/1004046750/Demo+Ecosystem+-+Overview), 
or create a ticket on 
[our Jira board](https://cloudbees.atlassian.net/secure/RapidBoard.jspa?rapidView=459&projectKey=DECO).

## Prerequisites

If you're going to run this yourself, you need to have the 
[gcloud CLI tools](https://cloud.google.com/sdk/docs/quickstarts) installed. 
Once they're installed, run `gcloud auth login` to log in to your GCP account. 

You also need V2 of [Helm](https://v2.helm.sh) installed. The script handles the 
details of installing Tiller
and initializing Helm, but you have to install Helm itself before the script will work. 

## Beware!

This thing takes a while. At least 20 minutes. Part of that is the provisioning time
for the two clusters (I need to do those in parallel) and part of it is waiting for 
Flow to initialize (I need to figure ou thow to wait
until running `ectool getServerStatus` against the Flow
installation returns `running`). Suggestions for streamlining the script
are enthusiastically welcomed. 

## Running the script

To this point the script has been tested in a Bash shell on Mac Catalina and Fedora 30. It **should** 
work on any other distro without modification. I don't have a Windows license, so I can't say whether 
it works in Cygwin or not. 

To run the script you need a *name* for the cluster and a *GCP region*. Here's an example: 

```
./provisionCluster.sh doug us-east1-b
```

This creates two clusters, `doug-core` and `doug-flow`, in the `us-east1-b` region. The output of the script
shows the details of the user IDs and passwords you'll need to get started. 
You'll see something like this: 

```
------------------------------------------------------------------
----> Two Kuberenetes clusters have been provisioned, one with 
      Core (doug-core) and one with Flow (doug-flow). 
------------------------------------------------------------------
----> Using Core: 
      Your initial password is 2057e0b03d904e798a5194a1f1fc2742
      Visit https://1.2.3.4.nip.io/cjoc to log in.
------------------------------------------------------------------
----> Using Flow: 
      Your username and password are admin / changeme
      Visit https://4.3.2.1/auth/# to log in.
------------------------------------------------------------------
```
