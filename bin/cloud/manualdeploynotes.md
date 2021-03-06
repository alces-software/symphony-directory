# Building images

## AWS

- Using the AWS AMI creator, create 3 new images:

  - `./ami-creator -k aws_ireland -b develop -i static -t directory`
  - `./ami-creator -k aws_ireland -b develop -i static -t storage`
  - `./ami-creator -k aws_ireland -b develop -i static -t clusterware-static`

- Replace the AMI ID in each of the CloudFormation templates in the bumblebee repository for the appropriate AMI/template

## OpenStack

- Using an Alces build machine - check out the imageware repository, then switch to the static branch, then hop to the OpenStack support directory
- Build 3 new images:

  - `./makeimage directory 1.0.0`
  - `./makeimage storage 1.0.0`
  - `./makeimage clusterware-static 1.0.0`

- Copy each of the images to the demo OpenStack login node (alces-cluster@10.101.0.36 - standard password)

- From the demo OpenStack login node - upload each of the images to Glance with the following example command, replacing with your image file and name

  - Authenticate using the primary-rc.sh file
  - `glance image-create --container-format bare --disk-format qcow2 --min-disk 1 --file somefile.qcow2 --name fancyname --progress --human-readable --is-public true`

- Use your images when creating Components in FlightDeck

# CloudFormation deployment

## Infrastructure

- Create a new stack using the `infrastructure.json` template found in `bumblebee/cloudformation/manual`
- Fill in the CloudFormation parameters with the following information:

  - `Stack name` - enter a stack name
  - `DirectoryType` - select the instance type to deploy
  - `EnvironmentDomain` - enter the domain you wish to use - entering `example` would set the domain `example.alces.cluster`
  - `FlightCustomBucket` - optionally use a custom Customizer bucket
  - `FlightCustomProfiles` - enter `directory` for the directory appliance to perform automatic setup
  - `KeyPair` - select your keypair, used to access the instance as the `alces` user
  - `NetworkCIDR` - enter a network CIDR used for external SSH access to the appliance

- Launch the CloudFormation stack and wait for completion

- If the `directory` custom profile was not used - log in to the instance and switch to the `root` user, then perform set up by running the following command: `directory setup`
- Optionally set up a new user to access deployed Flight Compute environments with:

  - `directory user add -f firstname -l lastname -u firstnamelastname -s <ssh key>`
  - _Note_: the SSH keypair option will only accept the middle part of the SSH public key (e.g. the key minus the `ssh-rsa` and name/email at the end of the key)

## Storage appliance (_optional_)

- Create a new stack using the `appliances/storage.json` template found in `bumblebee/cloudformation/manual`
- Fill in the CloudFormation parameters with the following information:

  - `Stack name` - enter a stack name, e.g. `example-nfs`
  - `ApplianceType` - select the instance type to deploy
  - `ClusterDomain` - enter the name of your IPA domain, e.g. `example`
  - `FlightCustomBucket` - optionally use a custom Customizer bucket
  - `FlightCustomProfiles` - enter `node` to enable automatic IPA enrolment
  - `KeyPair` - select your keypair, used to access the instance as the `alces` user
  - `NetworkCIDR` - enter a network CIDR used for external SSH access to the appliance
  - `EnvironmentVPC` - select the VPC created by your infrastructure template
  - `PrvSubnet` - select the `prv` subnet created by your infrastructure template
  - `APISubnet` - select the `api` subnet created by your infrastructure template
  - `StorageSize` - enter the size in GB of storage to deploy

- Launch the CloudFormation stack and wait for completion

- You can verify the storage mounts are available from the Directory appliance, e.g. `showmount -e storage1`

## Flight Compute environment

- Create a new stack using the `cluster.json` template found in `bumblebee/cloudformation/manual`
- Fill in the CloudFormation parameters with the following information:

  - `Stack name` - enter a stack name
  - `ClusterDomain` - enter the name of your IPA domain, e.g. `example`
  - `ClusterName` - enter your desired cluster name
  - `ComputeType` - select an instance type to use for all deployed instances
  - `FlightCustomBucket` - optionally use a custom Customizer bucket
  - `FlightCustomProfiles` - enter `node mounts` to enable automatic IPA enrolment, as well as automatically mounting any available storage mounts from the storage appliance. If the storage appliance was not deployed, simply enter `node` in the `FlightCustomProfiles` parameter field
  - `KeyPair` - select your keypair, used to access the instance as the `alces` user
  - `NetworkCIDR` - enter a network CIDR used for external SSH access to the appliance
  - `EnvironmentVPC` - select the VPC created by your infrastructure template
  - `PrvSubnet` - select the `prv` subnet created by your infrastructure template

