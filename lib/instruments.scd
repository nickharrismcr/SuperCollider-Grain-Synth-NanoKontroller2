//------------------------------------------------------------------------------------------------------------------------
// collection of instruments
(

	list:nil,
	active:nil,
	max:nil,
	mappings:nil,
	proto:nil,
	tracefunc:nil,
	soloed:-1,
	m_trace: { 
		arg self,t;
		//t.debug("Trace");
	},
	m_init: {
		arg self,mappings,proto;

		self.list.do {
			arg inst;

			inst.grain.free;
			inst.rev.free;
			inst.del.free;
		};
		self.list.free;
		self.list=Array.new(8);
		self.active=0;
		self.max=0;
		if ((self.mappings==nil), { self.mappings=mappings; });
		if ((self.proto==nil), { self.proto=proto; });
	},
	m_active: { 
		arg self;
		self.list.at(self.active);
	},
	m_get: { 
		arg self,id;
		self.list.at(id);
	},
	m_set_active: {
		arg self,id;
		self.active=id;
		self.list.at(self.active).active = true;
	},
	m_store_active_parameters: {
		arg self;
		self.m_active().m_store_parameters();
	},
	//------------------------------------------------------------------------------------------------------------------------
	// add a new instrument
	m_new_instrument: {

		arg self,soundfile;
		var new_inst,slider;

		self.m_trace("new_instrument");
		{
			self.m_set_all_inactive();
			self.max=self.max + 1;
			new_inst = Event.new(40,self.proto);
			new_inst.m_init();
			new_inst.m_load_sound_file(soundfile);
			new_inst.m_start_synths();
			new_inst.m_set_controller_defaults();
			self.list.add(new_inst);
			self.active=self.max - 1;
			self.m_store_active_parameters();

			// wire MIDI cc change to instrument control change
			NotificationCenter.register( \midi, \midi_in, new_inst, {
				| name,val|
				new_inst.m_setcontrol(name,val);
			});
			NotificationCenter.notify(\instruments,\changed_inst,self.active);

		}.defer;
	},
	//------------------------------------------------------------------------------------------------------------------------
	// add a new instrument, cloning currently active 
	m_new_instrument_clone: {

		arg self;
		var new_inst,slider,params,soundfile;

		self.m_trace("new_instrument_clone");
		{
			if ( (self.max < 8), {
				self.m_store_active_parameters();
				params=self.m_active().params.deepCopy;
				soundfile = self.m_active().soundfilename; 
				self.m_new_instrument(soundfile);
				self.m_active().params=params.deepCopy;
				self.m_active().m_set_synth();
			});
			self.m_trace("f_new_instrument done");

		}.defer;
	},
	//------------------------------------------------------------------------------------------------------------------------
	// select instrument
	m_set_instrument: {

		arg self,inst_no;

		self.m_trace("set instrument % ".format(inst_no));
		if (( inst_no < self.max ), {

			self.m_store_active_parameters();
			self.m_set_all_inactive();
			self.m_set_active(inst_no);
			self.m_load_active_parameters();
			self.m_update_gui_grain_display();
			NotificationCenter.notify(\instruments,\changed_inst,self.active);
		});
	},
	m_prev_instrument: {
		arg self;
		if ((self.active > 0),{
			self.m_set_instrument(self.active -1 );
		});
	},
	m_next_instrument: {
		arg self;
		if ((self.active < (self.max - 1)),{
			self.m_set_instrument(self.active + 1 );
		});
	},
	//---------------------------------------------------------------------------------------------------------------------------------------------
	// solo selected instrument
	m_toggle_solo: {
		arg self,inst_id;

		// channel already solo'd, unmute all
		if (( inst_id == self.soloed ),{
			self.m_trace("unsolo channel %".format(inst_id));
			self.list.do {
				arg inst;
				inst.m_set_mute(false);
			};
			self.soloed = -1;
		},{
		// solo a new channel
			self.m_trace("new solo channel %".format(inst_id));
			self.list.do {
				arg inst;
				inst.m_set_mute(true);
				if (( inst.id == inst_id ),{
					inst.m_set_mute(false);
				});
			};
			self.soloed = inst_id;	
		});
	},
	//---------------------------------------------------------------------------------------------------------------------------------------------
	// hide all soundfileviews then show the currently active one - run on change of instrument
	m_update_gui_grain_display: {

		arg self;
		{
			self.m_trace("update_gui_grain_display");
			self.list.do {
				arg inst;

				if (( inst != nil ),{
					if ((inst.active),{
						inst.soundFileView.visible = true;
					},
					{
						inst.soundFileView.visible = false;
					});
				});
			};
			self.m_trace("update_gui_grain_display done");
		}.defer;
	},
	//------------------------------------------------------------------------------------------------------------------------
	// set all instruments in g_instruments to inactive
	m_set_all_inactive: {

		arg self;
		self.m_trace("m_set_all_inactive");
		self.list.do {
			|inst|
			inst.active=false;
		};
		self.m_trace("m_set_all__inactive done");
	},
	//------------------------------------------------------------------------------------------------------------------------
	// load mappings from save for currently active instrument for display
	m_load_active_parameters: {

		arg self;
		var inst,mapping;

		self.m_trace("Load active parameters ");
		inst=self.m_active();
		inst.params.keysValuesDo {

			arg k,v;

			self.m_trace("Load active parameters % = % ".format(k,v));
			mapping=self.mappings.m_get(k);
			if ((mapping[\name]!=nil),{
				mapping[\lastval]=v;
				mapping[\matched]=false;
				NotificationCenter.notify(\inst,\cc_change,Array.with(mapping[\name],mapping[\lastval],false));
			});
		};
		self.m_trace("Load active parameters done");
	},
	//---------------------------------------------------------------------------------------------------------------------------------------------
	// randomize a patch
	m_randomize_active: {
		arg self;
		var inst;

		inst=self.m_active();
		self.mappings.m_get_all().keysValuesDo {

			arg name,mapping;
			var val;

			if ((mapping[\randomizable]==true),{
				val=exprand(1,127).floor;
				mapping.func(val,inst);
				mapping[\lastval]=val;
				mapping[\matched]=false;
				NotificationCenter.notify(\inst,\cc_change,Array.with(mapping[\name],mapping[\lastval],false));
			});
		};
	},
	//------------------------------------------------------------------------------------------------------------------------
	// save patch (all instruments/scenes)
	m_save_patch: {

		arg self,filename;
		var patchfile,params;

		patchfile=File(filename,"w");

		self.m_store_active_parameters();
		self.list.do {
			arg inst,inst_index;
			patchfile.write("*,%,%\n".format(inst_index,inst.soundfilename));
			inst.params.keysValuesDo {
				arg key,value;
				patchfile.write("+,%,%,%\n".format(inst_index,key,value));
			};
			patchfile.write("@,\n");
			( inst.scenes != nil).if {
				inst.scenes.do {
					arg scene,scene_index;
					( scene != nil ).if {
						scene.keysValuesDo {
							arg key,value;
							patchfile.write("=,%,%,%,%\n".format(inst_index,scene_index,key,value));
						};
					};
				};
			};
		};
		patchfile.close;
	},
	//------------------------------------------------------------------------------------------------------------------------
	// load patch
	m_load_patch: {

		arg self,path;
		var patch, inst;

		self.m_trace("load_patch");

		self.m_init();

		patch=CSVFileReader.read(path);

		patch.do {
			arg line,index;
			var filename,cont,val,scene,mapping;

			if (( line[0]=="*" ), {
				filename = line[2];
				self.m_new_instrument(filename);
				inst=self.m_active();
				inst.scenes=Array.fill(8*8,nil);
				NotificationCenter.notify(\instruments,\changed_inst,self.active);
			});
			if (( line[0]=="+"),{
				cont=line[2];
				val=line[3].asInteger;
				inst.params.put(cont,val);
			});
			if (( line[0] == "@" ),{
				self.m_trace("Set parameters");
				inst.params.keysValuesDo {
					arg cont,val;
					mapping=self.mappings.m_get(cont);
					mapping[\lastval]=val;
					mapping.func(val,inst);
					mapping[\matched]=false;
					NotificationCenter.notify(\inst,\cc_change,Array.with(mapping[\name],mapping[\lastval],false));
				};
			});
			if (( line[0]=="="),{
				scene=line[2].asInteger;
				cont=line[3];
				val=line[4].asInteger;
				if (( inst.scenes[scene] == nil ),{
					inst.scenes[scene] = Dictionary.new();
				});
				inst.scenes[scene].put(cont,val);
				NotificationCenter.notify(\instruments,\load_scene,inst);
			});
		};
		self.m_trace("load_patch done");
	};


);

