global xref_path = 		@"X:\02_Kunden\BAL\01_Basics\00_Datenbibliothek\Scenes\"
global pattern_path =	@"X:\02_Kunden\BAL\01_Basics\00_Datenbibliothek\CSV"
global thread_path = 	@"X:\02_Kunden\BAL\01_Basics\00_Datenbibliothek\Faeden\"
global output_path =  	@"X:\02_Kunden\BAL\01_Basics\00_Datenbibliothek\test\test_output"
global master_path = 	@"X:\02_Kunden\BAL\01_Basics\00_Datenbibliothek\Carpets\"
global master_file = 	"Carpet_Master.max"
global backGroundPath = @"X:\02_Kunden\BAL\01_Basics\00_Datenbibliothek\test\backgrounds\" 
global texture_path = 	@"X:\02_Kunden\BAL\01_Basics\00_Datenbibliothek\DistributionMaps\"

global out_type = 		"jpg"



global all_scenes, all_patterns, patterns, render_jobs, running



struct CSV_Parser (
	function get_filename p = (
		fname = pathConfig.stripPathToLeaf p
		substring fname 1 (fname.count - 4)
	),
	function parse_first_row row &ids &names = (
		ids = #()
		names = #()
		cols = filterString row ";"
		for col in cols do (
			numbers = FilterString col ":"
			append ids (numbers[1] as integer)
			append names numbers[2]
		)
		print names
	),
	function get_size lines &width &height = (
		height = lines.count - 4
		cols = filterString lines[5] ";"
		width = cols.count
		--print ("width: " + width as string)
		--print ("height: " + height as string)
	),
	function parse_to_textures importpath = (
		carpet_maps = #()
		local lines = (dotnetClass "System.IO.File").ReadAllLines importpath
		CSV_Parser.parse_first_row lines[1] &ids &names
		CSV_Parser.get_size lines &width &height
		
		for i = 1 to ids.count do append carpet_maps (carpet_map(bitmap width height color:red) names[i])
		
		-- create textures
		for i = 1 to height do (
			cols = FilterString lines[i+4] ";"
			rows_out = for id in ids collect #()

			for j in cols do (
				id = j as integer
				index = findItem ids id 
				for k = 1 to ids.count do (
					if k == index then append rows_out[k] (color 255 255 255)
					else append rows_out[k] (color 0 0 0)
				)
			)
			for k = 1 to ids.count do setPixels carpet_maps[k].texture [0,i-1] rows_out[k] 
		) 
		--for c in carpet_maps do display c.texture
		carpet_maps
		print carpet_maps
	),
	function cleanup_list &names isUsed = (
		for i = 1 to names.count do (
			if Not isUsed[i] then names[i] = undefined
		)
	),
	function parse_to_single_texture importpath &names &tex_path &tex_width &tex_height = (
		local lines = (dotnetClass "System.IO.File").ReadAllLines importpath
		CSV_Parser.parse_first_row lines[1] &ids &names
		CSV_Parser.get_size lines &tex_width &tex_height

		isUsed = for n in names collect false

		if (mod tex_height 2) == 0 then tex_height -= 1
		if (mod tex_width 2) == 0 then tex_width -= 1

		img_out = bitmap tex_width tex_height color:black

		for i = 1 to tex_height do 
		(
			cols = filterString lines[i+4] ";"
			row_out = #()

			for j = 1 to tex_width do 
			(
				id = cols[j] as integer
				index = findItem ids id
				isUsed[index] = true
				maxOps.colorById index &col
				if id == 0 then col = color 0 0 0 
				append row_out col
			)
			setPixels img_out [0,i-1] row_out
		)
		CSV_Parser.cleanup_list &names isUsed
		tex_path = texture_path + (CSV_Parser.get_filename importpath) + ".tif"
		img_out.filename = tex_path
		save img_out
	)
)

struct Render_Job (
	pattern,
	render_scene
)



if CarpetTool != undefined then DestroyDialog CarpetTool


