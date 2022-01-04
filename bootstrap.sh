
#in crosh termina, copy paste this beginning section.. do not include the # in the paste

lxc stop penguin --force &&
lxc rename penguin debian &&
lxc launch ubuntu:18.04 penguin &&
lxc exec penguin -- bash

#	copy entire block and run as root user in crosh terminal
echo "APT UPDATE" &&
apt update &&
echo "APT UPGRADE" &&
apt upgrade &&
echo "ADDING CROS-PACKAGES" &&
echo "deb https://storage.googleapis.com/cros-packages buster main" > /etc/apt/sources.list.d/cros.list &&
if [ -f /dev/.cros_milestone ]; then sudo sed -i "s?packages?packages/$(cat /dev/.cros_milestone)?" /etc/apt/sources.list.d/cros.list; fi &&
apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 1397BC53640DB551 &&
apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 7638D0442B90D010 &&
apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 04EE7237B7D453EC &&
echo "APT UPDATE" &&
apt update &&
echo "INSTALLING BINUTILS" &&
apt install binutils &&
echo "DOWNLOADING CROS-PACKAGES" &&
apt download cros-ui-config &&
echo "UNPACKED DEB" &&
ar x cros-ui-config_0.12_all.deb data.tar.gz &&
gunzip data.tar.gz &&
echo "DELETED SETTINGS.INI" &&
tar f data.tar --delete ./etc/gtk-3.0/settings.ini &&
echo "REGENERATING DEB" &&
gzip data.tar &&
ar r cros-ui-config_0.12_all.deb data.tar.gz &&
echo "CLEANING UP" &&
rm -rf data.tar.gz &&
echo "INSTALLING CROS-PACKAGES"
apt install cros-guest-tools ./cros-ui-config_0.12_all.deb &&
echo "REMOVING CUSTOM DEB" &&
rm cros-ui-config_0.12_all.deb &&
echo "INSTALLING ADWAITA-ICON" &&
apt install adwaita-icon-theme-full &&
echo "CREATING BOOTSTRAP" &&
echo "mv /mnt/chromeos/GoogleDrive/MyDrive/usr/bin/Qogir-theme-master.zip /home/ubuntu/Qogir.zip &&\
unzip /home/ubuntu/Qogir.zip /home/ubuntu/.Qogir &&\
/home/ubuntu/.Qogir/install.sh --logo debian --tweaks round &&\
sudo apt-get install gnome-terminal &&\
gnome-terminal -- /home/ubuntu/.package_install &&\
mkdir /home/ubuntu/Desktop &&\
mkdir /home/ubuntu/Documents &&\
mkdir /home/ubuntu/Photos &&\
ln -s /mnt/chromeos/GoogleDrive/MyDrive/usr /home/ubuntu/usr &&\
ln -s /mnt/chromeos/GoogleDrive/MyDrive /home/ubuntu/Google\ Drive" >> /home/ubuntu/.bootstrap_start &&
echo "echo Run bootstrap_start once system is configured" >> /home/ubuntu/.bashrc
sudo chmod u+x /home/ubuntu/.bootstrap_start && 
echo "CREATING SYSPKG" &&
echo 'sudo add-apt-repository ppa:apt-fast/stable &&\
sudo apt-get update &&\
sudo apt-get install apt-fast &&\
sudo apt-fast install gnome-tweaks nautilus neofetch gedit eog celluloid &&\
sudo cp /mnt/chromeos/GoogleDrive/MyDrive/usr/sbin/pacapt.sh /usr/local/bin/pacapt &&\
sudo chmod 755 /usr/local/bin/pacapt && sudo ln -sv /usr/local/bin/pacapt /usr/local/bin/pacman || true &&\
gnome-terminal -- sudo apt-fast install zsh &&\
gnome-terminal -- sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" &&\
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git &&\
echo "source ${(q-)PWD}/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" >> ${ZDOTDIR:-$HOME}/.zshrc &&\
source ./zsh-syntax-highlighting/zsh-syntax-highlighting.zsh && sudo chsh -s /bin/zsh ubuntu &&\
wget -qO - https://download.sublimetext.com/sublimehq-pub.gpg | sudo apt-key add - &&\
echo "deb https://download.sublimetext.com/ apt/stable/" | sudo tee /etc/apt/sources.list.d/sublime-text.list &&\
sudo apt-get update &&\
sudo apt-get install sublime-text &&\
echo neofetch >> /home/ubuntu/.zshrc &&\
sudo chsh -s /bin/zsh ubuntu
echo ******end of script*****' >> /home/ubuntu/.package_install &&
sudo chmod u+x /home/ubuntu/.package_install &&
echo "FINISH CONFIGURATION IN TERMINAL APP" &&
shutdown -h now
##	end of copypaste

#in terminal app
sudo do-release-upgrade
#change release schedule from lts to normal 
sudo nano /etc/update-manager/release-upgrades 
sudo do-release-upgrade
sudo do-release-upgrade