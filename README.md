# scripts
linux scripts and related items

Dev machine is a 2017 Pixelbook i5, 8gb ram. 

Update goals:

	
	-auto updates
	
	-syntax wrapper
	
	-add parallel downloads for mass installs **implemented with apt-fast
		remvoe the dialog spam when apt-fast is downloading packages
	
	-convert system scripts from python to cpp (unsure if this is really worth it. cpp is overall the better 
	language to learn and use but many have said python is perfectly fine, which seems reasonable. 
	Might just want to do this due to my own ignorance in coding still. I'm learning though)
	
	-leaning into cli programs
	
	-manually push newest linux kernel beyond what ubuntu has provided (5.14 MAYBE 5.15)
	
	-get theme with no errors working and proper border outlines **changed to theme Ant/Ant-Nebula
	
	-get auto setup scripts working
	
	-get one time install instructions ironed out
	
	-get auto backup/restore
	

Development Updates:
12.14.21 attempting to push kernel version 5.15.x stable
```
wget -c https://kernel.ubuntu.com/~kernel-ppa/mainline/v5.15.8/amd64/linux-headers-5.15.8-051508_5.15.8-051508.202112141040_all.deb
wget -c https://kernel.ubuntu.com/~kernel-ppa/mainline/v5.15.8/amd64/linux-headers-5.15.8-051508-generic_5.15.8-051508.202112141040_amd64.deb
wget -c https://kernel.ubuntu.com/~kernel-ppa/mainline/v5.15.8/amd64/linux-image-unsigned-5.15.8-051508-generic_5.15.8-051508.202112141040_amd64.deb
wget -c https://kernel.ubuntu.com/~kernel-ppa/mainline/v5.15.8/amd64/linux-modules-5.15.8-051508-generic_5.15.8-051508.202112141040_amd64.deb
```
```
sudo dpkg -i *.deb
```
```
sudo shutdown -r now
```
```-uname -a``` showing kernel ```5.4.163-17363-g0022deef4e49``` even though ubuntu 21.10 should be 5.13? 

It appears the kernel is locked at 5.4. The default debian buster and bullseye installs Google ships the linux container with has the same kernels. 

I believe this kernel issue may be a limitation of LXD/LXC and not a google implemented one. It appears I do not fully understand what I'm trying to do (who would've though).

The kernel is not held in the container itself and rather in a vm that the container then runs inside. This is google's secure deployment method which is very interesting actually but leads to low user customizability in this aspect. I suppose not really an issue for them, though.

Always sending system related terminal commands to output file for uploading..

12.14.21 unenabling developer mode on chromebook and doing fresh install

Leaving snapd installed for now..

Main packages installed and htop reporting 9.8MB used ```(this is always wildly inaccurate to what chrome os is actually dedicating but it works for comparing container distros nonetheless)``` compared to the typical 12MB at initial startup and ~16MB after a while. 

Using ```top``` or ```free -h``` in termina rather than from the container itself, you can see memory/cpu usage including the kernel and everything else. I had not tested this before the previous installs but currently htop inside the container is reporting 39MiB used while free -h in termina is reporting 1.7GiB used. I don't know if there is a reliable conversion here but now you know. Update: They are not related. Usage in htop remains consistent with reboots while free -h changes dynamically as expected. htop shows user processes accurately but actual memory usage is not very reliable. Still can be used for container performance monitoring though.)

Added apt-fast wrapper for parallel apt downloads and then reroute duck package manager to call apt-fast. This requires aria2 to be installed.
	
	This has given duck automatic sudo priveledges. I am unsure if I will leave this as true for now. I like it, but it is insecure.

Sublime Text has problems with almost every theme without some in depth manually editing. I have absolutely no idea if this is true on normal linux installs, but using sublime's package installer works perfectly for themes. This is hardly relevant but I just spent the last 2 hours trying various code editors (vscode and atom for example refuse to take on the set gtk theme and default back to google's native look.) and I'm not going to forget how to get a decent WORKING option that also looks good. 

	I really wish vscode would properly theme though. I'm using the Ayu theme for both and vscode frankly looks better, 
	not to mention the multitude of better features.
	Sublime is cool though so I'm chilling. Vscode does work flawlessly outside of slightly choppier rendering 
	and the *somewhat* awkward google theme.
	(any hardware accelerated rendering struggles heavy, see firefox and discord for further evidence)
	
	yes im manually line breaking to avoid horizontal scrolling
	
I deleted the CrosAdapta theme (I only vaguely remember doing this, I'm going to be honest) but it seems the whole issue of using the default gtk theme instead of set one remains. Sometimes (primarily with Qt apps) apps will use chrome os' title bar (vscode and discord do this as well), other times they will use the default GTK theme (Would be CrosAdapta although it appears I successfully deleted it and now it goes to Adwaita. This is how firefox is behaving). I do not know how to change this, I thought it might be a GTK2 thing vs GTK3/GTK4 but it does not look like that is the case. ```Maybe I'll just keep removing themes from the system until it uses the one I want.```
