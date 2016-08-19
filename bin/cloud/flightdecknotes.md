# Building images
## AWS
* Using the AWS AMI creator, create 3 new images:
  * `./ami-creator -k aws_ireland -b develop -i static -t directory`
  * `./ami-creator -k aws_ireland -b develop -i static -t storage`
  * `./ami-creator -k aws_ireland -b develop -i static -t clusterware-static`
* Replace the AMI ID in each of the CloudFormation templates in the bumblebee repository for the appropriate AMI/template

## OpenStack
* Using an Alces build machine - check out the imageware repository, then switch to the static branch, then hop to the OpenStack support directory
* Build 3 new images:
  * `./makeimage directory 1.0.0`
  * `./makeimage storage 1.0.0`
  * `./makeimage clusterware-static 1.0.0`
* Copy each of the images to the demo OpenStack login node (alces-cluster@10.101.0.36 - standard password)
* From the demo OpenStack login node - upload each of the images to Glance with the following example command, replacing with your image file and name
  * Authenticate using the primary-rc.sh file
  * `glance image-create --container-format bare --disk-format qcow2 --min-disk 1 --file somefile.qcow2 --name fancyname --progress --human-readable --is-public true`
* Use your images when creating Components in FlightDeck

# Using with FlightDeck
On either AWS or OpenStack platform, perform the following steps:
* Gather the appropriate templates (infrastructure, storage and cluster) for the chosen platform - these can be found in the bumblebee repo
* Add a Component Template for each of the previously obtained templates. Map the appropriate FlightDeck inputs to the template parameters:
  * For the `infrastructure` *Component Template*:
    * `FlightClusterUUID` map to *"Cluster UUID"*
    * `FlightClusterToken` map to *"Cluster secret token"*
    * `FlightServiceURL` map to *"FlightDeck service URL"*
    * `FlightInstanceUUID` map to *"FlightDeck component instance UUID"*
    * `EnvironmentDomain` map to *"Cluster name"*
    * `KeyPair` map to *"Environment keypair"*
    * Hit **Next** to finish creating your `infrastructure` *Component Template*
    * You can use the following example description when entering a name and description for your `infrastructure` *Component Template*:

**Alces Flight Compute Infrastructure with Directory Service**
```
![Directory](https://s3.amazonaws.com/vlj/directory.png "Directory")

This template creates an Alces Infrastructure together with an Alces Directory Appliance for use with semi-ephemeral Alces Flight Compute clusters. The Alces Directory Appliance is deployed to provide DNS and user management utilities. The template creates the following components;

* **Virtual private network** used by all nodes in the environment to interact with the Alces Directory service
* **Alces Directory Appliance** for user management and DNS utilities

## Setup
1. Once the infrastructure template deployment has completed - the public IP address will be displayed. Use the displayed IP address together with your environment SSH keypair to log in as the `alces` administrator user then switch to the `root` user
2. Perform the Directory Appliance set up - you will be prompted to set passwords for the deployed services, however you can simply press **Enter** to have passwords randomly generated and saved to a secure configuration file
```

  * For the `storage` *Component Template*:
    * `FlightClusterUUID` map to *"Cluster UUID"*
    * `FlightClusterToken` map to *"Cluster secret token"*
    * `FlightServiceURL` map to *"FlightDeck service URL"*
    * `FlightInstanceUUID` map to *"FlightDeck component instance UUID"*
    * `EnvironmentDomain` map to *"Cluster name"*
    * `KeyPair` map to *"Environment keypair"*
    * Hit **Next** to finish creating your `storage` *Component Template*
    * You can use the following example description when entering a name and description for your `storage` *Component Template*:

