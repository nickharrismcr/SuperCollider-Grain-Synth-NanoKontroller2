// control mappings for jpverb reverb
(
	mappings:nil,
	m_init: {
		arg self;

		self.mappings=Dictionary.new(80);

		"add fx mappings".postln;
		self.mappings.put("KNOB_1",
			(
				group:1,
				order:1,
				name:"FX level",
				lastval:0,
				matched:false,
				init:127,
				func:{
					|self,val,inst|
					inst.set(\level,val.linlin(0,127,0.0,1.0 ));
				}
		));
		self.mappings.put("SHIFT_1+KNOB_1",
			(
				group:1,
				order:2,
				name:"low mult",
				lastval:0,
				matched:false,
				init:0,
				func:{
					|self,val,inst|
					inst.set(\low,val.linlin(0,127,0.0,1.0 ));

				}
		));
		self.mappings.put("SHIFT_2+KNOB_1",
			(
				group:1,
				order:3,
				name:nil,
				lastval:0,
				matched:false,
				init:0,
				func:nil
		));

		self.mappings.put("KNOB_2",
			(
				group:2,
				order:4,
				name:"length",
				lastval:0,
				matched:false,
				init:10,
				func:{
					|self,val,inst|
					inst.set(\delayTime,val.linlin(0,127,0.1,60 ));
				}
		));
		self.mappings.put("SHIFT_1+KNOB_2",
			(
				group:2,
				order:5,
				name:"mid mult",
				lastval:0,
				matched:false,
				init:0,
				func:{
					|self,val,inst|
					inst.set(\mid,val.linlin(0,127,0.0,1.0 ));

				}
		));
		self.mappings.put("SHIFT_2+KNOB_2",
			(
				group:2,
				order:6,
				name:nil,
				lastval:0,
				matched:false,
				init:0,
				func:nil
		));
		self.mappings.put("KNOB_3",
			(
				group:3,
				order:7,
				name:"damp",
				lastval:0,
				matched:false,
				init:67,
				func:{
					|self,val,inst|
					inst.set(\damp, val.linlin(0,127,0.0,1.0));
				}
		));
		self.mappings.put("SHIFT_1+KNOB_3",
			(
				group:3,
				order:8,
				name:"high mult",
				lastval:0,
				matched:false,
				init:0,
				func:{
					|self,val,inst|
					inst.set(\high,val.linlin(0,127,0.0,1.0 ));

				}
		));
		self.mappings.put("SHIFT_2+KNOB_3",
			(
				group:3,
				order:9,
				name:nil,
				lastval:0,
				matched:false,
				init:0,
				func:nil
		));
		self.mappings.put("KNOB_4",
			(
				group:4,
				order:10,
				name:"size",
				lastval:0,
				matched:false,
				init:64,
				func:{
					|self,val,inst|
					inst.set(\size, val.linlin(0,127,0.5,5));
				}
		));
		self.mappings.put("SHIFT_1+KNOB_4",
			(
				group:4,
				order:11,
				name:"low cut",
				lastval:0,
				matched:false,
				init:0,
				func:{
					|self,val,inst|
					inst.set(\lowcut,val.linlin(0,127,100,6000));

				}
		));
		self.mappings.put("SHIFT_2+KNOB_4",
			(
				group:4,
				order:12,
				name:nil,
				lastval:0,
				matched:false,
				init:0,
				func:nil
		));

		self.mappings.put("KNOB_5",
			(
				group:5,
				order:13,
				name:"diffusion",
				lastval:0,
				matched:false,
				init:64,
				func:{
					|self,val,inst|
					inst.set(\diff,val.linlin(0,127,0.0,1.0));
				}
		));
		self.mappings.put("SHIFT_1+KNOB_5",
			(
				group:5,
				order:14,
				name:"high cut",
				lastval:0,
				matched:false,
				init:0,
				func:{
					|self,val,inst|
					inst.set(\highcut,val.linlin(0,127,1000,6000 ));

				}
		));
		self.mappings.put("SHIFT_2+KNOB_5",
			(
				group:5,
				order:15,
				name:nil,
				lastval:0,
				matched:false,
				init:0,
				func:nil
		));
		self.mappings.put("KNOB_6",
			(
				group:6,
				order:16,
				name:"mod depth",
				lastval:0,
				matched:false,
				init:30,
				func:{
					|self,val,inst|
					inst.set(\modDepth,val.linlin(0,127,0.0,3.0 ));
				}
		));
		self.mappings.put("SHIFT_1+KNOB_6",
			(
				group:5,
				order:17,
				name:nil,
				lastval:0,
				matched:false,
				init:0,
				func:nil
		));
		self.mappings.put("SHIFT_2+KNOB_6",
			(
				group:5,
				order:18,
				name:nil,
				lastval:0,
				matched:false,
				init:0,
				func:nil
		));
		self.mappings.put("KNOB_7",
			(
				group:7,
				order:19,
				name:"mod freq",
				lastval:0,
				matched:false,
				init:0,
				func:{
					|self,val,inst|
					inst.set(\modFreq,val.linlin(0,127,0.1,5.0 ));
				}	
		));
		self.mappings.put("SHIFT_1+KNOB_7",
			(
				group:5,
				order:20,
				name:nil,
				lastval:0,
				matched:false,
				init:0,
				func:nil
		));
		self.mappings.put("SHIFT_2+KNOB_7",
			(
				group:5,
				order:21,
				name:nil,
				lastval:0,
				matched:false,
				init:0,
				func:nil
		));
		self.mappings.put("KNOB_8",
			(
				group:5,
				order:22,
				name:"disk play vol",
				lastval:0,
				matched:false,
				init:0.5,
				func:{ 
					|self,val,inst|
					inst.set(\vol,val.linlin(0,127,0.0,1.0));
				}
		));
		self.mappings.put("SHIFT_1+KNOB_8",
			(
				group:5,
				order:23,
				name:nil,
				lastval:0,
				matched:false,
				init:0,
				func:nil
		));
		self.mappings.put("SHIFT_2+KNOB_8",
			(
				group:5,
				order:24,
				name:nil,
				lastval:0,
				matched:false,
				init:0,
				func:nil
		));

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
	}
);
