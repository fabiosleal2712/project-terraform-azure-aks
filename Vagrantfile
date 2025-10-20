Vagrant.configure("2") do |config|
  # Usar a box 'bento/ubuntu-20.04' que é uma distribuição leve do Ubuntu
  config.vm.box = "bento/ubuntu-20.04"

  # Configurar a máquina virtual
  config.vm.provider "virtualbox" do |vb|
    vb.memory = "512"
    vb.cpus = 1
  end

  # Sincronizar a pasta do host com a máquina virtual
  config.vm.synced_folder ".", "/vagrant", type: "virtualbox"
  
  
  config.vm.provision "shell", inline: <<-SHELL
  # Update and install basic dependencies
  sudo apt-get update
  sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 234654DA9A296436
  sudo apt-get update
  sudo apt-get install -y wget unzip curl

  # Install Ansible and Python
  sudo apt-get install -y ansible python3

  # Install Terraform
  TERRAFORM_VERSION="1.0.11"
  wget https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip
  unzip terraform_${TERRAFORM_VERSION}_linux_amd64.zip
  sudo mv terraform /usr/local/bin/
  rm terraform_${TERRAFORM_VERSION}_linux_amd64.zip

  # Install AWS CLI
  curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
  unzip awscliv2.zip
  sudo ./aws/install
  rm -rf awscliv2.zip aws

  # Install kubectl (official method)
  curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
  sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
  kubectl version --client --short

  # Install eksctl
  curl --silent --location "https://github.com/weaveworks/eksctl/releases/latest/download/eksctl_$(uname -s)_amd64.tar.gz" | tar xz -C /tmp
  sudo mv /tmp/eksctl /usr/local/bin

  # Verify eksctl installation
  eksctl version

  # Download the installer script:
curl --proto '=https' --tlsv1.2 -fsSL https://get.opentofu.org/install-opentofu.sh -o install-opentofu.sh
# Alternatively: wget --secure-protocol=TLSv1_2 --https-only https://get.opentofu.org/install-opentofu.sh -O install-opentofu.sh

# Give it execution permissions:
chmod +x install-opentofu.sh

# Please inspect the downloaded script

# Run the installer:
./install-opentofu.sh --install-method deb

# Remove the installer:
rm -f install-opentofu.sh

SHELL

end
