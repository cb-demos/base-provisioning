# Thunder Demo deployment script

This is the depository for the shell scripts, tools, and other resources needed to provision a new 
demo environment. The script provisions a cluster in GKE, then installs Core and 
Flow in them. With the products installed, it uses some DSL, Groovy, and JSON files
to initialize a project, release, and pipeline (as well as associated data) in Flow. 

## Feedback

Please send your feedback in any way you can, including PRs, Slack messages 
(our CloudBees Slack channel is `#project-thunder-demo`), comments on 
[our Confluence pages](https://cloudbees.atlassian.net/wiki/spaces/PMT/pages/1004046750/Demo+Ecosystem+-+Overview), 
or create a ticket on 
[our Jira board](https://cloudbees.atlassian.net/secure/RapidBoard.jspa?rapidView=459&projectKey=DECO).

## Prerequisites

If you're going to run this yourself, you need to have the 
[`gcloud` CLI tools](https://cloud.google.com/sdk/docs/quickstarts) installed. 
Once they're installed, run `gcloud auth login` to log in to your GCP account. 

You also need V2 of [Helm](https://v2.helm.sh) installed. The script handles the 
details of installing Tiller
and initializing Helm, but you have to install Helm itself before the script will work.
**THIS SCRIPT DOES NOT WORK WITH HELM V3.** We're working on it, but for now, you've got
to install Helm V2. (If you're on a Mac, you can use `brew install helm@2` to get the
correct version.)

## What the script does

Here's the rundown on what the script does. See the actual code for more details.

1. Creates a cluster with `gcloud container clusters create`.
1. Configures `kubectl` to work with the new cluster.
1. Sets up `tiller` and `helm`.
1. Installs `nginx` via a Helm chart to set up the ingress for Core.
1. Installs Core via a Helm chart and waits for it to initialize.
1. Uses `kubectl exec` to get the `initialAdminPassword` value from the Core pod.
1. Uses a YAML file to install the Nexus OSS artifact repository.
1. Installs Flow via a Helm chart and waits for it to initialize.
1. Uses `kubectl exec ectool evalDsl` to process several DSL and Groovy files to create releases, pipelines, and data in Flow.
1. Prints the Core and Flow credentials and exits.

## Beware!

This thing takes a while. Google takes a few minutes to provision a cluster, and
Flow and Core (especially Flow) take a while to get up and running.
An obvious enhancement would be to modify the script so that Core and Flow are
installed concurrently. (Looking forward to your PRs.)

## Running the script

To this point the script has been tested in a Bash shell on Mac Catalina and Fedora 30. It **should** 
work on any other distro without modification. I don't have a Windows license, so I can't say whether 
it works in Cygwin or not. 

To run the script you need a *name* for the cluster, a *GCP region*, and a GCP
*project name*. Here's an example: 

```
./provisionCluster.sh doug us-east1 core-flow-research
```

This creates a cluster named `doug` in the `us-east1` region for the `core-flow-research`
project. The output of the script
shows the details of the user IDs and passwords you'll need to get started. 
When it's finished, you'll see something like this: 

```
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

## No rest for the wicked

Lots of things to do for the basic provisioning script. First of all, there are a bunch
of Jenkins plugins that I currently need to install manually. Here are their IDs:

* `configuration-as-code`
* `electricflow`
* `git`
* `git-client`
* `github`
* `github-api`
* `github-branch-source`
* `maven-plugin`
* `nexus-artifact-uploader`
* `workflow-api`
* `workflow-basic-steps`
* `workflow-cps`
* `workflow-durable-task-step`
* `workflow-job`
* `workflow-multibranch`
* `workflow-scm-step`
* `workflow-step-api`
* `workflow-support`

I need to set up CasC so that those plugins are automatically installed as part of the 
script. 

On the Flow side, I need to install the `unplug`, `EC-AuditReports`, and `EC-Slack` plugins. 
They need to be installed in that order, and `EC-Slack` is configured differently than 
any other Flow plugin I've worked with. All of that needs to be automated. 

As we go forward, we have to be able to store pipelines, configurations, environments, 
releases, etc. in GitHub so that they can automatically be installed as part of the 
provisioning process. 

Finally, **_DATA_** is just as important as having a running cluster and a working 
infrastructure. If the data doesn't help us tell a story, everything else is useless. 
A Flow dashboard filled with boxes that read "No Data Available" is a failure. Some of the data work is already done, other things will probably take a while. 