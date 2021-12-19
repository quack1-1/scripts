#!/usr/bin/env python3
import os
import time

pkgUninst = input("What package would you like to uninstall? ")
rmCmd = "sudo rm /bin/{}".format(pkgUninst)
output = "echo Testing {} removal..".format(pkgUninst)
testrm = "{}".format(pkgUninst)

os.system(rmCmd)
os.system(output)
time.sleep(2)
os.system(testrm)
