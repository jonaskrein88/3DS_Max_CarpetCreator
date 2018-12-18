
from Deadline.Scripting import *
from DeadlineUI.Controls.Scripting.DeadlineScriptDialog import DeadlineScriptDialog

from subprocess import call
from time import sleep 

import thread
import os


# status 	0 rendering, 1 rendered, 2 post-processing 3 post-processed
# filepath 
# backgroundimage path
# outpath






def __main__( *args ):

	global scriptDialog

	scriptDialog = DeadlineScriptDialog()
	scriptDialog.SetSize(350,100)
	scriptDialog.SetTitle("Carpet PSD Listener")
	scriptDialog.AddGrid()
	absButton = scriptDialog.AddControlToGrid( "AbsButton", "ButtonControl", "Start", 0, 2, expand=False )
	stopButton = scriptDialog.AddControlToGrid( "StopButton", "ButtonControl", "Stop", 2, 2, expand=False )
	absButton.ValueModified.connect(AbsButtonPressed)
	stopButton.ValueModified.connect(StopButtonPressed)

	scriptDialog.closeEvent = stop

	scriptDialog.EndGrid()
	scriptDialog.ShowDialog( False )


def loop():
	i = 0
	while running and i < 10:
		print("updating")
		iterate_jobs()
		sleep(5)
		i = i + 1



def iterate_jobs():

	scriptPath = "X:\\05_Benutzerordner\\Jonas\\rnd\carpet_tools\\post.vbs"
	ids = RepositoryUtils.GetJobIds(True)
	jobs = [RepositoryUtils.GetJob(i, True) for i in ids]
	carpets = [j for j in jobs if j.ExtraInfo0 == "CarpetGenerator" and j.Status == 3]

	for j in carpets:
		status 			= int(j.ExtraInfo1)
		filepath 		= j.ExtraInfo2
		backgroundimage = j.ExtraInfo3
		outpath 		= j.ExtraInfo4

		if status == 0:
			print("Processing " + j.Name)
			j.ExtraInfo1 	= "1"
			RepositoryUtils.SaveJob(j)
			success = call("cscript " + scriptPath + " " + filepath + " " + backgroundimage + " " + outpath)
			if success == 99:
				j.ExtraInfo1 	= "2"
				RepositoryUtils.SaveJob(j)
				print("success")
			else: 
				print("Failed")


def run():
	print("starting")
	thread.start_new_thread(loop,())
	
	
def stop( *args ):
	global running
	print("stop")
	running = False


def AbsButtonPressed( *args ):
	global running
	running = True
	print(running)
	run()


def StopButtonPressed( *args ):
	stop()
	