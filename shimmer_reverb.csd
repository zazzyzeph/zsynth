Title: Shimmer Reverb
Author: Steven Yi
Date: 2018.08.22

Description:

Shimmer Reverb using reverb tail that is delayed and fed back into itself after being pitch-shifted using and FFT-based approach 

<CsoundSynthesizer>
<CsOptions>
-o dac --port=10000
</CsOptions>
<CsInstruments>

sr	=	48000
ksmps	= 32	
nchnls=	2
0dbfs	=	1


/* UTILITY CODE FROM csound-live-code */

/** Utility opcode for declicking an audio signal. Should only be used in instruments that have positive p3 duration. */
opcode declick, a, a
  ain xin
  aenv = linseg:a(0, 0.01, 1, p3 - 0.02, 1, 0.01, 0, 0.01, 0)
  xout ain * aenv
endop

/** Returns random item from karray. */
opcode rand, i, k[]
  kvals[] xin
  indx = int(random(0, lenarray(kvals)))
  ival = i(kvals, indx)
  xout ival
endop

;; Stereo Audio Bus

ga_sbus[] init 16, 2

/** Write two audio signals into stereo bus at given index */
opcode sbus_write, 0,iaa
  ibus, al, ar xin
  ga_sbus[ibus][0] = al
  ga_sbus[ibus][1] = ar
endop

/** Mix two audio signals into stereo bus at given index */
opcode sbus_mix, 0,iaa
  ibus, al, ar xin
  ga_sbus[ibus][0] = ga_sbus[ibus][0] + al
  ga_sbus[ibus][1] = ga_sbus[ibus][1] + ar
endop

/** Clear audio signals from bus channel */
opcode sbus_clear, 0, i
  ibus xin
  aclear init 0
  ga_sbus[ibus][0] = aclear
  ga_sbus[ibus][1] = aclear
endop

/** Read audio signals from bus channel */
opcode sbus_read, aa, i
  ibus xin
  aclear init 0
  al = ga_sbus[ibus][0] 
  ar = ga_sbus[ibus][1] 
  xout al, ar
endop

instr ShimmerReverb 
  al, ar sbus_read 1

  ; pre-delay
  al = vdelay3(al, 100, 100)
  ar = vdelay3(ar, 100, 100)
 
  afbl init 0
  afbr init 0
  ifblvl = 0.45


  al = al + (afbl * ifblvl)
  ar = ar + (afbr * ifblvl)

  ; important, or signal bias grows rapidly
  al = dcblock2(al)
  ar = dcblock2(ar)

  al = tanh(al)
  ar = tanh(ar)

  al, ar reverbsc al, ar, 0.95, 16000

  iratio = 2 
  ideltime = 100

  ifftsize  = 2048 
  ioverlap  = ifftsize / 4 
  iwinsize  = ifftsize 
  iwinshape = 1; von-Hann window 

  fftin     pvsanal al, ifftsize, ioverlap, iwinsize, iwinshape 
  fftscale  pvscale fftin, iratio, 0, 1
  atransL   pvsynth fftscale

  fftin2    pvsanal ar, ifftsize, ioverlap, iwinsize, iwinshape 
  fftscale2 pvscale fftin2, iratio, 0, 1
  atransR   pvsynth fftscale2

  ;; delay the feedback to let it build up over time
  afbl = vdelay3(atransL, ideltime, ideltime)
  afbr = vdelay3(atransR, ideltime, ideltime)

  out(al, ar)
  
  sbus_clear(1)
endin
schedule("ShimmerReverb", 0, -1)

instr Syn
  asig = vco2(1, p4)
  asig += vco2(1, p4 * 1.005)
  asig += vco2(1, p4 * 0.997)
  asig = zdf_2pole(asig, expon(1400, p3, 120), 2)
  asig *= p5 * 0.3
  asig = declick(asig * expon(1, p3, 0.001))

  out(asig, asig)
  sbus_mix(1, asig * 0.2, asig * 0.2)
endin

instr Run
  inum = random(4,7)
  indx = 0
  ioct = rand(array(-2,-1,0))
  ibase = int(random(0,7)) + 60
  inn = 0
  while (indx < inum) do
  	schedule("Syn", 0, 6, cpsmidinn(ibase + inn), ampdbfs(-18))
    inn += (indx % 2) == 0 ? 3 : 4 
    indx += 1
  od

  if(p2 < 120) then
    schedule(p1, rand(array(2,4,4,8,8,16)) * 0.5, 0)
  else
    event_i("e", 0, 28)
  endif
endin
  
schedule("Run", 0, 0)

</CsInstruments>
; ==============================================
<CsScore>

</CsScore>
</CsoundSynthesizer>