**Alces Flight Storage Appliance**
```
![Storage](https://s3.amazonaws.com/vlj/storage.png "Storage")

This template creates an Alces Flight Storage appliance - which allows multiple NFS shares to be configured and enabled for clusters within a static environment.

## Setup

Configuration is performed automatically - the configuration file is located at `/opt/flight-storage/etc/config`. Upon first-boot the storage server will automatically share each of its configured mounts.

Additional mounts can be added by adding additional entries to the configuration file, then running the `configurator` located in `/opt/flight-storage`
```

  * For the `cluster` *Component Template*:
    * `FlightClusterUUID` map to *"Cluster UUID"*
    * `FlightClusterToken` map to *"Cluster secret token"*
    * `FlightServiceURL` map to *"FlightDeck service URL"*
    * `FlightInstanceUUID` map to *"FlightDeck component instance UUID"*
    * `EnvironmentDomain` map to *"Cluster name"*
    * `KeyPair` map to *"Environment keypair"*
    * Hit **Next** to finish creating your `cluster` *Component Template*
    * You can use the following example description when entering a name and description for your `cluster` *Component Template*:

**Alces Flight Semi-Ephemeral Compute Environment - 3 nodes**
```
![Alces Flight](https://s3.amazonaws.com/vlj/flight-3node.png "Alces Flight 3 node cluster")

Launch an Alces Flight Compute cluster complete with Alces Gridware and the SGE job scheduler. The semi-ephemeral template connects to your sites existing infrastructure, allowing you to log in to your environment with your username and password provided to you by your system administrator.

This template creates;

* A single cluster login node complete with cluster scheduler services
* 3 dedicated compute hosts

## Accessing your environment

Once your cluster has finished creating - you can log in to your environment using the login credentials your site administrator has provided you. This may be using an SSH key or using password authentication.
```

* Create *Components* from each of the *Component Templates*. For each of the *Components*, enter the following information:
  * `infrastructure`
    * `FlightCustomBucket` (if applicable, else use the default)
    * `FlightCustomProfiles` if you wish to perform automated set up of the directory appliance, enter `directory`
    * `DirectoryType` select your desired instance type, typically a `t2.small` will suffice
    * `NetworkCIDR` Enter the network CIDR for external SSH access
    * *Heat only:* `cluster_type` Select the previously built `directory` image
    * *Heat only:* `s3_access_key` Enter your S3 access key for use with the Alces customizer
    * *Heat only:* `s3_secret_key` Enter your S3 secret access key for use with the Alces customizer
  * `storage`
    * The `storage` template is mostly the same, fill in as per the infrastructure template - leaving the following fields blank for each platform:
      * OpenStack: `domain`, `prv_network`
      * AWS: `ClusterDomain`, `PrivateVPC`, `PrvSubnet`
      * Enter `node` in the CustomizerProfiles parameter
      * AWS only: Enter the `StorageSize` parameter
  * `cluster`
    * As per the `storage` template, fill in the required Parameters - leaving the network and domain settings blank until the Cluster Template stage
    * Create a *Cluster Template* from the `infrastructure` component
      * Enter your desired domain as the Flight cluster name, for example enter `bedrock` to create a Directory appliance with the domain `bedrock.alces.cluster` then launch the cluster
      * If the `directory` customizer profile was chosen - wait until creation has finished. The IPA setup will complete automatically. If automated set up was not chosen, manually log in to the Directory instance once deployment has completed and as the `root` user run `directory setup`
    * Create a *Cluster Template* from the `storage` component
      * From the Outputs of the Directory/Infrastructure stack, fill in the remaining parameters - correctly matching as required
      * Launch the `storage` Cluster Template and wait for completion. The FlightDeck Cluster Name does not matter, so a randomly generated cluster name can be used
    * Create a *Cluster Template* from the `cluster` component
      * From the Outputs of the Directory/Infrastructure stack, fill in the remaining parameters - correctly matching as required
      * Launch the `cluster` Cluster Template and wait for completion. The FlightDeck Cluster Name defines your cluster name
      * Log in to your cluster using the alces user and environment keypair. Optionally - a new cluster user can be created from the Directory appliance with an SSH keypair of choice. From the Directory instance, run `directory user add -f first -l last -u firstlast -s <middle bit of SSH pub key>`
