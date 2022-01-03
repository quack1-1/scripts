#!/usr/bin/env sh

#vmc start termina
lxc stop penguin --force && lxc rename penguin debian && lxc launch ubuntu:18.04 penguin && lxc exec penguin -- bash
#as root user
echo "UPDATING..\n" && apt update && echo "UPGRADING..\n" && apt upgrade && echo "deb https://storage.googleapis.com/cros-packages buster main" > /etc/apt/sources.list.d/cros.list && if [ -f /dev/.cros_milestone ]; then sudo sed -i "s?packages?packages/$(cat /dev/.cros_milestone)?" /etc/apt/sources.list.d/cros.list; fi && apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 1397BC53640DB551 && apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 7638D0442B90D010 && apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 04EE7237B7D453EC && apt update && apt install binutils && apt download cros-ui-config && ar x cros-ui-config_0.12_all.deb data.tar.gz && gunzip data.tar.gz && tar f data.tar --delete ./etc/gtk-3.0/settings.ini && gzip data.tar && ar r cros-ui-config_0.12_all.deb data.tar.gz && rm -rf data.tar.gz && apt install cros-guest-tools ./cros-ui-config_0.12_all.deb && rm cros-ui-config_0.12_all.deb && apt install adwaita-icon-theme-full && shutdown -h now

#in terminal app
sudo do-release-upgrade 
sudo nano /etc/update-manager/release-upgrades && sudo do-release-upgrade &&
sudo do-release-upgrade
echo "Script finished. Running neofetch to check"
neofetch

sudo add-apt-repository ppa:apt-fast/stable && sudo apt-get update && sudo apt-get install apt-fast && sudo apt-fast install gnome-tweaks nautilus gnome-terminal neofetch gedit eog celluloid && sudo cp /mnt/chromeos/GoogleDrive/MyDrive/linux-backups/quackrnt/system-run/pacapt.sh /usr/local/bin/pacapt && sudo chmod 755 /usr/local/bin/pacapt && sudo ln -sv /usr/local/bin/pacapt /usr/local/bin/pacman || true && sudo apt-fast install zsh 
sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" 
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git && echo "source ${(q-)PWD}/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" >> ${ZDOTDIR:-$HOME}/.zshrc && source ./zsh-syntax-highlighting/zsh-syntax-highlighting.zsh && sudo chsh -s /bin/zsh ubuntu && wget -qO - https://download.sublimetext.com/sublimehq-pub.gpg | sudo apt-key add - && echo "deb https://download.sublimetext.com/ apt/stable/" | sudo tee /etc/apt/sources.list.d/sublime-text.list && sudo apt-get update && sudo apt-get install sublime-text && /mnt/chromeos/GoogleDrive/MyDrive/linux-backups/quackrnt/Qogir-theme-master --logo debian --tweaks round && gnome-tweaks 
