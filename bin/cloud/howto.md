# How to launch an infrastructure stack with directory server and connected clusters

Steps to create the following environment: 

* Infrastructure stack, containing the site-wide `prv` network and `directory` instance
* One or more clusters, sitting on both the site-wide `prv` network and their own internal `api` network

## OpenStack

### Creating appliance images

#### Building the `directory` appliance image

* From an Alces build machine, clone the `imageware` repository and check out the `static` branch.

* Ensure an existing image does not exist for the version you are attempting to create, these will live in `/opt/vm/imagebuilder-release/centos7-directory*`

* Run the image builder: 

```bash
cd $imagewarecheckout/support/openstack
./makeimage directory 1.0.0 # replace with your desired version
```

* Once finished, copy the created image to the Alces demo OpenStack - then SSH to the demo OpenStack login node to upload the newly created image to Glance:

```bash
scp -i $HOME/.ssh/id_julius \
    /opt/vm/imagebuilder-release/centos7-directory-1.0.0.qcow2 \
    alces-cluster@10.101.0.36:/users/alces-cluster/
ssh -i $HOME/.ssh/id_julius alces-cluster@10.101.0.36
```

* Authenticate to OpenStack, then upload the image to Glance

```bash
. $HOME/primary_rc.sh
glance image-create \
       --container-format bare \
       --disk-format qcow2 \
       --min-disk 1
       --file centos7-directory-1.0.0.qcow2 \
       --name directory-1.0.0 \
       --progress \
       --human-readable \
       --is-public true
```

#### Building the compute node image

Repeat the steps for the `directory` appliance - but instead build the `clusterware-static` appliance type, for example: 

```bash
./makeimage clusterware-static 1.0.0
```

### Creating environments

#### Setting up the infrastructure/directory

##### Deploying the infrastructure stack

* Connect to the Alces OpenStack demo VPN - then from the Alces demo OpenStack Horizon dashboard - navigate to the Heat stack creation console

* Create a new stack using the `infrastructure.yaml` file located in the `bumblebee` repository: 

    `https://raw.githubusercontent.com/alces-software/bumblebee/master/heat/infrastructure.yaml`

* Fill in the form with the following details: 

    **Stack Name**: This sets the domain, for example a stack name `tatooine` would define the IPA realm `tatooine.alces.cluster`
    **Creation Timeout**: Leave default `60`
    **Rollback On Failure**: `true`
    **Password for user "(your user)"**: Enter the OpenStack password for your OpenStack user
    **Cluster admin key**: Select your desired keypair, this is used to access the `directory` instance as the `alces` user
    **Bumblebee Image**: Select the previously uploaded `directory` appliance image - for example `directory-1.0.0`
    **Directory instance flavour**: Select a flavour to use for the directory instance

* Once all of the required fields are filled in - launch the stack and wait for completion

###### Performing initial setup

* Use the displayed floating IP address to SSH as the `alces` user with your previously selected key

* Switch to the `root` user

* Run `directory setup` to begin configuration - this will prompt you for an IPA administrator password and Alces Flight Trigger authentication password. Press enter to use the default generated passwords for each service.

* Once the configuration has completed - additional utilities are available such as adding a user

* Add a user to log in to each deployed cluster as, along with an SSH key: 

```bash
directory user add -f luke -l skywalker -u lskywalker -s AAAAB3NzaC1yc2EAAAADAQABAAABAQDCBMcZdI/1SLOaHhGH0dbfZh7YZwWHNN779oA9JKfk0QWHqTqY78x/0B1Q8lRBBrkFYMU1c9fsF0vYlVBAEvVWGZL24i/l/C1Bnu82O8NdUE/lxUzuu4xD6HTYoVJzFwpLWGkuqjJmzijQ2phYcvavUhJkvcI9fU9cig4PqcOTGDNG0lin7YGkdqZiRB6k+82WdTcegiLMnHVG/SC0VoIMf6eElpceviBZieEAsLX2DoADmYu7PO2SSI3QaKDtSodt5nEeGfs/Q0/91vml9B95R0Jb6tm1YGnt51JD2C7FmPCBxdClGWthhdYj/MfFkX0DVAA5UygDCJ0rGdMdGus1
```

* *Note*: The SSH key will only accept the middle part of the key (currently), so do not include the beginning `ssh-rsa` or end name of the public key - just the actual key

#### Deploying a cluster

* Connect to the Alces OpenStack demo VPN - then from the Alces demo OpenStack Horizon dashboard - navigate to the Heat stack creation console

* Create a new stack using the `cluster.yaml` file located in the `bumblebee` repository:

    `https://raw.githubusercontent.com/alces-software/bumblebee/master/heat/cluster.yaml`

* Fill in the form with the following details:

    **Stack Name**: This sets the cluster name, enter your desired cluster name
    **Creation Timeout**: Leave default `60`
    **Rollback On Failure**: `true`
    **Password for user "(your user)"**: Enter the OpenStack password for your OpenStack user
    **Cluster admin key**: Select your desired keypair, this is used to access the cluster as the `alces` administrator user
    **Bumblebee Image**: Select your previously uploaded `clusterware-static` appliance image - for example `clusterware-static-1.0.0`
    **Compute node instance type**: Select a flavour to use for all nodes within a cluster
    **Alces Customizer profiles**: Enter `node`
    **Environment domain**: Enter the infrastructure stack name, for example `tatooine`. This would set your cluster domain as `jabbas-palace.tatooine.alces.cluster`
    **Private network**: Select the private network created by your infrastructure stack, for example `tatooine-prv`. The network will always be marked `$domain-prv`
    **S3 Access Key**: Enter your AWS S3 Access Key for use with the Alces Customizer tool
    **S3 Region**: Enter `eu-west-1`
    **S3 Secret Key**: Enter your AWS S3 Secret Access Key for use with the Alces Customizer tool
    **Alces Customizer S3 bucket**: Enter `s3://alces-flight-nmi0ztdmyzm3ztm3`

