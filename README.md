# About

Use packer to clone and customize a Windows image in Proxmox.

This will:

* Clone the `windows-2022-uefi` Proxmox template image.
* Install Chocolatey.
* Generalize (Sysprep) the machine.
* Create the `custom-windows-2022-uefi` Proxmox template image.

# Usage

Create the `windows-2022-uefi` Proxmox template image by following the instructions at the [rgl/windows-vagrant repository](https://gitgub.com/rgl/windows-vagrant).

Set your proxmox details:

```bash
# see https://registry.terraform.io/providers/bpg/proxmox/latest/docs#argument-reference
# see https://github.com/bpg/terraform-provider-proxmox/blob/v0.67.1/proxmoxtf/provider/provider.go#L50-L59
cat >secrets-proxmox.sh <<'EOF'
unset HTTPS_PROXY
#export HTTPS_PROXY='http://localhost:8080'
export PROXMOX_USERNAME='root@pam'
export PROXMOX_PASSWORD='vagrant'
export PROXMOX_NODE='pve'
export PROXMOX_NODE_ADDRESS='192.168.1.21'
export PROXMOX_URL="https://$PROXMOX_NODE_ADDRESS:8006/api2/json"
export TF_VAR_proxmox_pve_node_name="$PROXMOX_NODE"
export TF_VAR_proxmox_pve_node_address="$PROXMOX_NODE_ADDRESS"
export PROXMOX_VE_INSECURE='1'
export PROXMOX_VE_ENDPOINT="$PROXMOX_URL"
export PROXMOX_VE_USERNAME="$PROXMOX_USERNAME"
export PROXMOX_VE_PASSWORD="$PROXMOX_PASSWORD"
EOF
source secrets-proxmox.sh
```

Create the template:

```bash
# NB use the same file that was created as described in the
#    rgl/windows-vagrant repository.
source secrets-proxmox.sh
CHECKPOINT_DISABLE=1 PACKER_LOG=1 PACKER_LOG_PATH=packer-init.log \
    packer init .
CHECKPOINT_DISABLE=1 PACKER_LOG=1 PACKER_LOG_PATH=packer-build.log \
    packer build -on-error=abort .
```

Try the template, using terraform:

```bash
pushd example-terraform
export CHECKPOINT_DISABLE='1'
export TF_LOG='DEBUG' # TRACE, DEBUG, INFO, WARN or ERROR.
export TF_LOG_PATH='terraform.log'
terraform init
terraform plan -out=tfplan
time terraform apply tfplan
```

Login into the machine using SSH:

```bash
ssh-keygen -f ~/.ssh/known_hosts -R "$(terraform output --raw ip)"
ssh "vagrant@$(terraform output --raw ip)"
exit # ssh
```

Login into the machine using PowerShell Remoting over SSH:

```bash
pwsh
Enter-PSSession -HostName "vagrant@$(terraform output --raw ip)"
$PSVersionTable
whoami /all
exit # Enter-PSSession
exit # pwsh
```

Destroy the example:

```bash
time terraform destroy -auto-approve
popd
```
