{
	SynthDef( \grain,
		{
			|out,
			sendone=999,
			sendonelev=0,
			sendtwo=999,
			sendtwolev=0,
			id=0,
			leftbuf,
			rightbuf,
			envbuf,
			master_amp=1,
			amp=1,
			lpf=400,
			hpf=30,
			trate=1,
			rate=0.1,
			pos=0.5,
			dur=0.5,
			scanwidth=0,
			scanrate=0.1,
			scanshape=0.5,
			panwidth=0,
			durjitter=0,
			pos_lfo_rate=0.01,
			pos_lfo_level=0.5,
			pos_lfo_shape=0,
			grain_att=0.5,
			grain_rel=0.5,
			grate_jit=0,
			pitch_jit=0,
			ringmod_lev=0,
			ringmod_freq=440,
			vol_lfo_amt=0.0,
			vol_lfo_freq=0.0,
			disto_amt=0.0,
			vol_lfo_shape=0.5
			|

			var mix, clk, durmod,slowclk, l_sig,r_sig,length,frames,spos, scan, linscan, lfoscan,pitch;
			var lpfsig, hpfsig,tratemod,panleft,panright, pos_lforand, pos_lfosaw;
			var ring, ringmix, amplfo,disto_l,disto_r;

			tratemod=Lag.kr(trate)+LFNoise2.kr(trate).range(0,grate_jit*4);
			clk = Impulse.kr(tratemod);
			slowclk = Impulse.kr(5);

			durmod=Lag.kr(dur,0.02)+TRand.kr(0,0.2*durjitter,clk);
			pitch=Lag.kr(rate,0.2)*TRand.kr( 1-(0.5*pitch_jit),1+(2*pitch_jit),clk);
			length=BufDur.kr(leftbuf);
			frames=BufFrames.kr(rightbuf);
			linscan=VarSaw.kr(scanrate, 0, scanshape, scanwidth/2 ,0 );
			pos_lforand=TRand.kr(-0.5,0.5,Dust.kr(pos_lfo_rate));
			pos_lfosaw=VarSaw.kr(pos_lfo_rate,0,0.5);
			lfoscan=SelectX.kr(pos_lfo_shape, [ pos_lfosaw, pos_lforand ] )*pos_lfo_level;
			scan= pos + linscan + lfoscan;
			spos= scan * length;
			panleft= -1 + (TRand.kr(0,2,clk)*panwidth);
			panright= 1 - (TRand.kr(0,2,clk)*panwidth);
			amplfo=VarSaw.kr(vol_lfo_freq,0,vol_lfo_shape,mul:vol_lfo_amt, add:1.0);
			SendTrig.kr(slowclk,id,scan*frames);

			l_sig=TGrains2.ar(2,
				clk,
				leftbuf,
				pitch,
				Lag.kr(spos),
				durmod,
				panleft,
				1,
				grain_att,
				grain_rel
			);
			r_sig=TGrains2.ar(2,
				clk,
				rightbuf,
				pitch,
				Lag.kr(spos),
				durmod,
				panright,
				1,
				grain_att,
				grain_rel
			);
			disto_l=Limiter.ar(l_sig*20.0*disto_amt, 0.1,0.001).distort; 
			disto_r=Limiter.ar(r_sig*20.0*disto_amt, 0.1,0.001).distort; 
			disto_l=Normalizer.ar(disto_l,0.5)*3;
			disto_r=Normalizer.ar(disto_r,0.5)*3;
			l_sig = SelectX.ar( disto_amt,[l_sig,disto_l]);
			r_sig = SelectX.ar( disto_amt,[r_sig,disto_r]);

			mix=Mix.ar([ l_sig, r_sig ])*amplfo;
			ring=DiodeRingMod.ar(mix,SinOsc.ar(ringmod_freq));
			ringmix=SelectX.ar(ringmod_lev,[ mix, ring ]);
			lpfsig=LPF.ar(ringmix,Lag.kr(lpf));
			hpfsig=HPF.ar(lpfsig,Lag.kr(hpf));

			Out.ar(out,hpfsig*amp*master_amp);
			Out.ar(sendone,hpfsig*sendonelev*master_amp);
			Out.ar(sendtwo,hpfsig*sendtwolev*master_amp);

	}).add;

	SynthDef( \rev,
		{
			|in,out,room=50,time=5,damp=0.9,tail=0.5|
			var inp,verb;

			inp=In.ar(in,1)/2;
			verb=GVerb.ar(inp,room,time,damping:damp,taillevel:tail, earlyreflevel:0.1,drylevel:0);

			Out.ar(out,verb);
		}
		,[0,0,1,1,1,1]).add;

	SynthDef( \grey,
		{
			arg in, out, level=1.0, delayTime=2.0, damp= 0.0, size= 1.0, diff= 0.707, feedback= 0.9, modDepth= 0.1, modFreq= 2.0;
			var inp,verb;

			inp=In.ar(in,2);
			verb=Greyhole.ar(inp,delayTime:delayTime, damp:damp, size:size, diff: diff, feedback: feedback, modDepth: modDepth, modFreq: modFreq);
			Out.ar(out,verb*level);
		}).add;

	SynthDef( \jpv,
		{
			arg in, out, level=1.0, delayTime=2.0, damp= 0.0, size= 1.0, diff= 0.707, modDepth= 0.1,
				modFreq= 2.0, low=1.0,mid=1.0,high=1.0,lowcut=500.0,highcut=2000.0;
			var inp,verb;

			inp=In.ar(in,2);
			verb=JPverb.ar(inp,t60:delayTime, damp:damp, size:size, earlyDiff: diff, modDepth: modDepth,
					modFreq: modFreq, low: low, mid: mid, high: high, lowcut: lowcut, highcut: highcut);
			Out.ar(out,verb*level);
		}).add;

	SynthDef(\out, {|in,out,aux,vol,pan=0.0,auxlev=0.0|
		var inp,nl,nr,bal;
		inp=In.ar(in,2)/2 ;
		nl=Compander.ar(inp[0],inp[0],thresh:0.7,slopeBelow:1,slopeAbove:0.1,clampTime:0.01,relaxTime:0.1)*vol;
		nr=Compander.ar(inp[1],inp[1],thresh:0.7,slopeBelow:1,slopeAbove:0.1,clampTime:0.01,relaxTime:0.1)*vol;
		bal=Balance2.ar(nl,nr,pan);
		Out.ar(out,bal);
		Out.ar(aux,inp*auxlev);
	}).add;



	SynthDef(\delay, { |in,out,send,buf1,buf2,repeats=1,dtime=1.0,dlev=0.5, moddepth=0, modrate=1 |

		var  del1a,del1b;
		var  left,right,inp,delmod;

		inp= In.ar(in,2);

		inp=inp/2;

		delmod=SinOsc.kr(modrate,0,moddepth);
		del1a = BufCombC.ar(buf1,inp[0],Lag.kr(dtime,1)+delmod,    repeats,dlev);
		del1b = BufCombC.ar(buf2,inp[1],Lag.kr(dtime * 2,1)+delmod ,  repeats,dlev);

		left=LPF.ar(del1a,10000);
		right=LPF.ar(del1b,10000);
		//Out.ar(send,[ left,right ]);
		Out.ar(out,[ left,right ] ) ;

	},[0,0,0,1,1,1]).add;

	SynthDef(\disk, { |out, bufnum = 0, vol=0.5|
	    Out.ar(out, DiskIn.ar(2, bufnum)*vol);
	}).add
};
