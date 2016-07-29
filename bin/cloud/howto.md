# How to launch an infrastructure stack with directory/subclusters

Steps to create the following environment: 

* Infrastructure stack, containing the site-wide `prv` network and `directory` instance
* One or more clusters, sitting on both the site-wide `prv` network and their own internal `api` network
* Optionally deploy example appliances into the site domains network for interaction with all deployed clusters

## OpenStack

### Setting up the infrastructure

* Using the Alces Demo OpenStack - navigate to the Heat dashboard
* Create a new Heat stack using the following template: 
  `https://raw.githubusercontent.com/alces-software/bumblebee/master/heat/infrastructure.yaml`
* Important things to note when filling in the Heat parameters:
  * The stack name should be filled in as your site domain name, for example `tatooine` - which would then set the IPA REALM as `tatooine.alces.cluster`
  * Select the correct image, or nothing will work! The `bumblebee-develop` image should be used. 
* Launch the Heat stack
* Once the stack has finished creating - the floating IP of the directory server will be displayed. Log in to the directory server as the `alces` user and switch to the root account
* (fill in something about directory set up)

### Setting up a cluster

* Using the Alces Demo OpenStack - navigate to the Heat dashboard
* Create a new Heat stack using the following template:
  `https://raw.githubusercontent.com/alces-software/bumblebee/master/heat/cluster.yaml`
* Launch the Heat stack
* Important things to note when filling in the Heat parameters:
  * The stack name should be filled in as your desired cluster name, for example `jabbas-palace` - which would then set your domain as `jabbas-palace.tatooine.alces.cluster`
  * The environment domain field should contain the name of your infrastructure Heat template name, e.g. `tatooine`
  * Select the correct image - the `clusterware-static` image should be used. 
  * Select the correct network to join, for example `$DOMAIN-prv`
* Once the stack has finished creating - the floating IP of the login node will be displayed. Log in to the directory server as the `alces` user. 

## AWS

### Setting up the infrastructure

* Navigate to the CloudFormation console
* Create a new stack using the following template:
  `https://raw.githubusercontent.com/alces-software/bumblebee/master/cloudformation/infrastructure.json`
* Important things to note when filling in the CloudFormation parameters:
  * The stack name should be filled in as your site domain name, for example `tatooine` - which would then set the IPA REALM as `tatooine.alces.cluster`
* Launch the CloudFormation stack
* Once the stack has finished creating - the floating IP of the directory server will be displayed. Log in to the directory server as the `alces` user and switch to the root account
* Run the directory set up script: 

```bash
curl -sL https://git.io/vKFGI | /bin/bash
```

* Once the set up has finished - continue to creating a cluster

### Setting up a cluster

* Navigate to the CloudFormation console
* Create a new stack using the following template:
  `https://raw.githubusercontent.com/alces-software/bumblebee/master/cloudformation/cluster.json`
* Important things to note when filling in the CloudFormation parameters:
  * The stack name should be filled in as your desired cluster name, for example `jabbas-palace` - which would then set your domain as `jabbas-palace.tatooine.alces.cluster`
  * In the customization profile box, enter `node` - this will trigger the `join` script when each node boots - automatically adding it to the IPA realm
  * The environment domain field should contain the name of your infrastructure Heat template name, e.g. `tatooine`
  * Select the correct VPC, for example `$DOMAIN-vpc`
  * Select the correct subnet, for example `$DOMAIN-prv`
* Launch the CloudFormation stack
* When the cluster is ready - the public IP address of the login node will be displayed

## Issues

### General

* The ClusterWare SSH key does not seem to work when attempting to SSH between hosts. Each node will have the ClusterWare generated key in its authorised keys, but will not accept the key
* Currently, nodes have no way of performing their `leave` script - this has to be done manually either from the directory server or from the node itself

### AWS

* Without manually modifying the `cluster` template each time - only 1 cluster can be created as the cluster internal `api` network has to live on a subnet within the VPC, meaning multiple subnets with the same subnet cannot be created
* As the directory server is not any of the available ClusterWare roles - the customizer won't work, hence having to log in manually and run the set up script

### OpenStack

* At present - the customizer tool isn't working with OpenStack, so manual configuration is required using the provided scripts. The directory server is automatically set up and configured to work with the client side scripts
