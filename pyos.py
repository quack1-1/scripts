#!/usr/bin/env python3
import os
import subprocess
import time
import threading

#startup for "computer". on button is a "1" otherwise it closes out
def startup():
    login = input("Please start\n")
    if login == "1":
        userLogin = input("Who is interacting? \n")
        print("Logging in with user {}".format(userLogin))
    if login != "1":
        print("Unknown startup code")
        exit()
#the "taskbar" if you will. report this at the end of any program otherwise main cmd wont be accessible
def options():
    print("")
    print("Programs Logout")
    cmdIn = input()
    if cmdIn == "programs":
        programs()
        options()
    if cmdIn == "logout":
        exit()
    #currently the programs exits if absolutely anything other than the predetermined options are entered
    #this includes typos, which is kind of annoying, however, i do not care enough to figure it out right now
    #if cmdIn != "programs", "logout", "calc":
        #print("Unknown command")
        #options()
    if cmdIn == "calc":
        calc()
        options()

def programs():
    os.system("cat /mnt/chromeos/GoogleDrive/MyDrive/linux-backups/python-bin/progams.txt")

def calc():
    x = input("Please enter a number: ")
    y = input("Please enter another number: ")
    cout = float(x) + float(y)
    print(cout)

startup()
options()
