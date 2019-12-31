//------------------------------------------------------------------------------------------------------------------------
// object to hold an instrument
(

	mappings:nil,
	multi:nil,
	id:nil,
	active:false,
	params:nil,
	out:nil,
	grain:nil,
	del:nil,
	rev:nil,
	soundfilename:nil,
	soundFileView:nil,
	scene:0,
	bank:0,
	parameters:nil,
	scenes:nil,
	buf1:nil,
	buf2:nil,
	delbuf1:nil,
	delbuf2:nil,
	envbuf:nil,
	outbus:nil,
	reverbbus:nil,
	delaybus:nil,
	sample_rate:nil,
	fine_rate:nil,
	mute:1.0,
	vol:127,
	vol_matched:false,
	pan:64,
	pan_matched:false,
	aux:0,
	aux_matched:false,
	mygui:nil,
	trace:true,
	m_trace:{
		arg self,s;
		(self.trace).if { s.debug("Instrument");};
	},
	m_init: {

		arg self,gui,mappings,multi;

		self.m_trace("init");
		self.mappings=mappings;
		self.mygui=gui;
		self.multi=multi;
		self.active=true;
		self.id = self.multi.inst_count - 1;
		self.params = Dictionary.new(80);
		self.sample_pos=0.5;
		self.scan_width=0.5;
		self.scan_dir=1;
		self.sample_rate=1;
		self.fine_rate=0;
		self.scan_rate_range=0.1;
		self.grain_dur=0.1;
		self.sample_pos_fine=0;
		self.bank=0;
		self.scene=0;
		self.scenes=Array.fill(8*8,nil);

		self.outbus=Bus.audio(s,2);
		self.delaybus=Bus.audio(s,2);
		self.reverbbus=Bus.audio(s,2);
		self.delbuf1=Buffer.alloc(s,44100*8,1);
		self.delbuf2=Buffer.alloc(s,44100*8,1);
		self.m_trace("init done");
	},

	// on init, is registered to be called on \midi_in event
	m_setcontrol: {

		arg self,name,val;
		var mapping,lastvalue,matched,param,group;

		self.m_trace("setcontrol % % ".format(name,val));

		if ((self.active == true && self.mygui.m_get_mode() == 0 ), {
			mapping=self.mappings.m_get(name);
			if (( mapping != nil ), {
				self.m_trace(" inst id % : % = % => %  matched % ".format(self.id,name,val, mapping[\name], mapping[\matched] ));
				param=mapping[\name];
				self.m_unmatch_group(mapping);
				if (( val == mapping[\lastval]),{
					mapping[\matched]=true;
				});
				if (( mapping[\matched] == true ), {
					mapping[\lastval]=val;
					if (( mapping[\name] != nil ), {
						mapping.func(val,self);
					});
				});
				NotificationCenter.notify(\inst,\cc_change,Array.with(param,val,mapping[\matched]));
			});
		});
	},
	m_setcontrol_gui: {

		arg self,name,val;
		var mapping,param,group;

		self.m_trace("setcontrol % % ".format(name,val));

		if ((self.active == true && self.mygui.m_get_mode() == 0 ), {
			mapping=self.mappings.m_get(name);
			if (( mapping != nil ), {
				param=mapping[\name];
				mapping[\lastval]=val;
				if (( mapping[\name] != nil ), {
					mapping.func(val,self);
				});
				NotificationCenter.notify(\inst,\cc_change,Array.with(param,val,mapping[\matched]));
			});
		});
	},
	//------------------------------------------------------------------------------------------------------------------------
	// start synths for an instrument

	m_start_synths: {

		arg self;

		self.m_trace("m_start_synths");
		self.out=Synth(\out, [ \in:self.outbus, \out: self.multi.mixbus , \aux: self.multi.fxbus, \auxlev: 0.0 ]);
		self.rev=Synth(\rev, [ \in:self.reverbbus, \out: self.outbus ]);
		self.del=Synth(\delay , [ \in:self.delaybus, \out: self.outbus, \buf1: self.delbuf1, \buf2: self.delbuf2 ]);
		self.grain=Synth(\grain, [ \out:self.outbus, \sendone: self.delaybus, \sendtwo: self.reverbbus,  \leftbuf:self.buf1, \rightbuf:self.buf2, \envbuf:self.envbuf, \id:self.id ]);
		self.m_trace("m_start_synths done");

	},

	// set default values on all controllers
	m_set_controller_defaults: {

		arg self;
		self.mappings.m_get_all().keysValuesDo
		{
			|k,v|
			var param;
			v[\lastval]=v[\init];
			v[\matched]=false;

			if (( v[\name] != nil ), {
				param=v[\name];
				v.func(v[\init],self);
				self.m_trace("Initialised % = % ".format(v[\name],v[\init]));
				NotificationCenter.notify(\inst,\cc_change,Array.with(param,v[\init],false));
			});
		};
	},

	//------------------------------------------------------------------------------------------------------------------------
	// set instrument volume 
	m_setvol: {
	
		arg self,val,forced;

		self.m_trace("setvol % % ".format(self.id, val));
		if (( (self.vol_matched == false) && (forced.not)),{
			if (( self.vol == val ),{
				self.vol_matched = true;
			});
		},{
			self.vol = val;
			self.out.set(\vol,self.vol.linlin(0,127,0.0,1.0 ));
		});
		NotificationCenter.notify(\inst,\mixchange);
	},
	//------------------------------------------------------------------------------------------------------------------------
	// set instrument pan 
	m_setpan: {
	
		arg self,val;
		
		self.m_trace("setpan % % ".format(self.id, val));
		if (( self.pan_matched == false ),{
			if (( self.pan == val ),{
				self.pan_matched = true;
			});
		},{
			self.m_trace("pan %".format(val));
			self.pan = val;
			self.out.set(\pan,self.pan.linlin(0,127,-1.0,1.0 ));
		});
		NotificationCenter.notify(\inst,\mixchange);
	},
	//------------------------------------------------------------------------------------------------------------------------
	// set instrument aux send
	m_setaux: {
	
		arg self,val;

		self.m_trace("setaux % % ".format(self.id, val));
		if (( self.aux_matched == false ),{
			if (( self.aux == val ),{
				self.aux_matched = true;
			});
		},{
			self.aux = val;
			self.out.set(\auxlev,self.aux.linlin(0,127,0.0,1.0 ));
		});
		NotificationCenter.notify(\inst,\mixchange);
	},
	//------------------------------------------------------------------------------------------------------------------------
	// toggle instrument mute
	m_toggle_mute: {
		arg self;
		if (( self.mute == 0 ) ,{
			self.mute=1.0;
		},{
			self.mute=0.0;
		});
		self.out.set(\vol,self.mute*self.vol.linlin(0,127,0.0,1.0 ));
		self.out.set(\auxlev,self.mute*self.aux.linlin(0,127,0.0,1.0 ));
		NotificationCenter.notify(\multi,\changed_inst,self.id);
	},
	//------------------------------------------------------------------------------------------------------------------------
	// set instrument mute ( used by solo ) 
	m_set_mute: {
		arg self,setting;
		self.m_trace("set mute % % ".format(self.id, setting));
		if (( setting ) ,{
			self.mute=0.0;
		},{
			self.mute=1.0;
		});
		self.out.set(\vol,self.mute*self.vol.linlin(0,127,0.0,1.0 ));
		self.out.set(\auxlev,self.mute*self.aux.linlin(0,127,0.0,1.0 ));
		NotificationCenter.notify(\multi,\changed_inst,self.id);
	},
	//------------------------------------------------------------------------------------------------------------------------
	//------------------------------------------------------------------------------------------------------------------------
	// mixer inst vol match status
	m_unset_vol_match: {

		arg self;
		self.vol_matched = false;
		NotificationCenter.notify(\inst,\mixchange);
	},
	//------------------------------------------------------------------------------------------------------------------------
	// mixer inst pan match status
	m_unset_pan_match: {

		arg self;
		self.pan_matched = false;
		NotificationCenter.notify(\inst,\mixchange);
	},
	//------------------------------------------------------------------------------------------------------------------------
	// mixer inst aux match status
	m_unset_aux_match: {

		arg self;
		self.aux_matched = false;
		NotificationCenter.notify(\inst,\mixchange);
	},
	//------------------------------------------------------------------------------------------------------------------------
	// store all mapping parameters 
	m_store_parameters:  {

		arg self;
		self.m_trace("Store parameters ");
		self.mappings.m_get_all().keysValuesDo {

			arg k,v;
			self.m_trace("Store parameters % = % ".format(v[\name],v[\lastval]));
			self.params.put(k,v[\lastval]);
		};
		self.m_trace("Store parameters done");
	},
	//------------------------------------------------------------------------------------------------------------------------
	// reset matched status of all params sharing this controller
	m_unmatch_group: {

		arg self,mapping;
		var group;

		self.m_trace("m_unmatch_group");
		group=mapping[\group];
		self.mappings.m_get_group(group).do {
			arg v;
			if ((v[\name] != nil ),{
				if ((v[\order] != mapping[\order] ),{
					v[\matched]=false;
					NotificationCenter.notify(\inst,\cc_change,Array.with(v[\name],nil,false));
				});
			});
		};

		self.m_trace("m_unmatch_group done");
	},
	//--------------------------------------------------------------------------------------------------------------------------
	// load a sound file
	m_load_sound_file:{

		arg self,filename;

		self.m_trace("load_sound_file %".format(filename));
		self.soundfilename=filename;
		self.soundFile=SoundFile.openRead(self.soundfilename);
		if ((self.soundFile == nil), {
			Error("Could not find % ".format(f)).throw;
		});
		self.buf1=Buffer.readChannel(s,self.soundFile.path,0,-1,[0]);
		if (( self.soundFile.numChannels == 2 ), {
			self.buf2=Buffer.readChannel(s,self.soundFile.path,0,-1,[1]);
		},
		{
			self.buf2=Buffer.readChannel(s,self.soundFile.path,0,-1,[0]);
		});

		// Sound File View
		if ( ( self.soundFileView != nil ), {
			self.soundFileView.destroy;
		});

		// TODO gui object should hold and manage sound file views
		self.m_trace("load_sound_file set view");
		self.m_trace("load_sound_file set view");
		self.soundFileView = SoundFileView.new(self.mygui.win, Rect(30, 50, 1300, 300))
		.soundfile_(self.soundFile)
		.read(0, self.soundFile.numFrames)
		.gridColor_(Color.gray(0.3))
		.gridOn_(false)
		.setSelectionColor(0, self.mygui.darkorange)
		.setSelectionColor(1, Color.yellow);
		self.soundFileView.peakColor=Color.new255(200,100,0);
		self.soundFileView.rmsColor=Color.new255(200,150,0);
		self.m_trace("load_sound_file done");
	},
	//------------------------------------------------------------------------------------------------------------------------
	// replace a sound file
	m_replace_soundfile: {

		arg self,path;

		self.m_trace("replace_soundfile");
		self.m_load_sound_file(path);
		self.grain.free;

		self.grain=Synth(\grain, [ \out:self.outbus, \sendone: self.delaybus, \sendtwo: self.reverbbus,  \leftbuf:self.buf1, \rightbuf:self.buf2, \envbuf:self.envbuf, \id:self.id ]);
		self.m_set_controller_defaults();
		self.m_trace("replace_soundfile done");
	},
	//------------------------------------------------------------------------------------------------------------------------
	// load instrument scene into current params
	m_load_scene: {

		arg self,scene;
		var slot,mapping,params;

		self.m_trace("f_load_scene slot %".format(scene));
		self.scene=scene;
		slot=self.scene + ( self.bank * 8);
		params=self.scenes.at(slot);
		if ((params != nil ), {
			self.params=params.deepCopy;
			self.m_set_synth();
		});


		self.m_trace("f_load_scene done");
	},
	//------------------------------------------------------------------------------------------------------------------------
	// set synths for current params
	m_set_synth: {

		arg self;
		var mapping;

		self.m_trace("m_set_synth");
		self.params.keysValuesDo {
			arg cont,val;

			mapping=self.mappings.m_get(cont);

			mapping[\lastval]=val;
			mapping.func(val,self);
			mapping[\matched]=false;
			NotificationCenter.notify(\inst,\cc_change,Array.with(mapping[\name],mapping[\lastval],false));
		};
		NotificationCenter.notify(\multi,\load_scene,self);

		self.m_trace("m_set_synth done");
	},
	//------------------------------------------------------------------------------------------------------------------------
	// store current params as instrument scene
	m_save_scene: {

		arg self,scene;
		var slot;

		self.m_trace("m_save_scene ");
		self.multi.m_store_active_parameters();
		self.scene=scene;
		slot=self.scene + ( self.bank * 8);
		self.scenes.put(slot,self.params.deepCopy);
		NotificationCenter.notify(\multi,\save_scene,self);
		self.m_trace("m_save_scene done");
	}


);
