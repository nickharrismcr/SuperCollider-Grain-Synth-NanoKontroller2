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
var g_trace;

var f_trace,f_dump,f_debug,f_import;
var f_add_synthdefs;

var g_midi;
var f_midi_handler,f_set_general_actions;

var g_disk,g_diskbuf,g_playing;
var g_mappings,g_fx_mappings;
var f_make_mapping,f_make_fx_mapping;
var f_toggle_record, f_reset, f_toggle_play_from_disk;
var f_make_instrument,f_make_multi,f_make_gui;
var g_instrument,g_multi,g_recording,g_default_soundfile;
var g_gui;

//-------------------------------------------------------------------------------------------------------------------------
// constants
//-------------------------------------------------------------------------------------------------------------------------
g_default_soundfile="C:/Users/nick/Music/samples/whitenoise.wav";
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
// instrument 
f_make_instrument=f_import.("lib/instrument.scd").value;
// collection of instruments
f_make_multi=f_import.("lib/multi.scd").value;
// gui
f_make_gui=f_import.("lib/gui.scd").value;

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
	var txt;
	(g_trace).if { txt.debug("Main"); };
};
f_debug={
	var txt;
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
		if (( name == "PREV_MARK" && val == 127 ), { g_multi.m_prev_instrument(); });
		if (( name == "NEXT_MARK" && val == 127 ), { g_multi.m_next_instrument(); });
		if (( name == "SET_MARK"  && val == 127 ), { g_multi.m_new_instrument_clone(); });

		// cycle toggles synth/mixer mode
		if (( name == "CYCLE" && val == 127 ), {
			switch (g_gui.m_get_mode(), 
				0,{ g_gui.m_set_mode(1); },
				1,{ g_gui.m_set_mode(2); },
				2,{ g_gui.m_set_mode(0); });
			g_gui.m_show_mixer();
		});
		// synth mode
		if (( g_gui.m_get_mode() == 0 ), {

			// save scenes
			if (( name.find( "SHIFT_1+R_BUTTON") != nil && val == 127 ), {
				num=name.split($_)[3].asInteger;	
				g_multi.m_active().m_save_scene(num-1);
			});

			// load scenes
			if (( name.beginsWith( "R_BUTTON")  && val == 127 ), {
				num=name.split($_)[2].asInteger;	
				g_multi.m_active().m_load_scene(num-1);
			});

			// select active instrument
			if (( name.beginsWith( "S_BUTTON")  && val == 127 ), {
				num=name.split($_)[2].asInteger;	
				g_multi.m_set_instrument(num-1);
			});

			// mute instrument
			if (( name.beginsWith( "M_BUTTON")  && val == 127 ), {
				num=name.split($_)[2].asInteger;	
				inst=g_multi.m_get(num-1);
				if ((inst!=nil),{
					inst.m_toggle_mute();
				});
			});
			// solo instrument
			if (( name.beginsWith( "SHIFT_1+M_BUTTON")  && val == 127 ), {
				num=name.split($_)[3].asInteger;	
				g_multi.m_toggle_solo(num-1);
			});
			// unset mixer slider matched flag
			if (( name.beginsWith("SLIDER" ) ), {
				num=name.split($_)[1].asInteger;	
				inst=g_multi.m_get(num-1);
				if ((inst!=nil),{
					inst.m_unset_vol_match();
				});
			});	
			// unset mixer knob matched flag
			if (( name.beginsWith("KNOB" ) ), {
				num=name.split($_)[1].asInteger;	
				inst=g_multi.m_get(num-1);
				if ((inst!=nil),{
					inst.m_unset_pan_match();
					inst.m_unset_aux_match();
				});
			});	
		});
		// mixer mode
		if (( g_gui.m_get_mode() == 1 ), {
			// set a mixer channel volume
			if (( name.beginsWith( "SLIDER_")), {
				num=name.split($_)[1].asInteger;	
				inst=g_multi.m_get(num-1);
				if ((inst!=nil),{
					inst.m_setvol(val);
				});
			});
			// set a mixer channel pan
			if (( name.beginsWith( "KNOB_")), {
				num=name.split($_)[1].asInteger;	
				inst=g_multi.m_get(num-1);
				if ((inst!=nil),{
					inst.m_setpan(val);
				});
			});
			// set a mixer channel aux
			if (( name.beginsWith( "SHIFT_1+KNOB_")), {
				num=name.split($_)[2].asInteger;	
				inst=g_multi.m_get(num-1);
				if ((inst!=nil),{
					inst.m_setaux(val);
				});
			});
			// mute instrument
			if (( name.beginsWith( "M_BUTTON")  && val == 127 ), {
				num=name.split($_)[2].asInteger;	
				inst=g_multi.m_get(num-1);
				if ((inst!=nil),{
					inst.m_toggle_mute();
				});
			});
			// solo instrument
			if (( name.beginsWith( "SHIFT_1+M_BUTTON")  && val == 127 ), {
				num=name.split($_)[3].asInteger;	
				g_multi.m_toggle_solo(num-1);
			});
		});
		// fx mode
		if (( g_gui.m_get_mode() == 2 ), {
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
							mapping.func(val,g_multi.fx);
						});
					});
				});
				NotificationCenter.notify(\fx,\cc_change,Array.with(param,val,mapping[\matched]));
			});

		});
	});
	NotificationCenter.register(\gui,\toggle_play,this,{
		arg path;
		f_trace.("gui toggle play event");
		f_toggle_play_from_disk.(path);
	});
	NotificationCenter.register(\gui,\reset,this,{
		f_trace.("gui reset event");
		f_reset.();
	});
	NotificationCenter.register( \gui,\toggle_record,this,{
		f_trace.("gui toggle rec event");
		f_toggle_record.();
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
		f_trace.("Open % for playing ".format(path));
		sf=SoundFile.openRead(path);
		if ((sf.numChannels == 2),{
			f_trace.("Start playing");
			g_diskbuf = Buffer.cueSoundFile(s,path,0,2);
			g_disk=Synth(\disk, [ \out:g_multi.mixbus, \bufnum:g_diskbuf ]);
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

	g_multi.m_init(g_gui,g_mappings,g_instrument);
	g_multi.m_new_instrument(g_default_soundfile);
	g_mappings.m_clear_all_matches();
	NotificationCenter.notify(\multi,\changed_inst,g_multi.active);
};

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
g_trace = true;

f={
	f_set_general_actions.();
	g_gui=f_make_gui.();
	g_multi=f_make_multi.();
	g_mappings=f_make_mapping.();
	g_fx_mappings=f_make_fx_mapping.();
	g_instrument=f_make_instrument.();

	g_gui.trace=g_trace;
	g_multi.trace=g_trace;
	g_instrument.trace=g_trace;
	g_midi.trace=g_trace;

	f_add_synthdefs.();
	g_mappings.m_init();
	g_fx_mappings.m_init();
	g_instrument.m_init(g_gui,g_mappings,g_multi);
	g_multi.m_init(g_gui,g_mappings,g_instrument,f_trace);
	g_gui.m_init(g_multi,g_mappings,g_fx_mappings);
	f_trace.("Init complete");
	nil;
};
AppClock.sched(1,f);

{
	f_trace.("Starting...");
	2.wait;
	g_diskbuf = Buffer.alloc(s,2,2);
	g_multi.m_start_synths();
	g_playing=false;
	g_multi.m_new_instrument(g_default_soundfile);
}.fork;

// handler to update GUI play cursor from position sent from grain Synth
o=OSCFunc( {
	|msg, time, addr, recvPort|

	var inst_id=msg[2];
	var framepos=msg[3];
	g_gui.m_update_gui_play_pos(inst_id,framepos);

},'/tr',s.addr)
