#!/usr/bin/env python3
import os
import threading
import time

installPkg = input("Please enter the address of the script you would like to install  ")
pkgName = input("Please enter the name of the program  ")
pkgDescr = input("What does your package do? ")
pkgexeCmd = "sudo chmod +x {}".format(installPkg)
	#allowing executable rights for the script
touchCmd = "touch ~/quackrnt/{}".format(pkgName)
	#creating quack link to script
echoCmd = "echo {} >> ~/quackrnt/{}".format(installPkg, pkgName)
chmodCmd = "sudo chmod u+x ~/quackrnt/{}".format(pkgName)
	#putting script directory in quack link and giving link executable rights
mvCmd = "sudo mv ~/quackrnt/{} /bin".format(pkgName)
	#moving quack link to /bin directory
installLog = "echo {} >> ~/quackrnt/system-run/install-log".format(pkgName)
helpDescript = "echo -----{} >> ~/quackrnt/system-run/install-log".format(pkgDescr)
	#adding command and description to qk.list
def pkgExe():
	os.system(pkgexeCmd)
def touch():
	os.system(touchCmd)
def echo():
	os.system(echoCmd)
	os.system(chmodCmd)
	os.system(mvCmd)
def log():
	os.system(installLog)
	time.sleep(1)
	os.system(helpDescript)

t1 = threading.Thread(target=pkgExe)
t2 = threading.Thread(target=touch)
t3 = threading.Thread(target=echo)
t4 = threading.Thread(target=log)

t1.start()
t2.start()
t3.start()
t4.start()