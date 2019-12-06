// nanokontrol 2 midi handler object 
(
	names: [ "SLIDER_1", "SLIDER_2", "SLIDER_3", "SLIDER_4", "SLIDER_5", "SLIDER_6", "SLIDER_7", "SLIDER_8", "NONE", "NONE", "NONE", "NONE", "NONE", "NONE", "NONE", "NONE", "KNOB_1", "KNOB_2", "KNOB_3", "KNOB_4", "KNOB_5", "KNOB_6", "KNOB_7", "KNOB_8", "NONE", "NONE", "NONE", "NONE", "NONE", "NONE", "NONE", "NONE", "S_BUTTON_1", "S_BUTTON_2", "S_BUTTON_3", "S_BUTTON_4", "S_BUTTON_5", "S_BUTTON_6", "S_BUTTON_7", "S_BUTTON_8", "NONE", "PLAY", "STOP", "REW", "FF", "REC", "CYCLE", "NONE", "M_BUTTON_1", "M_BUTTON_2", "M_BUTTON_3", "M_BUTTON_4", "M_BUTTON_5", "M_BUTTON_6", "M_BUTTON_7", "M_BUTTON_8", "NONE", "NONE", "PREV_TR", "NEXT_TR", "SET_MARK", "PREV_MARK", "NEXT_MARK", "NONE", "R_BUTTON_1", "R_BUTTON_2", "R_BUTTON_3", "R_BUTTON_4", "R_BUTTON_5", "R_BUTTON_6", "R_BUTTON_7", "R_BUTTON_8" ],
	shift1:nil,
	shift2:nil,
	shift3:nil,
	m_name: { |self,val|  self.names.at(val); },
	m_update: {
		arg self,p_val,p_num,p_chan,p_src;
		var name;
		// notify dependants of change
		name=self.m_name(p_num);

		if ((name==nil), { "MIDI update failed name lookup".die; });

		if ((name=="REW"  && p_val == 127),{ self.shift1 = true; });
		if ((name=="REW"  && p_val == 0),  { self.shift1 = false; });
		if ((name=="FF"   && p_val == 127),{ self.shift2 = true; });
		if ((name=="FF"   && p_val == 0),  { self.shift2 = false; });
		if ((name=="STOP" && p_val == 127),{ self.shift3 = true; });
		if ((name=="STOP" && p_val == 0),  { self.shift3 = false; });

		if ((self.shift1 == true ), { name = "SHIFT_1+"++name; });
		if ((self.shift2 == true ), { name = "SHIFT_2+"++name; });
		if ((self.shift3 == true ), { name = "SHIFT_3+"++name; });

		NotificationCenter.notify(\midi,\midi_in,Array.with(name,p_val));
	};
);
