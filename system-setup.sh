#!/bin/bash

cp /mnt/chromeos/GoogleDrive/MyDrive/usr/bin/Qogir-theme-master.zip /home/ubuntu/Qogir.zip &&
unzip /home/ubuntu/Qogir.zip &&
sudo add-apt-repository ppa:apt-fast/stable &&
sudo apt-get update &&
sudo apt-get install -y apt-fast gnome-tweaks gnome-terminal sassc &&
/home/ubuntu/Qogir-theme-master/install.sh --logo debian --tweaks round &&
mkdir /home/ubuntu/Desktop &&
mkdir /home/ubuntu/Documents &&
mkdir /home/ubuntu/Photos &&
ln -s /mnt/chromeos/GoogleDrive/MyDrive/usr /home/ubuntu/usr &&
ln -s /mnt/chromeos/GoogleDrive/MyDrive /home/ubuntu/Google\ Drive
sudo apt-fast install -y nautilus neofetch gedit eog celluloid &&
sudo cp /mnt/chromeos/GoogleDrive/MyDrive/usr/sbin/pacapt.sh /usr/local/bin/pacapt &&
sudo chmod 755 /usr/local/bin/pacapt &&
sudo ln -sv /usr/local/bin/pacapt /usr/local/bin/pacman || true &&
gnome-terminal -- sudo apt-fast install zsh &&
gnome-terminal -- sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" &&
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git &&
echo "source ${(q-)PWD}/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" >> ${ZDOTDIR:-$HOME}/.zshrc &&
source ./zsh-syntax-highlighting/zsh-syntax-highlighting.zsh &&
sudo chsh -s /bin/zsh ubuntu &&
wget -qO - https://download.sublimetext.com/sublimehq-pub.gpg | sudo apt-key add - &&
echo "deb https://download.sublimetext.com/ apt/stable/" | sudo tee /etc/apt/sources.list.d/sublime-text.list &&
sudo apt-get update &&
sudo apt-get install sublime-text &&
echo neofetch >> /home/ubuntu/.zshrc &&
sudo chsh -s /bin/zsh ubuntu
