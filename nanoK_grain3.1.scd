// =====================================================================================================================
// GRAIN SYNTH FOR NANOKONTROL 2
// =====================================================================================================================
// S buttons     : select instrument
// M buttons     : mute instrument
// R buttons     : select scene / (shift 1) store scene
// REW           : shift 1
// FF            : shift 2
// CYCLE	 : toggle instrument/mixer/fx ui
// SET MARKER    : new instrument
// PREV MARKER   : prev instrument
// NEXT MARKER   : next instrument
// KNOBS/SLIDERS : synth controls
// =====================================================================================================================

var f_trace,f_dump,f_debug,f_import;
var f_add_synthdefs;

var g_midi;
var f_midi_handler,f_set_general_actions;
var g_mode;

var g_disk,g_diskbuf,g_playing,g_mixbus,g_fxbus, g_out,g_fx;
var g_mappings,g_fx_mappings;
var f_make_mapping,f_make_fx_mapping;
var f_toggle_record, f_reset, f_toggle_play_from_disk;
var g_instrument_proto,f_make_instruments,g_instruments,g_recording,g_default_soundfile;

var g_gui;
var g_hbar_proto,g_vbar_proto;

var c_orange,c_darkorange,c_khaki,c_green,c_darkgreen,c_darkblue;

//-------------------------------------------------------------------------------------------------------------------------
// constants
//-------------------------------------------------------------------------------------------------------------------------
g_default_soundfile="C:/Users/nick/Music/samples/piano.wav";
c_orange=Color.new255(255,105,0);
c_darkorange=Color.new255(170,50,0);
c_darkgreen=Color.new255(0,70,0);
c_green=Color.new255(0,200,0);
c_khaki=Color.new255(50,50,0);
c_darkblue=Color.new255(0,0,150);

//-------------------------------------------------------------------------------------------------------------------------
// return a function or event defined in an external file : crude import functionality!
f_import= {
	arg script;
	var path,func;

	path=thisProcess.nowExecutingPath.dirname;
	script.debug("Import");
	this.compileFile(path++"/"++script).();
};
//------------------------------------------------------------------------------------------------------------------------
//------------------------------------------------------------------------------------------------------------------------
//------------------------------------------------------------------------------------------------------------------------
//------------------------------------------------------------------------------------------------------------------------
// Imports
//------------------------------------------------------------------------------------------------------------------------

// add sythdefs to server
f_add_synthdefs=f_import.("lib/add_synthdefs.scd"); 
// object to for MIDI input  
g_midi=f_import.("lib/midi_handler.scd");
// define midi cc/synth param mappings
f_make_mapping = f_import.("lib/mappings.scd");
// define midi cc/fx param mappings
f_make_fx_mapping = f_import.("lib/jpverb_mappings.scd");
// collection of instruments
f_make_instruments=f_import.("lib/instruments.scd").value;

//-------------------------------------------------------------------------------------------------------------------------
//-------------------------------------------------------------------------------------------------------------------------
//-------------------------------------------------------------------------------------------------------------------------
// MIDI CC event handler, calls midi object update method
f_midi_handler= {

	| p_val,p_num,p_chan,p_src |
	g_midi.m_update(p_val,p_num,p_chan,p_src);
};
//-------------------------------------------------------------------------------------------------------------------------
// debug utils
f_trace={
	|txt|
	txt.debug("Trace");
};
f_debug={
	|txt|
	txt.debug("Debug");
};

//-------------------------------------------------------------------------------------------------------------------------
// instrument object dump
f_dump={

	arg inst;

	if (( inst == nil ),
		{ "inst dump is nil".postln; },
		{ inst.keysValuesDo { |k,v|  "%:%".format(k,v).postln }; }
	);

};

