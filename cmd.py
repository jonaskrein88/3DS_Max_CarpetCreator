# start deadline listener from maxscript


from Deadline.Events import *
from Deadline.Scripting import *

from subprocess import call
from time import sleep 

import os


# status    0 rendered, 1 post-processing 2 post-processed
# filepath 
# backgroundimage path
# outpath


def __main__( *args ):

    scriptPath = "X:\\05_Benutzerordner\\Jonas\\rnd\\carpet_tools\\post.vbs"

    if os.path.isfile(scriptPath):
        print("PS-Script found")
        ids = RepositoryUtils.GetJobIds(True)
        jobs = [RepositoryUtils.GetJob(i, True) for i in ids]
        carpets = [j for j in jobs if j.ExtraInfo0 == "CarpetGenerator" and j.Status == 3]

        for j in carpets:
            status          = int(j.ExtraInfo1)
            filepath        = j.ExtraInfo2
            backgroundimage = j.ExtraInfo3
            outpath         = j.ExtraInfo4

            if status == 0:
                print("Processing " + j.Name)
                j.ExtraInfo1    = "1"
                RepositoryUtils.SaveJob(j)
                success = call("cscript " + scriptPath + " " + filepath + " " + backgroundimage + " " + outpath)
                if success == 99:
                    j.ExtraInfo1    = "2"
                    RepositoryUtils.SaveJob(j)
                    print("success")
                else: 
                    print("failed")
    else:
        print("PS-Script not found")


    
        
