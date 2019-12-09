(
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
	instruments:nil,
	playing:false,
	orange:Color.new255(255,105,0),
	darkorange:Color.new255(170,50,0),
	darkgreen:Color.new255(0,70,0),
	green:Color.new255(0,200,0),
	khaki:Color.new255(50,50,0),
	darkblue:Color.new255(0,0,150),
	m_trace: {
		arg self,txt;
		txt.debug("GUI Trace");
	},
	// construct the gui
	m_init: {
		arg self,instruments,mappings,fx_mappings;

		var l_scene_item_panel, l_bank_item_panel, l_inst_item_panel, l_cont_list;
		var l_inst, l_scene_items, l_bank_items, l_inst_items;
		var l_randomize_button, l_load_patch_button, l_save_patch_button;
		var l_record_button, l_load_file_button, l_reset_button;
		var l_play_from_disk_button;
		var l_counter,l_panel2;

		self.m_trace("init_gui");
		self.win = Window.new("NanoKontrol 2 Granulator", Rect(50, 50, 1400, 800), false).front;
		self.win.background = Color.grey(0.1, 0.9);

		self.instruments=instruments;
		self.mixerchans=Array.new(8);
		self.params=Dictionary.new();
		self.fxparams=Dictionary.new();

		self.parampanel=CompositeView.new(self.win,Rect(30,400,1000,550));
		self.parampanel.decorator=FlowLayout(self.parampanel.bounds);

		// controllers are in a dictionary, which is unordered.
		// we need to sort them by the controllers \order property before adding to the guinst.

		l_cont_list = Array.new;
		mappings.m_get_all().collect({
			|item,key|  l_cont_list=l_cont_list.add([ item[\order],item ]);
		});

		l_counter=0;
		l_cont_list.sort( { |a,b| a[0] < b[0] }).do ({

			arg x;
			var l_controller,l_name,l_text,l_bar;

			l_controller=x[1];
			l_name=l_controller[\name];

			if ((l_counter == 0 ), {
				l_panel2=CompositeView.new(self.parampanel,Rect(0,0,120,150)).background_(self.khaki);
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
				l_bar=self.m_hbar_proto().copy;
				l_bar.addit(l_panel2,Rect(0,0,88,20),self.orange);
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

			l_panel2=CompositeView.new(self.mixerpanel,Rect(0,0,120,150)).background_(self.khaki);
			l_panel2.decorator=FlowLayout(l_panel2.bounds);
			l_item=StaticText.new(l_panel2,110@20 ).background_(Color.gray(0.1)).stringColor_(Color.white).align_(\center);
			l_item.font = Font("Monaco",10);
			l_item.string_("Level %".format(i+1));
			l_text=StaticText.new(l_panel2,20@20 ).background_(Color.gray(0.5)).stringColor_(Color.black).align_(\center);
			l_text.string_("64");
			l_text.font = Font("Monaco",10);
			l_item=self.m_hbar_proto().copy;
			l_item.addit(l_panel2,Rect(0,0,88,20),self.orange);
			l_item.updateit(1.0); 
			self.mixer_levels = self.mixer_levels.add([l_text,l_item]);


			l_item=StaticText.new(l_panel2,110@20 ).background_(Color.gray(0.1)).stringColor_(Color.white).align_(\center);
			l_item.font = Font("Monaco",10);
			l_item.string_("Pan %".format(i+1));
			l_text=StaticText.new(l_panel2,20@20 ).background_(Color.gray(0.5)).stringColor_(Color.black).align_(\center);
			l_text.string_("64");
			l_item=self.m_hbar_proto().copy;
			l_item.addit(l_panel2,Rect(0,0,88,20),self.orange);
			l_item.updateit(0.5); 
			self.mixer_pans = self.mixer_pans.add([l_text,l_item]);


			l_item=StaticText.new(l_panel2,110@20 ).background_(Color.gray(0.1)).stringColor_(Color.white).align_(\center);
			l_item.font = Font("Monaco",10);
			l_item.string_("Aux send %".format(i+1));
			l_text=StaticText.new(l_panel2,20@20 ).background_(Color.gray(0.5)).stringColor_(Color.black).align_(\center);
			l_text.string_("0");
			l_item=self.m_hbar_proto().copy;
			l_item.addit(l_panel2,Rect(0,0,88,20),self.orange);
			l_item.updateit(0.0); 
			self.mixer_auxs = self.mixer_auxs.add([l_text,l_item]);
		};

		self.fxpanel=CompositeView.new(self.win,Rect(30,400,1000,550));
		self.fxpanel.decorator=FlowLayout(self.fxpanel.bounds);

		l_cont_list = Array.new;
		fx_mappings.m_get_all().collect({
			|item,key|  l_cont_list=l_cont_list.add([ item[\order],item ]);
		});

		l_counter=0;
		l_cont_list.sort( { |a,b| a[0] < b[0] }).do ({

			arg x;
			var l_controller,l_name,l_text,l_bar;

			# z,l_controller = x; 
			l_name=l_controller[\name];

			if ((l_counter == 0 ), {
				l_panel2=CompositeView.new(self.fxpanel,Rect(0,0,120,150)).background_(self.khaki);
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
				l_bar=self.m_hbar_proto().copy;
				l_bar.addit(l_panel2,Rect(0,0,88,20),self.orange);
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
			l_item=StaticText.new(l_scene_item_panel,50@20).background_(self.darkgreen).string_("scene %".format(i+1)).align_(\center);
			l_item.font = Font("Monaco",10);
		});

		l_bank_item_panel=CompositeView.new(self.win,Rect(30,760,900,25));
		l_bank_item_panel.decorator=FlowLayout(l_bank_item_panel.bounds);

		self.bank_items=Array.fill(8, {
			|i|
			var l_item;
			l_item=StaticText.new(l_bank_item_panel,50@20).background_(self.darkblue).string_("bank %".format(i+1)).align_(\center);
			l_item.font = Font("Monaco",10);
		});

		l_inst_item_panel=CompositeView.new(self.win,Rect(30,0,900,25));
		l_inst_item_panel.decorator=FlowLayout(l_bank_item_panel.bounds);

		self.inst_items=Array.fill(8, {
			|i|
			var l_item;
			l_item=StaticText.new(l_inst_item_panel,50@20).background_(self.orange).string_("inst %".format(i+1)).align_(\center);
			l_item.font = Font("Monaco",10);
		});

		//update_gui_bank_items.(inst);
		self.m_update_gui_inst_items();

		l_play_from_disk_button=Button.new(self.win,Rect(700,760,70,20));
		l_play_from_disk_button.states_([[ "Play", self.orange, Color.black ], [ "Stop", Color.black, self.orange ]]);
		l_play_from_disk_button.font = Font("Monaco",10);
		l_play_from_disk_button.action = {
			|view|
			if ((self.playing.not), {
				FileDialog.new({ |paths|
					NotificationCenter.notify(\gui,\toggle_play);
				},
				nil,
				0,
				0
				);
				self.playing=true;
			},{
				NotificationCenter.notify(\gui,\toggle_play);
				self.playing=false;
			});
		};

		l_randomize_button=Button.new(self.win,Rect(800,760,70,20));
		l_randomize_button.font = Font("Monaco",10);
		l_randomize_button.states_([[ "Random", Color.cyan, Color.black ]]);
		l_randomize_button.action = {
			|view|
			self.instruments.m_randomize_active();
		};


		l_save_patch_button=Button.new(self.win,Rect(900,760,70,20));
		l_save_patch_button.states_([[ "Save", Color.green, Color.black ]]);
		l_save_patch_button.font = Font("Monaco",10);
		l_save_patch_button.action = {
			|view|
			FileDialog.new({ |paths|
				self.instruments.m_save_patch(paths[0]);
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
				self.instruments.m_load_patch(paths[0]);
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
				l_inst=self.instruments.m_active();
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
			NotificationCenter.notify(\gui,\toggle_record);
		};

		l_reset_button=Button.new(self.win,Rect(1300,760,70,20));
		l_reset_button.states_([[ "Reset", Color.magenta, Color.black ]]);
		l_reset_button.font = Font("Monaco",10);
		l_reset_button.action = {
			|view|
			NotificationCenter.notify(\gui,\reset);
		};

		self.win.front;

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
			self.m_update_gui_grain_window(self.instruments.m_active());
			self.m_update_gui_scene_items(self.instruments.m_active());
			mappings.m_clear_all_matches();
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
		self.m_trace("init_gui done");
		// prevent rescheduling
		nil;
	},
	//---------------------------------------------------------------------------------------------------------------------------------------------
	// update the scene buttons ( active, in use, unused )
	m_update_gui_scene_items: {

		arg self,inst;
		var snap;

		{
			self.m_trace("update_gui_scene_items");
			self.scene_items.do {

				arg x,i;

				x.background_(self.darkgreen);
				snap=inst.scenes[i+(inst.bank*8)];

				if (( snap != nil ),{

					self.scene_items[i].background_(self.green);

					if (( inst.scene != nil), {

						if ( ( (( 8 * inst.bank) + i ) == inst.scene ), {
							self.scene_items[i].background_(Color.cyan);
						})
					});
				});
			};
			self.m_trace("update_gui_scene_items done");
		}.defer;
	},

	//---------------------------------------------------------------------------------------------------------------------------------------------
	// update the sample position cursor 
	m_update_gui_play_pos: {

		arg self,inst_id,framepos;
		{
			var inst;

			inst=self.instruments.list[inst_id];
			inst.soundFileView.setSelection(1, [ framepos.floor,(inst.soundFile.numFrames/1100) ]);
		}.defer;
	},

	//---------------------------------------------------------------------------------------------------------------------------------------------
	// refresh the slider position etc of a gui inst parameter item
	m_update_inst_gui: {

		arg self, param , val, matched ;
		{
			var item,text,bar;
			self.m_trace("update_gui_inst_param v % p % m % ".format(val,param,matched));

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
						text.background_(self.darkgreen);
						bar.setcolor(self.orange);
					});
				});
			});

			self.m_trace("update_gui_inst_param done");
		}.defer;
	},
	//---------------------------------------------------------------------------------------------------------------------------------------------
	// refresh the slider position etc of a gui fx parameter item
	m_update_fx_gui: { 

		arg self, param , val, matched ;
		{
			var item,text,bar;
			self.m_trace("update_gui_fx_param v % p % m % ".format(val,param,matched));

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
					text.background_(self.darkgreen);
					bar.setcolor(self.orange);
				});
			});

			self.m_trace("update_gui_fx_param done");
		}.defer;
	},

	//---------------------------------------------------------------------------------------------------------------------------------------------
	// update the waveform display selection
	m_update_gui_grain_window: {

		arg self,inst;

		var pos,size;

		{
			self.m_trace("f_update_gui_grain_window");
			pos=inst.soundFileView.numFrames * ( inst.sample_pos_fine + inst.sample_pos - ( inst.scan_width/2 ));
			size=inst.soundFileView.numFrames * inst.scan_width;

			if ( size < 5000,{ size =5000; });
			inst.soundFileView.setSelection(0,[ pos, size ]);
			self.m_trace("f_update_gui_grain_window done");
		}.defer;
	},
	//---------------------------------------------------------------------------------------------------------------------------------------------
	// set state of inst buttons ( active, in use, unused, muted )
	m_update_gui_inst_items: {

		arg self;
		{
			self.m_trace("update_gui_inst_items");
			self.inst_items.do {

				arg item,id;
				var inst;

				item.background_(self.darkorange);

				inst=self.instruments.list.at(id);

				if (( inst != nil ),{

					item.background_(self.orange);
					if (( inst[\mute] == 0.0 ), {
						item.background_(Color.gray(0.25));
					});

					if (( self.instruments.active == id),{
						item.background_( Color.new255(255,200,0) );
						if ((inst[\mute] == 0.0 ), {
							item.background_(Color.gray(0.5));
						});
					});
				});
			};
			self.m_trace("update_gui_inst_items done");
		}.defer;
	},
	//---------------------------------------------------------------------------------------------------------------------------------------------
	// show/hide mixer
	m_show_mixer: {

		arg self,mode;
		self.m_trace("show mixer %".format(mode));
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
			self.m_trace("f_update_mixer");

			self.mixer_levels.do {

				arg item,id;
				var inst,text,bar;

				inst=self.instruments.list.at(id);

				if (( inst != nil ),{
					# text,bar = item;		
					text.string_("%".format(inst.vol));
					bar.updateit(inst.vol.linlin(0,127,0.0,1.0));
					bar.setcolor(self.darkorange);
					if (( inst.vol_matched == true ),{
						bar.setcolor(self.orange);
					});
				});
			};
			self.mixer_pans.do {

				arg item,id;
				var inst,text,bar;

				inst=self.instruments.list.at(id);

				if (( inst != nil ),{
					# text,bar = item;
					text.string_("%".format(inst.pan));
					bar.updateit(inst.pan.linlin(0,127,0.0,1.0));
					bar.setcolor(self.darkorange);
					if (( inst.pan_matched == true ),{
						bar.setcolor(self.orange);
					});
				});
			};
			self.mixer_auxs.do {

				arg item,id;
				var inst,text,bar;

				inst=self.instruments.list.at(id);

				if (( inst != nil ),{
					# text,bar = item;
					text.string_("%".format(inst.aux));
					bar.updateit(inst.aux.linlin(0,127,0.0,1.0));
					bar.setcolor(self.darkorange);
					if (( inst.aux_matched == true ),{
						bar.setcolor(self.orange);
					});
				});
			};
			self.m_trace("f_update_mixer done");
		}.defer;
	},
	//---------------------------------------------------------------------------------------------------------------------------------------------
	// update fx panel sliders
	m_update_mixer: {

		arg self;
		{
			self.m_trace("f_update_fx");

			self.mixer_levels.do {

				arg item,id;
				var inst,text,bar;

				inst=self.instruments.list.at(id);

				if (( inst != nil ),{
					# text,bar = item;		
					text.string_("%".format(inst.vol));
					bar.updateit(inst.vol.linlin(0,127,0.0,1.0));
					bar.setcolor(self.darkorange);
					if (( inst.vol_matched == true ),{
						bar.setcolor(self.orange);
					});
				});
			};
			self.mixer_pans.do {

				arg item,id;
				var inst,text,bar;

				inst=self.instruments.list.at(id);

				if (( inst != nil ),{
					# text,bar = item;
					text.string_("%".format(inst.pan));
					bar.updateit(inst.pan.linlin(0,127,0.0,1.0));
					bar.setcolor(self.darkorange);
					if (( inst.pan_matched == true ),{
						bar.setcolor(self.orange);
					});
				});
			};
			self.mixer_auxs.do {

				arg item,id;
				var inst,text,bar;

				inst=self.instruments.list.at(id);

				if (( inst != nil ),{
					# text,bar = item;
					text.string_("%".format(inst.aux));
					bar.updateit(inst.aux.linlin(0,127,0.0,1.0));
					bar.setcolor(self.darkorange);
					if (( inst.aux_matched == true ),{
						bar.setcolor(self.orange);
					});
				});
			};
			self.m_trace("f_update_mixer done");
		}.defer;
	},
	// prototype object for horizontal slider
	m_hbar_proto: {
		arg self;
		(

			view:0,
			val:0.5,
			color:self.orange,
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
					Pen.strokeColor = self.darkorange;
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
		)
	}
);

