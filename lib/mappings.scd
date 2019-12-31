// assigns dictionary of midi control / instrument param mapping definitions to passed in vars
(
	mappings:nil,
	groups:nil,

	m_init: {
		arg self;

		self.mappings=Dictionary.new(80);
		self.groups=Dictionary.new(20);
		self.params=Dictionary.new(80);

		self.mappings.put("KNOB_1",
			(
				group:1,
				order:1,
				name:"master vol",
				lastval:0,
				matched:false,
				init:127,
				func:{
					|self,val,inst|
					inst.out.set(\vol,val.linlin(0,127,0.0,1.0 )*inst.mute);
					inst.vol=val;
				},

				randomizable:false
		));

		self.mappings.put("SHIFT_1+KNOB_1",
			(
				group:1,
				order:2,
				name:"lpf",
				lastval:0,
				matched:false,
				init:127,
				func:{
					|self,val,inst|
					inst.grain.set(\lpf,val.linexp(0,127,100,10000 ));
				},

				randomizable:false
		));

		self.mappings.put("SHIFT_2+KNOB_1",
			(
				group:1,
				order:3,
				name:"hpf",
				lastval:0,
				matched:false,
				init:0,
				func:{
					|self,val,inst|
					a=val.linlin(0,127,50,8000 );
					inst.grain.set(\hpf,a);
				},

				randomizable:false
		));
		self.mappings.put("KNOB_2",
			(
				group:2,
				order:4,
				name:"grain rate",
				lastval:0,
				matched:false,
				init:5,
				func:{
					|self,val,inst|
					inst.grain.set(\trate,val.linlin(0,127,0.1,300 ));
				},

				randomizable:true
		));
		self.mappings.put("SHIFT_1+KNOB_2",
			(
				group:2,
				order:5,
				name:"grain rate jitter",
				lastval:0,
				matched:false,
				init:0,
				func:{
					|self,val,inst|
					a=val.linlin(0,127,0,1 );
					inst.grain.set(\grate_jit,a);
				},

				randomizable:true
		));
		self.mappings.put("SHIFT_2+KNOB_2",
			(
				group:2,
				order:6,
				name:"distortion",
				lastval:0,
				matched:false,
				init:0,
				func:{
					|self,val,inst|
					inst.grain.set(\disto_amt,val.linlin(0,127,0.0001,1.0));
				},
				randomizable:true
		));
		self.mappings.put("KNOB_3",
			(
				group:3,
				order:7,
				name:"pitch",
				lastval:0,
				matched:false,
				init:67,
				func:{
					|self,val,inst|

					inst.sample_rate=val.linexp(0,127,0.1,8 );
					inst.grain.set(\rate, inst.sample_rate + inst.fine_rate);
				},

				randomizable:true
		));
		self.mappings.put("SHIFT_1+KNOB_3",
			(
				group:3,
				order:8,
				name:"pitch jitter",
				lastval:0,
				matched:false,
				init:0,
				func:{
					|self,val,inst|
					inst.grain.set(\pitch_jit,val.linexp(0,127,0.001,3.0 ));
				},

				randomizable:false
		));
		self.mappings.put("SHIFT_2+KNOB_3",
			(
				group:3,
				order:9,
				name:"fine pitch",
				lastval:0,
				matched:false,
				init:64,
				func:{
					|self,val,inst|
					inst.fine_rate=val.linlin(0,127,-0.1,0.1 );
					inst.grain.set(\rate,inst.sample_rate+inst.fine_rate);
				},

				randomizable:false
		));
		self.mappings.put("KNOB_4",
			(
				group:4,
				order:10,
				name:"position",
				lastval:0,
				matched:false,
				init:64,
				func:{
					|self,val,inst|
					inst.sample_pos=val.linlin(0,127,0,1 );
					inst.grain.set(\pos,inst.sample_pos+inst.sample_pos_fine);
					NotificationCenter.notify(\multi, \grain_window, inst);
				},

				randomizable:true
		));

		self.mappings.put("SHIFT_1+KNOB_4",
			(
				group:4,
				order:11,
				name:"fine position",
				lastval:0,
				matched:false,
				init:64,
				func:{
					|self,val,inst|
					inst.sample_pos_fine=val.linlin(0,127,-0.02,0.02 );
					inst.grain.set(\pos,inst.sample_pos+inst.sample_pos_fine);
					NotificationCenter.notify(\multi, \grain_window, inst);
				},
				randomizable:true
		));
		self.mappings.put("SHIFT_2+KNOB_4",
			(
				group:4,
				order:12,
				name:nil,
				lastval:0,
				matched:false,
				init:0,
				func:nil,
				randomizable:false
		));
		self.mappings.put("KNOB_5",
			(
				group:5,
				order:13,
				name:"grain duration",
				lastval:0,
				matched:false,
				init:64,
				func:{
					|self,val,inst|
					inst.grain_dur=val.linlin(0,127,0.01,1 );
					inst.grain.set(\dur,inst.grain_dur);
				},

				randomizable:true
		));
		self.mappings.put("SHIFT_1+KNOB_5",
			(
				group:5,
				order:14,
				name:"grain attack",
				lastval:0,
				matched:false,
				init:64,
				func:{
					|self,val,inst|
					a=val.linlin(0,127,0,1 );
					inst.grain.set(\grain_att,a*inst.grain_dur);
				},

				randomizable:true
		));
		self.mappings.put("SHIFT_2+KNOB_5",
			(
				group:5,
				order:15,
				name:"grain release",
				lastval:0,
				matched:false,
				init:64,
				func:{
					|self,val,inst|
					a=val.linlin(0,127,0,1 );
					inst.grain.set(\grain_rel,a*inst.grain_dur);
				},

				randomizable:true
		));
		self.mappings.put("KNOB_6",
			(
				group:6,
				order:16,
				name:"volume",
				lastval:0,
				matched:false,
				init:30,
				func:{
					|self,val,inst|
					inst.grain.set(\amp,val.linlin(0,127,0,1 ));
				},

				randomizable:false
		));
		self.mappings.put("SHIFT_1+KNOB_6",
			(
				group:6,
				order:17,
				name:"ring lev",
				lastval:0,
				matched:false,
				init:0,
				func:{
					|self,val,inst|
					inst.grain.set(\ringmod_lev,val.linlin(0,127,0,1));
				},

				randomizable:true
		));
		self.mappings.put("SHIFT_2+KNOB_6",
			(
				group:6,
				order:18,
				name:"ring freq",
				lastval:0,
				matched:false,
				init:64,
				func:{
					|self,val,inst|
					inst.grain.set(\ringmod_freq,val.linlin(0,127,30,2000));
				},

				randomizable:true
		));
		self.mappings.put("KNOB_7",
			(
				group:7,
				order:19,
				name:"delay send",
				lastval:0,
				matched:false,
				init:0,
				func:{
					|self,val,inst|
					inst.grain.set(\sendonelev,val.linlin(0,127,0,1 ));
				},

				randomizable:false
		));
		self.mappings.put("SHIFT_1+KNOB_7",
			(
				group:7,
				order:20,
				name:"delay mod",
				lastval:0,
				matched:false,
				init:0,
				func:{
					|self,val,inst|
					inst.del.set(\moddepth,val.linlin(0,127,0,0.01));
				},

				randomizable:false
		));
		self.mappings.put("SHIFT_2+KNOB_7",
			(
				group:7,
				order:21,
				name:"del mod rate",
				lastval:0,
				matched:false,
				init:0,
				func:{
					|self,val,inst|
					inst.del.set(\modrate,val.linexp(0,127,0.1,10));
				},

				randomizable:false
		));
		self.mappings.put("KNOB_8",
			(
				group:8,
				order:22,
				name:"reverb send",
				lastval:0,
				matched:false,
				init:0,
				func:{
					|self,val,inst|
					inst.grain.set(\sendtwolev,val.linlin(0,127,0,1 ));

				},

				randomizable:true
		));
		self.mappings.put("SHIFT_1+KNOB_8",
			(
				group:8,
				order:23,
				name:"reverb time",
				lastval:0,
				matched:false,
				init:64,
				func:{
					|self,val,inst|
					inst.rev.set(\time,val.linlin(0,127,1,30 ));

				},

				randomizable:true
		));
		self.mappings.put("SHIFT_2+KNOB_8",
			(
				group:8,
				order:24,
				name:"reverb damp",
				lastval:0,
				matched:false,
				init:64,
				func:{
					|self,val,inst|
					inst.rev.set(\damp,val.linlin(0,127,0,1 ));
				},

				randomizable:true
		));
		self.mappings.put("SLIDER_1",
			(
				group:9,
				order:25,
				name:"amp LFO level",
				lastval:0,
				matched:false,
				init:0,
				func:{
					|self,val,inst|
					inst.grain.set(\vol_lfo_amt,val.linlin(0,127,0,1 ));
				},
				randomizable:true
		));
		self.mappings.put("SHIFT_1+SLIDER_1",
			(
				group:9,
				order:26,
				name:"amp LFO rate",
				lastval:0,
				matched:false,
				init:10,
				func:{
					|self,val,inst|
					inst.grain.set(\vol_lfo_freq,val.linexp(0,127,0.01,10 ));
				},
				randomizable:true
		));
		self.mappings.put("SHIFT_2+SLIDER_1",
			(
				group:9,
				order:27,
				name:"amp LFO shape",
				lastval:0,
				matched:false,
				init:64,
				func:{
					|self,val,inst|
					inst.grain.set(\vol_lfo_shape,val.linlin(0,127,0.0,1.0 ));
				},
				randomizable:false
		));
		self.mappings.put("SLIDER_2",
			(
				group:10,
				order:28,
				name:"posn lfo level",
				lastval:0,
				matched:false,
				init:0,
				func:{
					|self,val,inst|
					inst.grain.set(\pos_lfo_level,val.linlin(0,127,0,0.1 ));

				},

				randomizable:true
		));
		self.mappings.put("SHIFT_1+SLIDER_2",
			(
				group:10,
				order:29,
				name:"posn lfo rate",
				lastval:0,
				matched:false,
				init:65,
				func:{
					|self,val,inst|
					inst.grain.set(\pos_lfo_rate,val.linexp(0,127,0.001,10));
				},
				randomizable:true
		));
		self.mappings.put("SHIFT_2+SLIDER_2",
			(
				group:10,
				order:30,
				name:"posn lfo shape",
				lastval:0,
				matched:false,
				init:127,
				func:{
					|self,val,inst|
					inst.grain.set(\pos_lfo_shape,val.linlin(0,127,0,1));
				},
				randomizable:true
		));
		self.mappings.put("SLIDER_3",
			(
				group:11,
				order:31,
				name:nil,
				lastval:0,
				matched:false,
				init:0,
				func:nil,
				randomizable:false
		));
		self.mappings.put("SHIFT_1+SLIDER_3",
			(
				group:11,
				order:32,
				name:nil,
				lastval:0,
				matched:false,
				init:0,
				func:nil,
				randomizable:false
		));
		self.mappings.put("SHIFT_2+SLIDER_3",
			(
				group:11,
				order:33,
				name:nil,
				lastval:0,
				matched:false,
				init:0,
				func:nil,
				randomizable:false
		));
		self.mappings.put("SLIDER_4",
			(
				group:12,
				order:34,
				name:"scan rate",
				lastval:0,
				matched:false,
				init:0,
				func:{
					|self,val,inst|
					inst.scan_rate = val.linexp(0,127,0.01,6.0 );
					inst.grain.set(\scanrate,inst.scan_rate*inst.scan_rate_range);

				},

				randomizable:true
		));
		self.mappings.put("SHIFT_1+SLIDER_4",
			(
				group:12,
				order:35,
				name:"scan shape",
				lastval:0,
				matched:false,
				init:64,
				func:{
					|self,val,inst|
					inst.grain.set(\scanshape,val.linlin(0,127,0,1));
				},
				randomizable:true
		));
		self.mappings.put("SHIFT_2+SLIDER_4",
			(
				group:12,
				order:36,
				name:"scan width",
				lastval:0,
				matched:false,
				init:0,
				func:{
					|self,val,inst|
					inst.scan_width=val.linlin(0,127,0,1 );
					inst.grain.set(\scanwidth,inst.scan_width);
					NotificationCenter.notify(\multi, \grain_window, inst);

				},
				randomizable:true
		));
		self.mappings.put("SLIDER_5",
			(
				group:13,
				order:37,
				name:"duration jitter",
				lastval:0,
				matched:false,
				init:64,
				func:{
					|self,val,inst|
					inst.grain.set(\durjitter,val.linlin(0,127,0,1 ));

				},

				randomizable:true
		));
		self.mappings.put("SHIFT_1+SLIDER_5",
			(
				group:13,
				order:38,
				name:"pan jitter",
				lastval:0,
				matched:false,
				init:0,
				func:{
					|self,val,inst|
					inst.grain.set(\panwidth,val.linlin(0,127,0,1 ));

				},
				randomizable:true

		));
		self.mappings.put("SHIFT_2+SLIDER_5",
			(
				group:13,
				order:39,
				name:nil,
				lastval:0,
				matched:false,
				init:0,
				func:nil,
				randomizable:false
		));
		self.mappings.put("SLIDER_6",
			(
				group:14,
				order:40,
				name:nil,
				lastval:0,
				matched:false,
				init:0,
				func:nil,
				randomizable:false


		));
		self.mappings.put("SHIFT_1+SLIDER_6",
			(
				group:14,
				order:41,
				name:nil,
				lastval:0,
				matched:false,
				init:0,
				func:nil,
				randomizable:false
		));
		self.mappings.put("SHIFT_2+SLIDER_6",
			(
				group:14,
				order:42,
				name:nil,
				lastval:0,
				matched:false,
				init:0,
				func:nil,
				randomizable:false
		));
		self.mappings.put("SLIDER_7",
			(
				group:15,
				order:43,
				name:"delay time",
				lastval:0,
				matched:false,
				init:64,
				func:{
					|self,val,inst|
					inst.del.set(\dtime,val.linlin(0,127,0.01,2 ));

				},

				randomizable:true
		));
		self.mappings.put("SHIFT_1+SLIDER_7",
			(
				group:15,
				order:44,
				name:"delay repeats",
				lastval:0,
				matched:false,
				init:64,
				func:{
					|self,val,inst|
					inst.del.set(\repeats,val.linlin(0,127,1,100 ));
				},

				randomizable:true

		));
		self.mappings.put("SHIFT_2+SLIDER_7",
			(
				group:15,
				order:45,
				name:nil,
				lastval:0,
				matched:false,
				init:0,
				func:nil,
				randomizable:false
		));
		self.mappings.put("SLIDER_8",
			(
				group:16,
				order:46,
				name:nil,
				lastval:0,
				matched:false,
				init:0,
				func:nil,
				randomizable:false

		));
		self.mappings.put("SHIFT_1+SLIDER_8",
			(
				group:16,
				order:47,
				name:nil,
				lastval:0,
				matched:false,
				init:0,
				func:nil,
				randomizable:false
		));
		self.mappings.put("SHIFT_2+SLIDER_8",
			(
				group:16,
				order:48,
				name:nil,
				lastval:0,
				matched:false,
				init:0,
				func:nil,
				randomizable:false
		));

		self.mappings.keysValuesDo {

			arg k,v;
			var group,param;

			group = v[\group];
			if ((self.groups.at(group) == nil ),{
				self.groups.put(group,[ v ] );
			},{
				self.groups.at(group).add(v);
			});

			param= v[\name];
			if ((param != nil),{
				self.params.put(param, k);
			});
		};
	},
	m_clear_all_matches: {
		arg self;
		self.mappings.do {
			arg mapping;
			mapping[\matched]=false;
		};
	},
	m_get_all: {
		arg self,key;
		self.mappings;
	},
	m_get: {
		arg self,key;
		self.mappings[key];
	},
	m_get_group: {
		arg self,key;
		self.groups[key];
	},
	m_get_param: {
		arg self,key;
		self.params[key];
	}
);