rollout CarpetTool "CarpetTool" width:1124 height:780
(
	GroupBox 'grp1' "Add Jobs" pos:[4,10] width:470 height:510 align:#left
	GroupBox 'grp3' "Jobs to Submit" pos:[488,10] width:628 height:100 align:#left
	--multiListBox 'mlb_patterns' "Patterns" pos:[10,33] width:450 height:15 align:#left
	
	edittext 'edt_patterns' "CSV Path" pos:[14,550] width:450 height:17 across:2 align:#left
	edittext 'edt_output' "Output" pos:[14,700] width:450 height:17 across:2 align:#left
	button 'but_openOutput' "Open Output" pos:[11,726] width:79 height:21 align:#left
	checkbox 'chk_generate' "Only Generate Carpet" pos:[14,651] width:130 height:15 align:#left
	checkbox 'chk_noRender' "Do Not Render" pos:[14,671] width:95 height:15 align:#left tooltip:"Stops process before sending the first job"

	dotNetControl 'lv_patterns' "System.Windows.Forms.ListView" pos:[10,40] width:450 height:220 align:#left
	dotNetControl 'lv_scenes' "System.Windows.Forms.ListView"  pos:[10,275] width:450 height:200 align:#left
	dotNetControl 'lv_jobs' "System.Windows.Forms.ListView" pos:[496,40] width:612 height:435 align:#left 
 
	button 'but_go' "Submit Jobs" pos:[750,650]  align:#left height:60 width:120
	checkbutton 'chk_listen' "Post-Pro" pos:[900,650]  align:#left height:60 width:120 highlightColor:[0,200,0]

	button 'but_addJob' "Add Jobs" pos:[15,490] align:#left
	button 'but_clear' "Clear" pos:[500,490] align:#left


	fn get_filename p = (
		fname = pathConfig.stripPathToLeaf p
		substring fname 1 (fname.count - 4)
	)
	fn update_job_lv = (
		lv_jobs.items.clear()
		theRange = #()

		for i = 1 to render_jobs.count do 
		(
			j = render_jobs[i]
			li = dotNetObject "System.Windows.Forms.ListViewItem" (i as string)
			sub_li = li.SubItems.add (get_filename j.pattern)
			sub_li = li.SubItems.add (get_filename j.render_scene)
			if (mod i 2) == 0 then li.BackColor = (dotNetClass "System.Drawing.Color").fromARGB 30 40 30
			append theRange li
		)
		lv_jobs.Items.AddRange theRange
	)
	fn init_job_lv = (
		--lv_jobs.gridLines = true 
		lv_jobs.View = (dotNetClass "System.Windows.Forms.View").Details
		lv_jobs.fullRowSelect = true 
		lv_jobs.HideSelection = false
		lv_jobs.ForeColor = (dotNetClass "System.Drawing.Color").fromARGB 150 150 150 --128 128 128
		lv_jobs.BackColor = (dotNetClass "System.Drawing.Color").fromARGB 30 30 30
		lv_jobs.BackColor = (dotNetClass "System.Drawing.Color").fromARGB 20 30 20
		lv_jobs.Columns.add "" 50 
		lv_jobs.Columns.add "Pattern" 200 
		lv_jobs.Columns.add "Scene" 140
		update_job_lv()
	)
	fn init_pattern_lv = (
		lv_patterns.View = (dotNetClass "System.Windows.Forms.View").Details
		lv_patterns.fullRowSelect = true 
		lv_patterns.HideSelection = false
		lv_patterns.ForeColor = (dotNetClass "System.Drawing.Color").fromARGB 150 150 150 --128 128 128
		lv_patterns.BackColor = (dotNetClass "System.Drawing.Color").fromARGB 30 30 30
		lv_patterns.Columns.add "#" 30 
		lv_patterns.Columns.add "Name" 250
		lv_patterns.Columns.add "Info" 140
		lv_patterns.HeaderStyle = lv_patterns.HeaderStyle.None
	)
	fn init_scene_lv = (
		lv_scenes.View = (dotNetClass "System.Windows.Forms.View").Details
		lv_scenes.fullRowSelect = true 
		lv_scenes.HideSelection = false
		lv_scenes.ForeColor = (dotNetClass "System.Drawing.Color").fromARGB 150 150 150 --128 128 128
		lv_scenes.BackColor = (dotNetClass "System.Drawing.Color").fromARGB 30 30 30
		lv_scenes.Columns.add "#" 30 
		lv_scenes.Columns.add "Name" 250
		lv_scenes.Columns.add "Info" 140
		lv_scenes.HeaderStyle = lv_scenes.HeaderStyle.None
	)

	fn check_for_master pattern_name &master_name = (
		type = (FilterString pattern_name "_")[1]
		master_name = master_path + type + "_Master.max"
		doesFileExist master_name
	)
	fn load_specific_master pattern_name &rect &ground &forest = (

		master_exists =  check_for_master pattern_name &filepath
		master = (
			if master_exists then filepath
			else (master_path + master_file)
		)
		SetQuietMode true
		loaded = mergeMaxFile master #deleteOldDups #useMergedMtlDups quiet:true
		SetQuietMode false
		ground = getNodeByName "Carpet_Dimension"
		rect = getNodeByName "Carpet_Ground"
		forest = getNodeByName "Carpet_Forest"
		--clear_forest_objs forest

		-- save if not found
		/*if Not master_exists then (
			nodes =  #(rect, forest, ground)
			saveNodes nodes filepath
		)
		*/
	)
	fn does_carpet_exist carpet_name = (
		f = master_path + carpet_name + ".max"
		doesfileexist f
	)


	fn get_ini_settings sceneName &moveCam &moveCarpet = (
		iniPath = xref_path + "settings.ini"
		local w = getINISetting iniPath "default" "width" 
		local h = getINISetting iniPath "default" "height" 
		if w != "" then renderwidth = w as integer
		if h != "" then renderheight = h as integer

		local w = getINISetting iniPath sceneName "width" 
		local h = getINISetting iniPath sceneName "height" 
		if w != "" then renderwidth = w as integer
		if h != "" then renderheight = h as integer
			
		moveCam  = getINISetting iniPath "default" "moveCamera"
		local x = getINISetting iniPath sceneName "moveCamera"
		if x != "" then moveCam = x as booleanClass

		moveCarpet = getINISetting iniPath "default" "moveCarpet"
		local x = getINISetting iniPath sceneName "moveCarpet"
		if x != "" then moveCarpet = x as booleanClass
		print renderwidth
		print renderheight
		print moveCam 
		print moveCarpet
	)
	fn get_size_from_name n &w &h = (
		tokens = filterString n "_." 
		nums = filterString tokens[4] "x"
		w = nums[1] as integer
		h = nums[2] as integer
		print ("size: " + w as string + ", " + h as string)
	)
	fn read_xref_files = (
		lv_scenes.items.clear()
		all_scenes = getFiles (xref_path + "*.max")
		local names = for f in all_scenes collect pathConfig.stripPathToLeaf f
		theRange = #()

		for i = 1 to names.count do (
			li = dotNetObject "System.Windows.Forms.ListViewItem" (i as string)
			sub_li = li.SubItems.add names[i]
			if (mod i 2) == 0 then li.BackColor = (dotNetClass "System.Drawing.Color").fromARGB 40 40 40
			append theRange li
		)
		lv_scenes.Items.AddRange theRange
	)
	fn read_patterns = (
		lv_patterns.items.clear()
		all_patterns = getFiles (pattern_path + "\\" + "*.csv")
		theRange = #()

		for i = 1 to all_patterns.count do 
		(
			p = all_patterns[i]
			pattern_name = pathConfig.stripPathToLeaf p

			li = dotNetObject "System.Windows.Forms.ListViewItem" (i as string)

			error = ""
			if not (check_for_master pattern_name &x) then 
			(
				li.ForeColor = (dotNetClass "System.Drawing.Color").fromARGB 255 80 80
				error = "no master"
			)

			
			sub_li = li.SubItems.add pattern_name
			sub_li = li.SubItems.add error
			if (mod i 2) == 0 then li.BackColor = (dotNetClass "System.Drawing.Color").fromARGB 40 40 40
			append theRange li
		)
		lv_patterns.Items.AddRange theRange
	)


	fn open_thread name = (
		if name == undefined then return #()
		clearSelection()
		filename = thread_path + name + ".max"
		if (mergeMaxFile filename #select #AutoRenameDups #renameMtlDups quiet:true) then (
			print ("loaded " + filename)
			lod_only = for o in (getCurrentSelection()) where (classof o) == ForestLOD collect o
			return lod_only
		)
		else (
			print ("could not load " + filename) 
			return #()
		)
	)
	fn load_threads names = (
		SetQuietMode true
		arr = for n in names collect (open_thread n)
		SetQuietMode false
		arr
	)
	fn delete_threads arr = (
		for t in arr do (
			for x in t do delete x
		)
	)
	fn hide_threads = (
		l = LayerManager.getLayerFromName "BAL_Faeden"
		if l != undefined then l.on = false
	)


	fn open_master &rect &ground &forest = (
		SetQuietMode true
		loaded = mergeMaxFile (master_path + master_file) #deleteOldDups #useMergedMtlDups quiet:true
		SetQuietMode false
		--print loaded
		ground = getNodeByName "Carpet_Dimension"
		rect = getNodeByName "Carpet_Ground"
		forest = getNodeByName "Carpet_Forest"
	)
	fn rescale_master rect ground w h =  (
		ground.width 	= w
		ground.length = h 
		uv = rect.modifiers["UVW Map"]
		uv.width 	= w 
		uv.length 	= h
	)



	fn get_selected_xrefs = (
		if lv_scenes.SelectedItems.count == 0 then return undefined
		local selected = #()
		for i = 0 to (lv_scenes.SelectedItems.count-1) do (
			index = lv_scenes.SelectedItems.Item[i].index+1
			append selected all_scenes[index] 
		)
		selected
	)
	fn get_selected_patterns = (
		if lv_patterns.SelectedItems.count == 0 then return undefined
		local selected = #()
		for i = 0 to (lv_patterns.SelectedItems.count-1) do (
			index = lv_patterns.SelectedItems.Item[i].index+1
			append selected all_patterns[index] 
		)
		selected
	)
	fn refresh = (
		read_patterns()
		read_xref_files()
	)



	fn get_Camera xref = (
		cams = for o in xref.tree.children where ((superclassof o) == Camera) and (classof o != targetobject) collect o
		if cams.count > 0 then (
			--viewport.SetCamera cams[1]
			--print cams[1]
			return cams[1]
		)
		else messageBox "no camera found in xref"
	)


	fn load_scene s = (
		SetQuietMode true
		x = xrefs.addNewXRefFile s
		SetQuietMode false
		x
	)
	fn get_camera_from_scene s = (
		names = getmaxfileobjectnames filepath
		cam_names = for n in names where matchpattern n pattern:"*cam*" ignoreCase:true collect n

		mergeMAXFile filepath cam_names #select #deleteOldDups quiet:true

		objs = selection as array 
		cams = for o in objs where superclassof o == camera and classof o != targetobject collect o
		cam = cams[1]
		if cam == undefined then (
			print "could not load cam"
			return undefined
		)
		target = cam.target

		for o in objs where o != cam and o != target do delete o

		old_cam = getnodebyname "RENDERCAM"
		if old_cam != undefined then delete old_cam
		cam.name = "RENDERCAM"
		cam
	)
	fn copy_cam_from_xref xref = (
		cam = get_Camera xref
		SetQuietMode true
		new_cam = xrefs.addNewXRefObject xref.filename cam.name
		rec = new_cam.xrefRecord
		objXRefMgr.MergeRecordIntoScene rec
		if cam == undefined then messagebox "no camera"
		SetQuietMode false
		viewport.SetCamera new_cam
		new_cam.name = "RENDERCAM"
		print new_cam
		new_cam
	)
	fn unload_scene s = delete s

	fn unload_scenes = (
		arr = for i = 1 to xrefs.getXRefFileCount() collect xrefs.getXRefFile i
		for a in arr do delete a
	)


	fn submit_render_job out_name scene_name = (
		-- enable PSD 
		-- set PSD setTilings

		SetQuietMode false
		rendSaveFile = true
		rendOutputFilename = output_path + "\\" + out_name + "." + out_type
		psd_path = output_path + "\\" + out_name + ".psd"

		bg = backGroundPath + scene_name + ".jpg"

		post_out = output_path + "\\final\\"
		makeDir post_out

		-- submit
		global SMTDSettings
		global SMTDFunctions
		global SMTDPaths
		local theNetworkRoot = @"\\FILESERVER\sooii\_Basics\z_DeadlineRepo10"
		local remoteScript = theNetworkRoot + @"\submission\3dsmax\main\SubmitMaxToDeadline_Functions.ms"
		if not doesfileexist remoteScript then (
			out = "Deadline Repository not found\nCorrect Deadline Version?"
			messageBox out beep:false title: "Repo not found"
			return 0)
		fileIn remoteScript
		SMTDFunctions.loadSettings() 

		SMTDSettings.JobName = out_name
		SMTDSettings.Comment = "Sooii CarpetTool"
		SMTDSettings.ExtraInfo0 = "CarpetGenerator"
		SMTDSettings.ExtraInfo1 = "0"
		SMTDSettings.ExtraInfo2 = psd_path
		SMTDSettings.ExtraInfo3 = bg
		SMTDSettings.ExtraInfo4 = post_out

		if SMTDPaths.tempdir == undefined then (messagebox "no tempdir"; break)
		local maxFileToSubmit = SMTDPaths.tempdir + maxFileName
		SMTDFunctions.SaveMaxFileCopy maxFileToSubmit
		local SubmitInfoFile = SMTDPaths.tempdir + "\\max_submit_info.job"
		local JobInfoFile = SMTDPaths.tempdir+ "\\max_job_info.job"
		SMTDFunctions.CreateSubmitInfoFile SubmitInfoFile
		SMTDFunctions.CreateJobInfoFile JobInfoFile

		local initialArgs = "\""+SubmitInfoFile+"\" \""+JobInfoFile+"\" \""+maxFileToSubmit+"\""
		print initialArgs

		local result = SMTDFunctions.waitForCommandToComplete initialArgs SMTDSettings.TimeoutSubmission
		if result == #success then (
			print "Deadline::Job successfully submitted"
		)
		else (
			print "Submission Failed"
			break
		)
	)

	


	fn color_to_float c = (
		r = c.r as float / 255.
		g = c.g as float / 255.
		b = c.b as float / 255.
		[r,g,b]
	)
	fn add_to_forest forest geo id = (
		unhide objects
		if geo == undefined or not (isValidNode geo) then return undefined 
		--print geo
		local i = forest.geomlist.count + 1
		maxOps.colorById id &col

		forest.namelist.count = i
		forest.namelist[i] = ""
		forest.geomlist.count = i
		forest.tempidlist.count = i
		forest.tempnamelist.count = i
		forest.tempnamelist[i] = ""
		forest.cobjlist.count = i
		forest.usemeshdimlist.count = i
		forest.widthlist.count = i
		forest.heightlist.count = i
		forest.scalelist.count = i
		forest.zoffsetlist.count = i
		forest.centerlist.count = i
		forest.matlist.count = i
		forest.problist.count = i
		forest.coloridlist.count = i
		forest.radiuslist.count = i
		forest.specidlist.count = i
		forest.conamelist.count = i
		forest.conamelist[i] = ""
		forest.geomlist[i] = 1
		forest.tempnamelist[i] = "One Plane"
		forest.usemeshdimlist[i] = on
		forest.widthlist[i] = 200
		forest.heightlist[i] = 300
		forest.problist[i] = 100
		forest.coloridlist[i] = color_to_float col
		forest.specidlist[i] = 11
		forest.geomlist[i] 	= 2
		forest.cobjlist[i] 	= geo
		forest.matlist[i] 	= geo.material
		forest.namelist[i] = geo.name



		/*

		forest.namelist.count 		= i
		forest.geomlist.count 		= i
		forest.tempidlist.count 	= i
		forest.tempnamelist.count 	= i
		forest.tempnamelist[i] 		= ""
		forest.cobjlist.count 		= i

		
		forest.problist.count 		= i
		forest.coloridlist.count 	= i
		forest.matlist.count 		= i



		forest.tempnamelist[i] 		= "One Plane"
		forest.geomlist[i] 			= 2
		forest.problist[i] 			= 100
		forest.coloridlist[i] 		= color_to_float col
		forest.cobjlist[i] 			= geo
		forest.namelist[i] 			= geo.name
		forest.matlist[i] 			= geo.material
		*/
		--sceneMaterials["forest_automat_93DC7C90"].materialList[i].Diffuse = col
	)
	fn clear_forest_objs forest = (
		i = 1
		forest.namelist.count = i 
		forest.geomlist.count = i
		forest.tempidlist.count = i
		forest.tempnamelist.count = i
		forest.cobjlist.count = i
		forest.usemeshdimlist.count = i
		forest.widthlist.count = i
		forest.heightlist.count = i
		forest.scalelist.count = i
		forest.zoffsetlist.count = i
		forest.centerlist.count = i
		forest.matlist.count = i
		forest.problist.count = i
		forest.coloridlist.count = i
		forest.radiuslist.count = i
		forest.specidlist.count = i
		forest.conamelist.count = i
	)
	fn set_forest_objs forest arr = (
		for i = 1 to arr.count do 
		(
			objs = arr[i]
			for obj in objs do add_to_forest forest obj i
		)
	)
	fn set_forest_size forest width height tex_width tex_height = (
		forest.units_x = width * 2
		forest.units_y = height
		forest.pixels_x = tex_width
		forest.pixels_y = tex_height
	)



	fn get_psd = (
		for i = 1 to numEffects do (
			effect = (getEffect i)
			if classof effect == psd_manager then return effect
		)
		undefined
	)
	fn add_psd = (
		x = get_psd()
		if x != undefined then return x
		else (
			psd = psd_manager()
			addEffect psd
			return psd 
		)
	)
	fn enable_psd = (
		psd = add_psd()
		setActive psd true
		psd.outputRenderAs = 0
		psd.matchRenderOutputFilename = true
		psd.gammaCorrectRender = on
		psd.gammaCorrectConfig = 2
		psd.compatibility = 0
	)
	fn disable_psd = (
		psd = get_psd()
		if psd != undefined then setActive psd false
	)
	fn enable_render_mask = renderers.current.imageSampler_renderMask_type = 2

	fn render_settings = (
		re = renderers.current 
		re.imagesampler_type = 3 
		re.progressive_max_render_time = 2
	)

	fn clear_scene = (
		unhide objects
		unfreeze objects
		delete objects
		renderers.current.imageSampler_renderMask_type = 0
		disable_psd()
	)

	fn job_exists job = (
		for j in render_jobs do (
			if j.render_scene == job.render_scene and j.pattern == job.pattern then return true
		)
		false
	)
	fn create_jobs = (
		if render_jobs == undefined then global render_jobs = #()
		local render_scenes = get_selected_xrefs()
		local patterns = get_selected_patterns()

		for p in patterns do 
		(
			for s in render_scenes do 
			(
				new_job = Render_Job p s
				if not job_exists new_job then append render_jobs new_job
			)
		)
		update_job_lv()
	)


	fn main = (
		clearListener()
		clear_scene()

		render_scenes = get_selected_xrefs()
		local patterns = get_selected_patterns()


		for p in patterns do 
		(
			local pattern_name = (get_filename p)
			load_specific_master pattern_name &rect &ground &forest
	
			get_size_from_name pattern_name &width &height
			rescale_master rect ground width height

			local success = CSV_Parser.parse_to_single_texture p &thread_names &texPath &tex_width &tex_height

			forest.divtmap.fileName = texPath
			thread_geo = load_threads thread_names

			set_forest_objs forest thread_geo
			set_forest_size forest width height tex_width tex_height
			hide_threads()

			if chk_generate.checked then return 0

			--save carpet
			saveMaxFile (master_path + pattern_name + ".max") quiet:true

			enable_render_mask()
			enable_psd()

			for s in render_scenes do 
			(
				xref = load_scene s
				local scene_name = (get_filename s) 
				local out_name = pattern_name + "_" + scene_name
				print out_name
				--return 0

				
				unload_scene xref
				delete cam
			)
			delete_threads thread_geo
		)
		clear_scene()
	)



	fn submit_list = (

		if render_jobs == undefined or render_jobs.count == 0 then (messagebox "No jobs"; return 0)
		clearListener()
		clear_scene()
		unload_scenes()
		render_settings()

		local current_pattern = ""
		local forest
		local pattern_name 

		for job in render_jobs do 
		(
			local p = job.pattern

			if p != current_pattern then 
			(
				clear_scene()
				pattern_name = (get_filename p)
				load_specific_master pattern_name &rect &ground &forest
				if forest == undefined or NOT (isValidNode forest) then (print "forest problem";return 0)
		
				get_size_from_name pattern_name &width &height
				rescale_master rect ground width height

				local success = CSV_Parser.parse_to_single_texture p &thread_names &texPath &tex_width &tex_height

				forest.divtmap.fileName = texPath
				thread_geo = load_threads thread_names

				set_forest_objs forest thread_geo
				set_forest_size forest width height tex_width tex_height
				hide_threads()

				--save carpet
				saveMaxFile (master_path + pattern_name + ".max") quiet:true
			)

			current_pattern = p

			-- check if only generate
			if not chk_generate.checked then 
			(
				local s = job.render_scene 
				xref = load_scene s
				local scene_name = (get_filename s) 
				local out_name = pattern_name + "_" + scene_name

				get_ini_settings scene_name &moveCam &moveCarpet

				SetQuietMode true
				xref.disabled = false
				SetQuietMode false
				cam = copy_cam_from_xref xref
				select $*


				if chk_noRender.checked then return 0
				enable_render_mask()
				enable_psd()
				submit_render_job out_name scene_name
				--render vfb:true

				unload_scenes()
				disable_psd()
			)
		)
		clear_scene()
		messagebox "Done" beep:false
	)



	fn run_deadlineCommand= (
		script_path = @"X:\05_Benutzerordner\Jonas\rnd\carpet_tools\cmd.py"
		command = "\"C:\Program Files\Thinkbox\Deadline10\bin\Deadlinecommand\" ExecuteScript " + script_path
		hiddenDOSCommand command
	)
	fn loop = (
		running = true
		while running do 
		(
			print "Updating"
			run_deadlineCommand()
			sleep 10
		)
		print "Listener stopped"
	)
	on chk_listen changed state do (
		if state then (
			MainThread = dotnetobject "System.ComponentModel.BackGroundWorker"
			dotNet.addEventHandler MainThread "DoWork" loop
			MainThread.RunWorkerAsync()
		)
		else running = false
	)




	on edt_output changed txt do (output_path = txt; refresh())
	on edt_patterns changed txt do (pattern_path = txt; refresh())

	on CarpetTool open do (
		if render_jobs == undefined then global render_jobs = #()
		edt_output.text = output_path
		edt_patterns.text = pattern_path
		init_job_lv()
		init_pattern_lv()
		init_scene_lv()
		read_xref_files()
		read_patterns()
	)
	on but_go pressed do (
		--main()
		submit_list()
	)
	on but_clear pressed do (
		global render_jobs = #()
		update_job_lv()
	)

	--on but_openOutput pressed do shellLaunch "explorer.exe" output_path
	on but_openOutput pressed do HiddenDOSCommand ("start " +  output_path)

	on but_addJob pressed do create_jobs()
	


)
CreateDialog CarpetTool