- Launch the CloudFormation stack and wait for completion

- Log in either as the `alces` user and your environment keypair - or if a user was created through the directory appliance - log in as that user once IPA enrolment has completed on the login node
- _Note_ - full deployment and enrolment can take up to 10 minutes, check the status of enrolment through `/var/log/clusterware/instance.log`

# Heat deployment

## Infrastructure

- Create a new stack using the `infrastructure.yaml` template found in `bumblebee/heat/manual`
- Fill in the Heat parameters with the following information:

  - `Stack Name` - enter a stack name
  - `Creation Timeout (minutes)` - leave default (`60`)
  - `Rollback On Failure` - `true`
  - `Password for user` - Enter your OpenStack user password
  - `Cluster admin key` - select your keypair, used to access the instance as the `alces` user
  - `Bumblebee Image` - select the `directory` image you previously created
  - `Alces Customizer profiles` - enter `directory` for automated setup of the directory appliance
  - `Directory instance flavour` - select your desired instance type
  - `environment_domain` - Enter your desired environment domain, e.g. `example`
  - `S3 Access Key` - Enter your S3 access key, used with the Alces customize tool
  - `S3 Region` - enter the region your customizer bucket lives in, e.g. `eu-west-1`
  - `S3 Secret Key` - Enter your S3 secret key, used with the Alces customize tool
  - `Alces Customizer S3 bucket` - enter your S3 bucket - e.g. `s3://mybucket`

- Launch the Hear stack and wait for completion

- If the `directory` custom profile was not used - log in to the instance and switch to the `root` user, then perform set up by running the following command: `directory setup`
- Optionally set up a new user to access deployed Flight Compute environments with:

  - `directory user add -f firstname -l lastname -u firstnamelastname -s <ssh key>`
  - _Note_: the SSH keypair option will only accept the middle part of the SSH public key (e.g. the key minus the `ssh-rsa` and name/email at the end of the key)

## Storage appliance

- Create a new stack using the `storage.yaml` template found in `bumblebee/heat/manual/appliances`
- Fill in the Heat parameters with the following information:

  - `Stack Name` - enter a stack name
  - `Creation Timeout (minutes)` - leave default (`60`)
  - `Rollback On Failure` - `true`
  - `Password for user` - enter your OpenStack user password
  - `Cluster admin key` - select your keypair, used to access the instance as the `alces` user
  - `Bumblebee Image` - select the `storage` image you previously created
  - `Alces Customizer profiles` - enter `node` for automatic IPA enrolment
  - `Environment domain` - enter the name of your IPA domain, e.g. `example`
  - `Private network` - select the private network created by your infrastructure template
  - `S3 Access Key` - enter your S3 access key, used with the Alces customize tool
  - `S3 Region` - enter the region your customizer bucket lives in, e.g. `eu-west-1`
  - `Alces Customizer S3 bucket` - enter your S3 bucket - e.g. `s3://mybucket`

- Launch the Heat stack and wait for completion

## Compute environment

- Create a new stack using the `cluster.yaml` template found in `bumblebee/heat/manual`
- Fill in the Heat parameters with the following information:

  - `Stack Name` - enter a stack name
  - `Creation Timeout (minutes)` - leave default (`60`)
  - `Rollback On Failure` - `true`
  - `Password for user` - enter your OpenStack user password
  - `Cluster admin key` - select your keypair, used to access the instances as the `alces` user
  - `Bumblebee Image` - select the `clusterware-static` image you previously created
  - `Alces Customizer profiles` - enter `node` for automatic IPA enrolment. Optionally - if a storage appliance was deployed, enter `node mounts` for automatic storage mount setup
  - `Environment domain` - enter the name of your IPA domain, e.g. `example`
  - `Private network` - select the private network created by your infrastructure template
  - `S3 Access Key` - enter your S3 access key, used with the Alces customizer tool
  - `S3 Region` - enter the region your customizer bucket lives in, e.g. `eu-west-1`
  - `Alces Customizer S3 bucket` - enter your S3 bucket - e.g. `s3://mybucket`

- Launch the Heat stack and wait for completion. Once IPA enrolment has finished - you can log in to the login node instance using either the `alces` user with your environment key pair, or using an optionally set up user from the Directory appliance