//------------------------------------------------------------------------------------------------------------------------
//------------------------------------------------------------------------------------------------------------------------
//------------------------------------------------------------------------------------------------------------------------
//------------------------------------------------------------------------------------------------------------------------
//------------------------------------------------------------------------------------------------------------------------
//-----------------------------------------------------------------------------------------------------------------------
//-----------------------------------------------------------------------------------------------------------------------
f_set_general_actions={

	// register to handle various buttons to add/select instruments etc
	NotificationCenter.register( \midi, \midi_in, this, {
		arg name,val,num,inst;

		// prev/next/new instrument 
		if (( name == "PREV_MARK" && val == 127 ), { g_instruments.m_prev_instrument(); });
		if (( name == "NEXT_MARK" && val == 127 ), { g_instruments.m_next_instrument(); });
		if (( name == "SET_MARK"  && val == 127 ), { g_instruments.m_new_instrument_clone(); });

		// cycle toggles synth/mixer mode
		if (( name == "CYCLE" && val == 127 ), {
			switch (g_mode, 
				0,{ g_mode=1; },
				1,{ g_mode=2; },
				2,{ g_mode=0; });
			g_gui.m_show_mixer(g_mode);
		});
		// synth mode
		if (( g_mode == 0 ), {

			// save scenes
			if (( name.find( "SHIFT_1+R_BUTTON") != nil && val == 127 ), {
				num=name.split($_)[3].asInteger;	
				g_instruments.m_active().m_save_scene(num-1);
			});

			// load scenes
			if (( name.beginsWith( "R_BUTTON")  && val == 127 ), {
				num=name.split($_)[2].asInteger;	
				g_instruments.m_active().m_load_scene(num-1);
			});

			// select active instrument
			if (( name.beginsWith( "S_BUTTON")  && val == 127 ), {
				num=name.split($_)[2].asInteger;	
				g_instruments.m_set_instrument(num-1);
			});

			// mute instrument
			if (( name.beginsWith( "M_BUTTON")  && val == 127 ), {
				num=name.split($_)[2].asInteger;	
				inst=g_instruments.m_get(num-1);
				if ((inst!=nil),{
					inst.m_toggle_mute();
				});
			});
			// solo instrument
			if (( name.beginsWith( "SHIFT_1+M_BUTTON")  && val == 127 ), {
				num=name.split($_)[3].asInteger;	
				g_instruments.m_toggle_solo(num-1);
			});
			// unset mixer slider matched flag
			if (( name.beginsWith("SLIDER" ) ), {
				num=name.split($_)[1].asInteger;	
				inst=g_instruments.m_get(num-1);
				if ((inst!=nil),{
					inst.m_unset_vol_match();
				});
			});	
			// unset mixer knob matched flag
			if (( name.beginsWith("KNOB" ) ), {
				num=name.split($_)[1].asInteger;	
				inst=g_instruments.m_get(num-1);
				if ((inst!=nil),{
					inst.m_unset_pan_match();
					inst.m_unset_aux_match();
				});
			});	
		});
		// mixer mode
		if (( g_mode == 1 ), {
			// set a mixer channel volume
			if (( name.beginsWith( "SLIDER_")), {
				num=name.split($_)[1].asInteger;	
				inst=g_instruments.m_get(num-1);
				if ((inst!=nil),{
					inst.m_setvol(val);
				});
			});
			// set a mixer channel pan
			if (( name.beginsWith( "KNOB_")), {
				num=name.split($_)[1].asInteger;	
				inst=g_instruments.m_get(num-1);
				if ((inst!=nil),{
					inst.m_setpan(val);
				});
			});
			// set a mixer channel aux
			if (( name.beginsWith( "SHIFT_1+KNOB_")), {
				num=name.split($_)[2].asInteger;	
				inst=g_instruments.m_get(num-1);
				if ((inst!=nil),{
					inst.m_setaux(val);
				});
			});
			// mute instrument
			if (( name.beginsWith( "M_BUTTON")  && val == 127 ), {
				num=name.split($_)[2].asInteger;	
				inst=g_instruments.m_get(num-1);
				if ((inst!=nil),{
					inst.m_toggle_mute();
				});
			});
			// solo instrument
			if (( name.beginsWith( "SHIFT_1+M_BUTTON")  && val == 127 ), {
				num=name.split($_)[3].asInteger;	
				g_instruments.m_toggle_solo(num-1);
			});
		});
		// fx mode
		if (( g_mode == 2 ), {
			var param,mapping;
			mapping=g_fx_mappings.m_get(name);
			if (( mapping != nil ), {
				param=mapping[\name];
				if (( val == mapping[\lastval]),{
					mapping[\matched]=true;
				});
				if (( mapping[\matched] == true ), {
					mapping[\lastval]=val;
					if (( mapping[\name] != nil ), {
						if (( mapping[\name] == "disk play vol"),{
							mapping.func(val,g_disk);
						},{
							mapping.func(val,g_fx);
						});
					});
				});
				NotificationCenter.notify(\fx,\cc_change,Array.with(param,val,mapping[\matched]));
			});

		});
	});
};

//------------------------------------------------------------------------------------------------------------------------
//------------------------------------------------------------------------------------------------------------------------
//------------------------------------------------------------------------------------------------------------------------
//------------------------------------------------------------------------------------------------------------------------
//------------------------------------------------------------------------------------------------------------------------
//------------------------------------------------------------------------------------------------------------------------
//-----------------------------------------------------------------------------------------------------------------------
//-----------------------------------------------------------------------------------------------------------------------
//------------------------------------------------------------------------------------------------------------------------
// object to hold an instrument

