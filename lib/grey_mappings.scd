// control mappings for greyhole reverb
(
	mappings:nil,
	m_init: {
		arg self;

		self.mappings=Dictionary.new(80);

		"add greyhole mappings".postln;
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

		self.mappings.put("KNOB_2",
			(
				group:2,
				order:4,
				name:"delay time",
				lastval:0,
				matched:false,
				init:10,
				func:{
					|self,val,inst|
					inst.set(\delayTime,val.linlin(0,127,0.1,4 ));
				}
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
		self.mappings.put("KNOB_6",
			(
				group:6,
				order:16,
				name:"feedback",
				lastval:0,
				matched:false,
				init:30,
				func:{
					|self,val,inst|
					inst.set(\feedback,val.linlin(0,127,0.0,1.0 ));
				}
		));
		self.mappings.put("KNOB_7",
			(
				group:7,
				order:19,
				name:"mod depth",
				lastval:0,
				matched:false,
				init:0,
				func:{
					|self,val,inst|
					inst.set(\modDepth,val.linlin(0,127,0.0,2.0 ));
				}	
		));
		self.mappings.put("KNOB_8",
			(
				group:8,
				order:22,
				name:"mod freq",
				lastval:0,
				matched:false,
				init:0,
				func:{
					|self,val,inst|
					inst.set(\modFreq,val.linlin(0,127,0.0,10.0 ));

				}
		));
		"done add greyhole mappings".postln;
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
