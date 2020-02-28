
# Carpet Creation Documentation
short list of the scripts with Discription



### carpet_tool.ms

__the main ui and brain of the creation process__

- creates the pattern from csv 
- loads the room as xref 
- load the camera from file 
- selects the carpet for the rendermask
- submits the job 
- appends _Extrainfo_ to the job for postproduction(see below)

***

### CarpetPost.py

the script creates a listener in the deadline monitor which:

- checks if there are finished jobs (Status 3) with an ExtraInfo0 of type __CarpetGenerator__
- if found the _ExtraInfos1-4_ are read which are
>     1 -  status of the PostProduction
>     2 -  path to file
>     3 -  path to background image 
>     4 -  outputpath

- if ppStatus is 0 the __vbs script__ gets called with the parameters 2-4
- if successfull (errorcode 99 from vbs) the PostProductionStatus(ExtraInfo1) gets set to 2

***

### post.vbs

- the photoshop script that creates the final image 
- loads image of background
- loads rendering of carpet
- merges the two 
- creates a subtle drop shadow on the ground