g_instrument_proto=(

	mappings:nil,
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

	m_init: {

		arg self;

		self.mappings=g_mappings;
		self.active=true;
		self.id = g_instruments.max - 1;
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
	},

	// on init, is registered to be called on \midi_in event
	m_setcontrol: {

		arg self,name,val;
		var mapping,lastvalue,matched,param,group;

		if ((self.active == true && g_mode == 0 ), {
			mapping=self.mappings.m_get(name);
			if (( mapping != nil ), {
				f_trace.(" inst id % : % = % => %  matched % ".format(self.id,name,val, mapping[\name], mapping[\matched] ));
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
	//------------------------------------------------------------------------------------------------------------------------
	// start synths for an instrument

	m_start_synths: {

		arg self;

		f_trace.("m_start_synths");
		self.out=Synth(\out, [ \in:self.outbus, \out: g_mixbus , \aux: g_fxbus, \auxlev: 0.0 ]);
		self.rev=Synth(\rev, [ \in:self.reverbbus, \out: self.outbus ]);
		self.del=Synth(\delay , [ \in:self.delaybus, \out: self.outbus, \buf1: self.delbuf1, \buf2: self.delbuf2 ]);
		self.grain=Synth(\grain, [ \out:self.outbus, \sendone: self.delaybus, \sendtwo: self.reverbbus,  \leftbuf:self.buf1, \rightbuf:self.buf2, \envbuf:self.envbuf, \id:self.id ]);
		f_trace.("m_start_synths done");

	},

	// set default values on all controllers
	m_set_controller_defaults: {

		arg self;
		g_mappings.m_get_all().keysValuesDo
		{
			|k,v|
			var param;
			v[\lastval]=v[\init];
			v[\matched]=false;

			if (( v[\name] != nil ), {
				param=v[\name];
				v.func(v[\init],self);
				f_trace.("Initialised % = % ".format(v[\name],v[\init]));
				NotificationCenter.notify(\inst,\cc_change,Array.with(param,v[\init],false));
			});
		};
	},

	//------------------------------------------------------------------------------------------------------------------------
	// set instrument volume 
	m_setvol: {
	
		arg self,val;

		f_trace.("setvol % % ".format(self.id, val));
		if (( self.vol_matched == false ),{
			if (( self.vol == val ),{
				self.vol_matched = true;
			});
		},{
			self.vol = val;
			self.out.set(\vol,self.vol.linlin(0,127,0.0,1.0 ));
		});
		g_gui.m_update_mixer();
	},
	//------------------------------------------------------------------------------------------------------------------------
	// set instrument pan 
	m_setpan: {
	
		arg self,val;
		
		f_trace.("setpan % % ".format(self.id, val));
		if (( self.pan_matched == false ),{
			if (( self.pan == val ),{
				self.pan_matched = true;
			});
		},{
			f_trace.("pan %".format(val));
			self.pan = val;
			self.out.set(\pan,self.pan.linlin(0,127,-1.0,1.0 ));
		});
		g_gui.m_update_mixer();
	},
	//------------------------------------------------------------------------------------------------------------------------
	// set instrument aux send
	m_setaux: {
	
		arg self,val;

		f_trace.("setaux % % ".format(self.id, val));
		if (( self.aux_matched == false ),{
			if (( self.aux == val ),{
				self.aux_matched = true;
			});
		},{
			self.aux = val;
			self.out.set(\auxlev,self.aux.linlin(0,127,0.0,1.0 ));
		});
		g_gui.m_update_mixer();
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
		NotificationCenter.notify(\instruments,\changed_inst,self.id);
	},
	//------------------------------------------------------------------------------------------------------------------------
	// set instrument mute ( used by solo ) 
	m_set_mute: {
		arg self,setting;
		f_trace.("set mute % % ".format(self.id, setting));
		if (( setting ) ,{
			self.mute=0.0;
		},{
			self.mute=1.0;
		});
		self.out.set(\vol,self.mute*self.vol.linlin(0,127,0.0,1.0 ));
		self.out.set(\auxlev,self.mute*self.aux.linlin(0,127,0.0,1.0 ));
		NotificationCenter.notify(\instruments,\changed_inst,self.id);
	},
	//------------------------------------------------------------------------------------------------------------------------
	//------------------------------------------------------------------------------------------------------------------------
	// mixer inst vol match status
	m_unset_vol_match: {

		arg self;
		self.vol_matched = false;
		g_gui.m_update_mixer();
	},
	//------------------------------------------------------------------------------------------------------------------------
	// mixer inst pan match status
	m_unset_pan_match: {

		arg self;
		self.pan_matched = false;
		g_gui.m_update_mixer();
	},
	//------------------------------------------------------------------------------------------------------------------------
	// mixer inst aux match status
	m_unset_aux_match: {

		arg self;
		self.aux_matched = false;
		g_gui.m_update_mixer();
	},
	//------------------------------------------------------------------------------------------------------------------------
	// store all mapping parameters 
	m_store_parameters:  {

		arg self;
		f_trace.("Store parameters ");
		self.mappings.m_get_all().keysValuesDo {

			arg k,v;
			f_trace.("Store parameters % = % ".format(v[\name],v[\lastval]));
			self.params.put(k,v[\lastval]);
		};
	},
	//------------------------------------------------------------------------------------------------------------------------
	// reset matched status of all params sharing this controller
	m_unmatch_group: {

		arg self,mapping;
		var group;

		f_trace.("m_unmatch_group");
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

		f_trace.("m_unmatch_group done");
	},
	//--------------------------------------------------------------------------------------------------------------------------
	// load a sound file
	m_load_sound_file:{

		arg self,filename;

		f_trace.("load_sound_file %".format(filename));
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
		self.soundFileView = SoundFileView.new(g_gui.win, Rect(30, 50, 1300, 300))
		.soundfile_(self.soundFile)
		.read(0, self.soundFile.numFrames)
		.gridColor_(Color.gray(0.3))
		.gridOn_(false)
		.setSelectionColor(0, c_darkorange)
		.setSelectionColor(1, Color.yellow);
		self.soundFileView.peakColor=Color.new255(200,100,0);
		self.soundFileView.rmsColor=Color.new255(200,150,0);
		f_trace.("load_sound_file done");
	},
	//------------------------------------------------------------------------------------------------------------------------
	// replace a sound file
	m_replace_soundfile: {

		arg self,path;

		f_trace.("replace_soundfile");
		self.m_load_sound_file(path);
		self.grain.free;

		self.grain=Synth(\grain, [ \out:self.outbus, \sendone: self.delaybus, \sendtwo: self.reverbbus,  \leftbuf:self.buf1, \rightbuf:self.buf2, \envbuf:self.envbuf, \id:self.id ]);
		self.m_set_controller_defaults();
		f_trace.("replace_soundfile done");
	},
	//------------------------------------------------------------------------------------------------------------------------
	// load instrument scene into current params
	m_load_scene: {

		arg self,scene;
		var slot,mapping,params;

		f_trace.("f_load_scene slot %".format(scene));
		self.scene=scene;
		slot=self.scene + ( self.bank * 8);
		params=self.scenes.at(slot);
		if ((params != nil ), {
			self.params=params.deepCopy;
			self.m_set_synth();
		});


		f_trace.("f_load_scene done");
	},
	//------------------------------------------------------------------------------------------------------------------------
	// set synths for current params
	m_set_synth: {

		arg self;
		var mapping;

		self.params.keysValuesDo {
			arg cont,val;

			mapping=g_mappings.m_get(cont);

			mapping[\lastval]=val;
			mapping.func(val,self);
			mapping[\matched]=false;
			NotificationCenter.notify(\inst,\cc_change,Array.with(mapping[\name],mapping[\lastval],false));
		};
		NotificationCenter.notify(\instruments,\load_scene,self);

		f_trace.("f_load_scene done");
	},
	//------------------------------------------------------------------------------------------------------------------------
	// store current params as instrument scene
	m_save_scene: {

		arg self,scene;
		var slot;

		g_instruments.m_store_active_parameters();
		self.scene=scene;
		slot=self.scene + ( self.bank * 8);
		self.scenes.put(slot,self.params.deepCopy);
		NotificationCenter.notify(\instruments,\save_scene,self);
		f_trace.("m_save_scene done");
	}


);
//------------------------------------------------------------------------------------------------------------------------
//------------------------------------------------------------------------------------------------------------------------
//------------------------------------------------------------------------------------------------------------------------
//------------------------------------------------------------------------------------------------------------------------
// start looping an audio file from disk
f_toggle_play_from_disk = {

	arg path;
	var sf;
	if ((g_playing),{
		f_trace.("Stop playing");
		g_diskbuf.free;
		g_disk.free;
		g_playing=false;
	},{
		sf=SoundFile.new;
		sf.openRead(path);
		if ((sf.numChannels == 2),{
			f_trace.("Start playing");
			g_diskbuf = Buffer.cueSoundFile(s,path,0,2);
			g_disk=Synth(\disk, [ \out:g_mixbus, \bufnum:g_diskbuf ]);
		},{
			"Must be a stereo soundfile".postln;
		});
		g_playing=true;
	});
};
//---------------------------------------------------------------------------------------------------------------------------------------------
// toggle recording mode

f_toggle_record = {

	if (( g_recording.not ), {
			g_recording = true;
			s.record;
		},{
			g_recording = false;
			s.stopRecording;
		}
	);

};

//---------------------------------------------------------------------------------------------------------------------------------------------
// go back to initial state
f_reset={

	var inst;

	g_instruments.m_init(g_mappings,g_instrument_proto,f_trace);
	g_instruments.m_new_instrument(g_default_soundfile);
	g_mappings.m_clear_all_matches();
	NotificationCenter.notify(\instruments,\changed_inst,g_instruments.active);
};

//------------------------------------------------------------------------------------------------------------------------
//------------------------------------------------------------------------------------------------------------------------
//------------------------------------------------------------------------------------------------------------------------
//------------------------------------------------------------------------------------------------------------------------
//------------------------------------------------------------------------------------------------------------------------
//------------------------------------------------------------------------------------------------------------------------
//------------------------------------------------------------------------------------------------------------------------
//------------------------------------------------------------------------------------------------------------------------
//------------------------------------------------------------------------------------------------------------------------
// prototype object for horizontal slider
g_hbar_proto = (

	view:0,
	val:0.5,
	color:c_orange,
	addit: {

		arg ev,parent,rect,color;
		var bar;

		// (1) create a UserView
		bar = UserView(parent,rect) ;
		bar.background_(Color.black);
		// (2) define a drawing function using Pen
		bar.drawFunc = {
			// Draw the fill

			Pen.fillColor = ev.color;
			Pen.addRect(Rect(1,1, (bar.bounds.width*ev.val)-2,bar.bounds.height-2));
			Pen.fill;

			// Draw the frame
			Pen.strokeColor = c_darkorange;
			Pen.width=2;
			Pen.addRect(Rect(0,0, bar.bounds.width,bar.bounds.height));
			Pen.stroke;
		};
		bar.refresh;
		ev.view=bar;
	},
	updateit: {
		arg ev,v;
		{
			ev.val=v;
			ev.view.refresh;
		}.defer;
	},
	setcolor: {
		arg ev,v;
		{
			ev.color=v;
			ev.view.refresh;
		}.defer;
	}
);

//------------------------------------------------------------------------------------------------------------------------
// prototype object for vertical slider
g_vbar_proto = (

	view:0,
	val:0.0,
	color:c_darkorange,
	addit: {

		arg ev,parent,rect,color;
		var bar;

		// (1) create a UserView
		bar = UserView(parent,rect) ;

		bar.background_(Color.black);
		// (2) define a drawing function using Pen
		bar.drawFunc = {
			// Draw the fill

			Pen.fillColor = ev.color;
			Pen.addRect(Rect( 1, bar.bounds.height, (bar.bounds.width)-2,1.0-(bar.bounds.height*ev.val)-2));
			Pen.fill;

			// Draw the frame
			Pen.strokeColor = Color.red;
			Pen.width=2;
			Pen.addRect(Rect(0,0, bar.bounds.width,bar.bounds.height));
			Pen.stroke;
		};
		bar.refresh;
		ev.view=bar;
		f_trace.("vbar added");
	},
	updateit: {
		arg ev,v;
		{
			f_trace.("vbar update %".format(v));
			ev.val=v;
			ev.view.refresh;
		}.defer;
	},
	setcolor: {
		arg ev,v;
		{
			ev.color=v;
			ev.view.refresh;
		}.defer;
	}
);


//------------------------------------------------------------------------------------------------------------------------
// GUI
g_gui=(
	win:nil,
	scene_items:nil,
	inst_items:nil,
	mixer_levels:nil,
	mixer_pans:nil,
	mixer_auxs:nil,
	bank_items:nil,
	params:nil,
	parampanel:nil,
	mixerpanel:nil,
	fxparams:nil,
	fxpanel:nil,
	// construct the gui
	m_init_gui: {
		arg self;

		var l_scene_item_panel, l_bank_item_panel, l_inst_item_panel, l_cont_list;
		var l_inst, l_scene_items, l_bank_items, l_inst_items;
		var l_randomize_button, l_load_patch_button, l_save_patch_button;
		var l_record_button, l_load_file_button, l_reset_button;
		var l_play_from_disk_button;
		var l_counter,l_panel2;

		f_trace.("init_gui");

		self.win = Window.new("NanoKontrol 2 Granulator", Rect(50, 50, 1400, 800), false).front;
		self.win.background = Color.grey(0.1, 0.9);


		self.mixerchans=Array.new(8);
		self.params=Dictionary.new();
		self.fxparams=Dictionary.new();

		self.parampanel=CompositeView.new(self.win,Rect(30,400,1000,550));
		self.parampanel.decorator=FlowLayout(self.parampanel.bounds);

		// controllers are in a dictionary, which is unordered.
		// we need to sort them by the controllers \order property before adding to the guinst.

		l_cont_list = Array.new;
		g_mappings.m_get_all().collect({
			|item,key|  l_cont_list=l_cont_list.add([ item[\order],item ]);
		});

		l_counter=0;
		l_cont_list.sort( { |a,b| a[0] < b[0] }).do ({

			arg x;
			var l_controller,l_name,l_text,l_bar;

			l_controller=x[1];
			l_name=l_controller[\name];

			if ((l_counter == 0 ), {
				l_panel2=CompositeView.new(self.parampanel,Rect(0,0,120,150)).background_(c_khaki);
				l_panel2.decorator=FlowLayout(l_panel2.bounds);
			});

			l_text=StaticText.new(l_panel2,110@20 ).background_(Color.gray(0.1)).stringColor_(Color.white).align_(\center);
			l_text.font = Font("Monaco",10);
			l_text.string_(l_name);
			if ((l_name == nil ), { l_text.visible_(false); });

			l_text=StaticText.new(l_panel2,20@20 ).background_(Color.gray(0.5)).stringColor_(Color.black).align_(\center);
			l_text.string_("%".format(l_controller[\init]));
			l_text.font = Font("Monaco",10);
			if ((l_name == nil ), { l_text.visible_(false); });

			if (( l_name != nil ), {
				l_bar=g_hbar_proto.copy;
				l_bar.addit(l_panel2,Rect(0,0,88,20),c_orange);
				l_bar.updateit(0.5); 
			});
			self.params.put(l_name,[ l_text,l_bar ]);

			l_counter = l_counter + 1;
			if ((l_counter == 3 ), { l_counter = 0; } );
		});


		self.mixerpanel=CompositeView.new(self.win,Rect(30,400,1000,550));
		self.mixerpanel.decorator=FlowLayout(self.mixerpanel.bounds);
		self.mixerpanel.visible_(false);

		l_counter=0;
		8.do {
			arg i;
			var l_controller,l_name,l_text,l_item;

			l_panel2=CompositeView.new(self.mixerpanel,Rect(0,0,120,150)).background_(c_khaki);
			l_panel2.decorator=FlowLayout(l_panel2.bounds);
			l_item=StaticText.new(l_panel2,110@20 ).background_(Color.gray(0.1)).stringColor_(Color.white).align_(\center);
			l_item.font = Font("Monaco",10);
			l_item.string_("Level %".format(i+1));
			l_text=StaticText.new(l_panel2,20@20 ).background_(Color.gray(0.5)).stringColor_(Color.black).align_(\center);
			l_text.string_("64");
			l_text.font = Font("Monaco",10);
			l_item=g_hbar_proto.copy;
			l_item.addit(l_panel2,Rect(0,0,88,20),c_orange);
			l_item.updateit(1.0); 
			self.mixer_levels = self.mixer_levels.add([l_text,l_item]);


			l_item=StaticText.new(l_panel2,110@20 ).background_(Color.gray(0.1)).stringColor_(Color.white).align_(\center);
			l_item.font = Font("Monaco",10);
			l_item.string_("Pan %".format(i+1));
			l_text=StaticText.new(l_panel2,20@20 ).background_(Color.gray(0.5)).stringColor_(Color.black).align_(\center);
			l_text.string_("64");
			l_item=g_hbar_proto.copy;
			l_item.addit(l_panel2,Rect(0,0,88,20),c_orange);
			l_item.updateit(0.5); 
			self.mixer_pans = self.mixer_pans.add([l_text,l_item]);


			l_item=StaticText.new(l_panel2,110@20 ).background_(Color.gray(0.1)).stringColor_(Color.white).align_(\center);
			l_item.font = Font("Monaco",10);
			l_item.string_("Aux send %".format(i+1));
			l_text=StaticText.new(l_panel2,20@20 ).background_(Color.gray(0.5)).stringColor_(Color.black).align_(\center);
			l_text.string_("0");
			l_item=g_hbar_proto.copy;
			l_item.addit(l_panel2,Rect(0,0,88,20),c_orange);
			l_item.updateit(0.0); 
			self.mixer_auxs = self.mixer_auxs.add([l_text,l_item]);
		};

		self.fxpanel=CompositeView.new(self.win,Rect(30,400,1000,550));
		self.fxpanel.decorator=FlowLayout(self.fxpanel.bounds);

		l_cont_list = Array.new;
		g_fx_mappings.m_get_all().collect({
			|item,key|  l_cont_list=l_cont_list.add([ item[\order],item ]);
		});

		l_counter=0;
		l_cont_list.sort( { |a,b| a[0] < b[0] }).do ({

			arg x;
			var l_controller,l_name,l_text,l_bar;

			# z,l_controller = x; 
			l_name=l_controller[\name];

			if ((l_counter == 0 ), {
				l_panel2=CompositeView.new(self.fxpanel,Rect(0,0,120,150)).background_(c_khaki);
				l_panel2.decorator=FlowLayout(l_panel2.bounds);
			});

			l_text=StaticText.new(l_panel2,110@20 ).background_(Color.gray(0.1)).stringColor_(Color.white).align_(\center);
			l_text.font = Font("Monaco",10);
			l_text.string_(l_name);
			if ((l_name == nil ), { l_text.visible_(false); });

			l_text=StaticText.new(l_panel2,20@20 ).background_(Color.gray(0.5)).stringColor_(Color.black).align_(\center);
			l_text.string_("%".format(l_controller[\init]));
			l_text.font = Font("Monaco",10);
			if ((l_name == nil ), { l_text.visible_(false); });

			if (( l_name != nil ), {
				l_bar=g_hbar_proto.copy;
				l_bar.addit(l_panel2,Rect(0,0,88,20),c_orange);
				l_bar.updateit(0.5); 
			});
			self.fxparams.put(l_name,[ l_text,l_bar ]);
			l_counter = l_counter + 1;
			if ((l_counter == 3 ), { l_counter = 0; } );

		});
		self.fxpanel.visible_(false);



		l_scene_item_panel=CompositeView.new(self.win,Rect(30,730,1400,25));
		l_scene_item_panel.decorator=FlowLayout(l_scene_item_panel.bounds);

		self.scene_items=Array.fill(8, {
			|i|
			var l_item;
			l_item=StaticText.new(l_scene_item_panel,50@20).background_(c_darkgreen).string_("scene %".format(i+1)).align_(\center);
			l_item.font = Font("Monaco",10);
		});

		l_bank_item_panel=CompositeView.new(self.win,Rect(30,760,900,25));
		l_bank_item_panel.decorator=FlowLayout(l_bank_item_panel.bounds);

		self.bank_items=Array.fill(8, {
			|i|
			var l_item;
			l_item=StaticText.new(l_bank_item_panel,50@20).background_(c_darkblue).string_("bank %".format(i+1)).align_(\center);
			l_item.font = Font("Monaco",10);
		});

		l_inst_item_panel=CompositeView.new(self.win,Rect(30,0,900,25));
		l_inst_item_panel.decorator=FlowLayout(l_bank_item_panel.bounds);

		self.inst_items=Array.fill(8, {
			|i|
			var l_item;
			l_item=StaticText.new(l_inst_item_panel,50@20).background_(c_orange).string_("inst %".format(i+1)).align_(\center);
			l_item.font = Font("Monaco",10);
		});

		//update_gui_bank_items.(inst);
		self.m_update_gui_inst_items();

		l_play_from_disk_button=Button.new(self.win,Rect(700,760,70,20));
		l_play_from_disk_button.states_([[ "Play", c_orange, Color.black ], [ "Stop", Color.black, c_orange ]]);
		l_play_from_disk_button.font = Font("Monaco",10);
		l_play_from_disk_button.action = {
			|view|
			if ((g_playing.not), {
				FileDialog.new({ |paths|
					f_toggle_play_from_disk.(paths[0]);
				},
				nil,
				0,
				0
				);
			},{
				f_toggle_play_from_disk.();
			});
		};

		l_randomize_button=Button.new(self.win,Rect(800,760,70,20));
		l_randomize_button.font = Font("Monaco",10);
		l_randomize_button.states_([[ "Random", Color.cyan, Color.black ]]);
		l_randomize_button.action = {
			|view|
			g_instruments.m_randomize_active();
		};


		l_save_patch_button=Button.new(self.win,Rect(900,760,70,20));
		l_save_patch_button.states_([[ "Save", Color.green, Color.black ]]);
		l_save_patch_button.font = Font("Monaco",10);
		l_save_patch_button.action = {
			|view|
			FileDialog.new({ |paths|
				g_instruments.m_save_patch(paths[0]);
			},
			nil,
			0,
			1,
			false,
			"C:\Users\nick\Documents\SC"
			);
		};



		l_load_patch_button=Button.new(self.win,Rect(1000,760,70,20));
		l_load_patch_button.states_([[ "Load", Color.blue, Color.black]]);
		l_load_patch_button.font = Font("Monaco",10);
		l_load_patch_button.action = {
			|view|
			FileDialog.new({ |paths|
				g_instruments.m_load_patch(paths[0]);
			},
			nil,
			0,
			0,
			false,
			"C:\Users\nick\Documents\SC"
			);
		};

		l_load_file_button=Button.new(self.win,Rect(1100,760,70,20));
		l_load_file_button.states_([[ "New Sample", Color.yellow, Color.black ]]);
		l_load_file_button.font = Font("Monaco",10);
		l_load_file_button.action = {
			|view|
			FileDialog.new({ |paths|
				l_inst=g_instruments.m_active();
				l_inst.m_replace_soundfile(paths[0]);
			},
			nil,
			0,
			0
			);
		};



		l_record_button=Button.new(self.win,Rect(1200,760,70,20));
		l_record_button.states_([[ "Record", Color.white, Color.black ], [ "Stop", Color.black, Color.red ]]);
		l_record_button.font = Font("Monaco",10);
		l_record_button.action = {
			|view|
			f_toggle_record.();
		};

		l_reset_button=Button.new(self.win,Rect(1300,760,70,20));
		l_reset_button.states_([[ "Reset", Color.magenta, Color.black ]]);
		l_reset_button.font = Font("Monaco",10);
		l_reset_button.action = {
			|view|
			f_reset.();
		};

		self.win.front;
		f_trace.("init_gui done");

		NotificationCenter.register(\inst,\cc_change,self.win, {
			arg name,val,matched;
			self.m_update_inst_gui(name,val,matched);
		});

		NotificationCenter.register(\fx,\cc_change,self.win, {
			arg name,val,matched;
			self.m_update_fx_gui(name,val,matched);
		});

		NotificationCenter.register( \instruments, \changed_inst, self.win, {
			arg id;

			self.m_update_gui_inst_items();
			self.m_update_gui_grain_window(g_instruments.m_active());
			self.m_update_gui_scene_items(g_instruments.m_active());
			g_mappings.m_clear_all_matches();
		});

		NotificationCenter.register( \instruments, \save_scene, self.win, {
			arg inst;
			self.m_update_gui_scene_items(inst);
		});

		NotificationCenter.register( \instruments, \load_scene, self.win, {
			arg inst;
			self.m_update_gui_scene_items(inst);
		});

		NotificationCenter.register( \instruments, \grain_window, self.win, {
			arg inst;
			self.m_update_gui_grain_window(inst);
		});
		// prevent rescheduling
		nil;
	},
	//---------------------------------------------------------------------------------------------------------------------------------------------
	// update the scene buttons ( active, in use, unused )
	m_update_gui_scene_items: {

		arg self,inst;
		var snap;

		{
			f_trace.("update_gui_scene_items");
			self.scene_items.do {

				arg x,i;

				x.background_(c_darkgreen);
				snap=inst.scenes[i+(inst.bank*8)];

				if (( snap != nil ),{

					self.scene_items[i].background_(c_green);

					if (( inst.scene != nil), {

						if ( ( (( 8 * inst.bank) + i ) == inst.scene ), {
							self.scene_items[i].background_(Color.cyan);
						})
					});
				});
			};
			f_trace.("update_gui_scene_items done");
		}.defer;
	},

	//---------------------------------------------------------------------------------------------------------------------------------------------
	// update the sample position cursor 
	m_update_gui_play_pos: {

		arg self,inst_id,framepos;
		{
			var inst;

			inst=g_instruments.list[inst_id];
			inst.soundFileView.setSelection(1, [ framepos.floor,(inst.soundFile.numFrames/1100) ]);
		}.defer;
	},

	//---------------------------------------------------------------------------------------------------------------------------------------------
	// refresh the slider position etc of a gui inst parameter item
	m_update_inst_gui: {

		arg self, param , val, matched ;
		{
			var item,text,bar;
			f_trace.("update_gui_inst_param v % p % m % ".format(val,param,matched));

			if (( param != nil ),{
				item=self.params.at(param);
				if (( item != nil ), {

					# text, bar = item;
					if (( val != nil), {
						text.string_("%".format(val));
						bar.updateit(val.linlin(0,127,0.0,1.0));
					});

					if (( matched == true ),{
						text.background_(Color.green);
						bar.setcolor(Color.white);
					},
					{
						text.background_(c_darkgreen);
						bar.setcolor(c_orange);
					});
				});
			});

			f_trace.("update_gui_inst_param done");
		}.defer;
	},
	//---------------------------------------------------------------------------------------------------------------------------------------------
	// refresh the slider position etc of a gui fx parameter item
	m_update_fx_gui: { 

		arg self, param , val, matched ;
		{
			var item,text,bar;
			f_trace.("update_gui_fx_param v % p % m % ".format(val,param,matched));

			item=self.fxparams.at(param);

			if (( item == nil ), { "item is nil".postln; });

			if (( item != nil ), {

				# text, bar = item;
				if (( val != nil), {
					text.string_("%".format(val));
					bar.updateit(val.linlin(0,127,0.0,1.0));
				});

				if (( matched == true ),{
					text.background_(Color.green);
					bar.setcolor(Color.white);
				},
				{
					text.background_(c_darkgreen);
					bar.setcolor(c_orange);
				});
			});

			f_trace.("update_gui_fx_param done");
		}.defer;
	},

	//---------------------------------------------------------------------------------------------------------------------------------------------
	// update the waveform display selection
	m_update_gui_grain_window: {

		arg self,inst;

		var pos,size;

		{
			f_trace.("f_update_gui_grain_window");
			pos=inst.soundFileView.numFrames * ( inst.sample_pos_fine + inst.sample_pos - ( inst.scan_width/2 ));
			size=inst.soundFileView.numFrames * inst.scan_width;

			if ( size < 5000,{ size =5000; });
			inst.soundFileView.setSelection(0,[ pos, size ]);
			f_trace.("f_update_gui_grain_window done");
		}.defer;
	},
	//---------------------------------------------------------------------------------------------------------------------------------------------
	// set state of inst buttons ( active, in use, unused, muted )
	m_update_gui_inst_items: {

		arg self;
		{
			f_trace.("update_gui_inst_items");
			self.inst_items.do {

				arg item,id;
				var inst;

				item.background_(c_darkorange);

				inst=g_instruments.list.at(id);

				if (( inst != nil ),{

					item.background_(c_orange);
					if (( inst[\mute] == 0.0 ), {
						item.background_(Color.gray(0.25));
					});

					if (( g_instruments.active == id),{
						item.background_( Color.new255(255,200,0) );
						if ((inst[\mute] == 0.0 ), {
							item.background_(Color.gray(0.5));
						});
					});
				});
			};
			f_trace.("update_gui_inst_items done");
		}.defer;
	},
	//---------------------------------------------------------------------------------------------------------------------------------------------
	// show/hide mixer
	m_show_mixer: {

		arg self,mode;
		f_trace.("show mixer %".format(mode));
		{
			switch (mode,
				0, {
					self.mixerpanel.visible_(false);
					self.parampanel.visible_(true);
					self.fxpanel.visible_(false);
				},
				1, {
					self.mixerpanel.visible_(true);
					self.parampanel.visible_(false);
					self.fxpanel.visible_(false);
				},
				2, {
					self.mixerpanel.visible_(false);
					self.parampanel.visible_(false);
					self.fxpanel.visible_(true);
				}
			);
		}.defer;
	},
	//---------------------------------------------------------------------------------------------------------------------------------------------
	// update mixer panel sliders
	m_update_mixer: {

		arg self;
		{
			f_trace.("f_update_mixer");

			self.mixer_levels.do {

				arg item,id;
				var inst,text,bar;

				inst=g_instruments.list.at(id);

				if (( inst != nil ),{
					# text,bar = item;		
					text.string_("%".format(inst.vol));
					bar.updateit(inst.vol.linlin(0,127,0.0,1.0));
					bar.setcolor(c_darkorange);
					if (( inst.vol_matched == true ),{
						bar.setcolor(c_orange);
					});
				});
			};
			self.mixer_pans.do {

				arg item,id;
				var inst,text,bar;

				inst=g_instruments.list.at(id);

				if (( inst != nil ),{
					# text,bar = item;
					text.string_("%".format(inst.pan));
					bar.updateit(inst.pan.linlin(0,127,0.0,1.0));
					bar.setcolor(c_darkorange);
					if (( inst.pan_matched == true ),{
						bar.setcolor(c_orange);
					});
				});
			};
			self.mixer_auxs.do {

				arg item,id;
				var inst,text,bar;

				inst=g_instruments.list.at(id);

				if (( inst != nil ),{
					# text,bar = item;
					text.string_("%".format(inst.aux));
					bar.updateit(inst.aux.linlin(0,127,0.0,1.0));
					bar.setcolor(c_darkorange);
					if (( inst.aux_matched == true ),{
						bar.setcolor(c_orange);
					});
				});
			};
			f_trace.("f_update_mixer done");
		}.defer;
	},
	//---------------------------------------------------------------------------------------------------------------------------------------------
	// update fx panel sliders
	m_update_mixer: {

		arg self;
		{
			f_trace.("f_update_fx");

			self.mixer_levels.do {

				arg item,id;
				var inst,text,bar;

				inst=g_instruments.list.at(id);

				if (( inst != nil ),{
					# text,bar = item;		
					text.string_("%".format(inst.vol));
					bar.updateit(inst.vol.linlin(0,127,0.0,1.0));
					bar.setcolor(c_darkorange);
					if (( inst.vol_matched == true ),{
						bar.setcolor(c_orange);
					});
				});
			};
			self.mixer_pans.do {

				arg item,id;
				var inst,text,bar;

				inst=g_instruments.list.at(id);

				if (( inst != nil ),{
					# text,bar = item;
					text.string_("%".format(inst.pan));
					bar.updateit(inst.pan.linlin(0,127,0.0,1.0));
					bar.setcolor(c_darkorange);
					if (( inst.pan_matched == true ),{
						bar.setcolor(c_orange);
					});
				});
			};
			self.mixer_auxs.do {

				arg item,id;
				var inst,text,bar;

				inst=g_instruments.list.at(id);

				if (( inst != nil ),{
					# text,bar = item;
					text.string_("%".format(inst.aux));
					bar.updateit(inst.aux.linlin(0,127,0.0,1.0));
					bar.setcolor(c_darkorange);
					if (( inst.aux_matched == true ),{
						bar.setcolor(c_orange);
					});
				});
			};
			f_trace.("f_update_mixer done");
		}.defer;
	}

);

//------------------------------------------------------------------------------------------------------------------------
//------------------------------------------------------------------------------------------------------------------------
//------------------------------------------------------------------------------------------------------------------------
//------------------------------------------------------------------------------------------------------------------------
//------------------------------------------------------------------------------------------------------------------------
//------------------------------------------------------------------------------------------------------------------------
//-----------------------------------------------------------------------------------------------------------------------
//-----------------------------------------------------------------------------------------------------------------------
// MAIN
//-----------------------------------------------------------------------------------------------------------------------
CmdPeriod.add( { s.freeAll; Buffer.freeAll; Window.closeAll; });
NotificationCenter.clear;

MIDIClient.init;
MIDIIn.connectAll;
MIDIFunc.cc(f_midi_handler);

g_recording = false;
g_mode = 0;

f={
	f_set_general_actions.();
	g_mappings=f_make_mapping.();
	g_mappings.m_init();
	g_fx_mappings=f_make_fx_mapping.();
	g_fx_mappings.m_init();
	f_add_synthdefs.();
	g_instruments=f_make_instruments.();
	g_instruments.m_init(g_mappings,g_instrument_proto,f_trace);
	g_gui.m_init_gui.();
	nil;
};
AppClock.sched(1,f);

{
	2.wait;
	g_mixbus = Bus.audio(s,2);
	g_fxbus = Bus.audio(s,2);
	g_diskbuf = Buffer.alloc(s,2,2);
	g_out=Synth(\out, [ \in:g_mixbus , \out: 0, \vol: 1.0 ]);
	g_fx=Synth(\jpv, [ \in:g_fxbus, \out: g_mixbus ]);
	g_playing=false;
	g_instruments.m_new_instrument(g_default_soundfile);

}.fork;

// handler to update GUI play cursor from position sent from grain Synth
o=OSCFunc( {
	|msg, time, addr, recvPort|

	var inst_id=msg[2];
	var framepos=msg[3];
	g_gui.m_update_gui_play_pos(inst_id,framepos);

},'/tr',s.addr)