* Once all of the required fields are filled in - launch the stack and wait for completion

* Once the nodes begin booting, they will automatically join the IPA realm. You can check the status by running the following command on the `directory` appliance: 

```bash
ipa dnsrecord-find <clustername>.<domain>.alces.cluster
```

* Once the login node has joined (this can take up to a few minutes) - you can SSH in as your previously created user, together with the key you provided for that user.

* *Note*: as there are no shared home directories, unless you manually upload your private key to the login node for the created user - you will not be able to SSH between nodes

## AWS

### Creating appliance images

#### Building the `directory` appliance image

* Clone the `imageware` repository to your desired location

* Run the AMI creator: 

```bash
cd $imagewarecheckout/support/aws
./ami-creator -k <your aws keypair> -b develop -i static -t directory
```

* Once finished - make note of the AMI ID displayed

* Using the infrastructure CloudFormation template as a base - replace the existing AMI ID in the `eu-west-1` region with your newly created AMI ID. The base template can be found in the `bumblebee` repository at: 

    `https://raw.githubusercontent.com/alces-software/bumblebee/master/cloudformation/infrastructure.json`

#### Building the compute node image

Repeat the steps for the `directory` appliance - but instead use the `clusterware-static` appliance type, for example:

```bash
./ami-creator -k <your aws keypair> -b develop -i static -t clusterware-static
```

### Creating environments

#### Setting up the infrastructure/directory

##### Deploying the infrastructure stack

* Navigate to the CloudFormation console in the `eu-west-1` region

* Create a stack using your modified `infrastructure` template

* Fill in the CloudFormation parameters:

    **Stack name**: This sets the domain, for example a stack name `tatooine` would define the IPA realm `tatooine.alces.cluster`
    **DirectoryType**: Select the type of directory instance to deploy
    **FlightCustomBucket**: Leave blank
    **FlightCustomProfiles**: Leave blank
    **KeyPair**: Select your AWS key pair, this is used to access the instance as the `alces` administrator user
    **LoginSystemDiskSize**: Enter the size in GB of the root volume on the directory instance to deploy
    **NetworkCIDR**: Enter a CIDR that is permitted to access the directory instance

* Once all of the required fields are filled in - launch the stack and wait for completion

##### Performing initial setup

* Use the displayed floating IP address to SSH as the `alces`  user with your previously selected key

* Switch to the `root` user

* Run `directory setup` to begin configuration - this will prompt you for an IPA administrator password and Alces Flight Trigger authentication password. Press enter to use the default generated passwords for each service.

* Once the configuration has completed - additional utilities are available such as adding a user

* Add a user to log in to each deployed cluster as, along with an SSH key: 

```bash
directory user add -f luke -l skywalker -u lskywalker -s AAAAB3NzaC1yc2EAAAADAQABAAABAQDCBMcZdI/1SLOaHhGH0dbfZh7YZwWHNN779oA9JKfk0QWHqTqY78x/0B1Q8lRBBrkFYMU1c9fsF0vYlVBAEvVWGZL24i/l/C1Bnu82O8NdUE/lxUzuu4xD6HTYoVJzFwpLWGkuqjJmzijQ2phYcvavUhJkvcI9fU9cig4PqcOTGDNG0lin7YGkdqZiRB6k+82WdTcegiLMnHVG/SC0VoIMf6eElpceviBZieEAsLX2DoADmYu7PO2SSI3QaKDtSodt5nEeGfs/Q0/91vml9B95R0Jb6tm1YGnt51JD2C7FmPCBxdClGWthhdYj/MfFkX0DVAA5UygDCJ0rGdMdGus1
```

* *Note*: The SSH key will only accept the middle part of the key (currently), so do not include the beginning `ssh-rsa` or end name of the public key - just the actual key

#### Deploying a cluster

* Navigate to the CloudFormation console in the `eu-west-1` region

* Create a new stack using your modified `cluster` template

* Fill in the CloudFormation parameters:

    **Stack name**: This sets the cluster name, enter your desired cluster name
    **ClusterDomain**: Enter the infrastructure stack name, for example `tatooine`. This would set your cluster domain as `jabbas-palace.tatooine.alces.cluster`
    **ComputeType**: Select the compute instance type to use for all deployed instances
    **FlightCustomBucket**: Leave blank
    **FlightCustomProfiles**: Enter `node`
    **KeyPair**: Select a key pair to assign to the instance
    **NetworkCIDR**: Enter a CIDR that is permitted to access each of the deployed instances
    **PrivateVPC**: Select the VPC created by your infrastructure stack, for example `tatooine`
    **PrvSubnet**: Select the private network subnet created by your infrastructure stack, for example `tatooine-prv`

* Once all of the required fields are filled in - launch the stack and wait for completion

* Once the nodes begin booting, they will automatically join the IPA realm. You can check the status by running the following command on the `directory` appliance:

```bash
ipa dnsrecord-find <clustername>.<domain>.alces.cluster
```

* Once the login node has joined (this can take up to a few minutes) - you can SSH in as your previously created user, together with the key you provided for that user.

* *Note*: as there are no shared home directories, unless you manually upload your private key to the login node for the created user - you will not be able to SSH between nodes
