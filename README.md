# Configure EBS on AWS

## Help

```bash
   _____             __ _                        ______ ____   _____ 
  / ____|           / _(_)                      |  ____|  _ \ / ____|
 | |     ___  _ __ | |_ _  __ _ _   _ _ __ ___  | |__  | |_) | (___  
 | |    / _ \| '_ \|  _| |/ ` | | | | '__/ _ \ |  __| |  _ < \___ \ 
 | |___| (_) | | | | | | | (_| | |_| | | |  __/ | |____| |_) |____) |
  \_____\___/|_| |_|_| |_|\__, |\__,_|_|  \___| |______|____/|_____/ 
                           __/ |                                     
                          |___/                                      
      Created by: Andrei Merlescu (github.com/andreimerlescu)        

[SUCCESS] Welcome to ./configure-ebs.sh!
[INFO] Parsing arguments...
Usage: ./configure-ebs.sh [OPTIONS]
       --fstrim      Set to any value to enable fstrim on this EBS volume
       --fs          Filesystem type of the EBS volume (default = 'xfs')
       --device      The original mapping of the EBS device mapping. Should be /dev/xvd#.
       --volumeid    The AWS EBS block device ID. Seen as vol#################
       --label       Name of the volume being created
       --mount       Define the mount point of the EBS volume
       --size        Integer of GiB of EBS volume capacity


```

## Examples

```bash
# GitLab Registry
./configure-ebs.sh --device "/dev/nvme1n1" \
                   --label "gitlab_registry" \
                   --mount "/var/opt/gitlab/gitlab-rails/shared/registry" \
                   --fs "xfs" \
                   --fstrim "on"

# Git Large File Storage
./configure-ebs.sh --device "/dev/nvme2n1" \
                   --label "gitlab_lfs_objects" \
                   --mount "/var/opt/gitlab/gitlab-rails/shared/lfs-objects" \
                   --fs "xfs" \
                   --fstrim "on"

# Artifacts
./configure-ebs.sh --device "/dev/nvme3n1" \
                   --label "gitlab_artifacts" \
                   --mount "/var/opt/gitlab/gitlab-rails/shared/artifacts" \
                   --fs "xfs" \
                   --fstrim "on"

# Public Uploads
./configure-ebs.sh --device "/dev/nvme4n1" \
                   --label "gitlab_uploads" \
                   --mount "/opt/gitlab/embedded/service/gitlab-rails/public" \
                   --fs "xfs" \
                   --fstrim "on"

# Terraform State
./configure-ebs.sh --device "/dev/nvme5n1" \
                   --label "gitlab_terraform_state" \
                   --mount "/var/opt/gitlab/gitlab-rails/shared/terraform_state" \
                   --fs "xfs" \
                   --fstrim "on"

# CI Secure Files
./configure-ebs.sh --device "/dev/nvme6n1" \
                   --label "gitlab_ci_secure_files" \
                   --mount "/var/opt/gitlab/gitlab-rails/shared/ci_secure_files" \
                   --fs "xfs" \
                   --fstrim "on"

# Backup Directory
./configure-ebs.sh --device "/dev/nvme7n1" \
                   --label "gitlab_ci_secure_files" \
                   --mount "/var/opt/gitlab/backups" \
                   --fs "xfs" \
                   --fstrim "on"


```
