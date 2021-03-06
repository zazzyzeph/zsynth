<CsoundSynthesizer>

<CsOptions>
; find your desired alsa midi port  number w aconnect -i -o
-odac -+rtmidi=alsaseq -+rtaudio=jack  -M14
</CsOptions>

<CsInstruments>
;==============================================================================
;==============================================================================
;							 OPTIONS & TABLES
;==============================================================================
sr = 48000
nchnls = 2
0dbfs = 1

gifn	ftgen   2,0,0dbfs,"tanh",1,-1,0	; tanh
; gifn	ftgen	0,0, 257, 9, .5,1, 270	; sigmoid
; gifn	ftgen	1, 0, 16384, 10, 1
gisine ftgen 1, 0, 16384, 10, 1


;==============================================================================
;==============================================================================
;								PATCHBAY
;==============================================================================

connect "Kick", "output", "Mixer", "input1"
; connect "Kick", "output", "Reverb", "input1"
; connect "Reverb", "output1", "Mixer", "input2"
; connect "Reverb", "output2", "Mixer", "input2"

connect "Mixer",   "output",     "Outputs",     	"inputL"
connect "Mixer",   "output",     "Outputs",     	"inputR"

alwayson "Gate0"
alwayson "Gate1"
alwayson "VcaEnv"
alwayson "PitchEnv"
alwayson "NoiseVcaEnv"
alwayson "Kick"
alwayson "Reverb"
alwayson "Mixer"
alwayson "Outputs"


;==============================================================================
;==============================================================================
;							CUSTOM OPCODES
;==============================================================================

; Responsive analog style envelopes for MIDI instruments

#include "udo/adsd.udo"

; Tube style drive

#include "udo/tubewarmth.udo"

; Shimmer Reverb

#include "udo/shimverb.udo"

;==============================================================================
;==============================================================================
;								INSTRUMENTS
;==============================================================================
instr midiIn0
	icps     cpsmidi
	gkcps0 = icps
endin
instr midiIn1
	icps     cpsmidi
	gkcps1 = icps
endin

instr Gate0
	kNoteCount active "midiIn0"
	if (kNoteCount > 0) then
		gkGate0 = 1
	else
		gkGate0 = 0
	endif
endin
instr Gate1
	kNoteCount active "midiIn1"
	if (kNoteCount > 0) then
		gkGate1 = 1
	else
		gkGate1 = 0
	endif
endin

instr VcaEnv
	initc7 1, 1, 0.1
	kDecay ctrl7 1, 1, 0.05, 0.3
	gkVcaEnv ADSD 1, 0.005, kDecay, 0, gkGate0
endin

instr PitchEnv
	initc7 1, 2, 0.3
	initc7 1, 3, 0.4
	kPitchBendAmt ctrl7 1,2,0,1
	kPitchBendDecay ctrl7 1, 3, 0.001, 0.4
	gkPitchBendEnv ADSD kPitchBendAmt, 0.001, kPitchBendDecay, 0, gkGate0
endin

instr NoiseVcaEnv
	initc7 1, 4, 0.6
	initc7 1, 5, 0.2
	kNoiseVcaAmt ctrl7 1,4,0,0.2
	kNoiseVcaDecay ctrl7 1, 5, 0.001, 0.1
	gkNoiseVcaEnv ADSD kNoiseVcaAmt, 0.001, kNoiseVcaDecay, 0, gkGate0
endin

instr Kick
	initc7 1, 6, 0.5
	kDriveAmt ctrl7 1, 6, 2, 5
	aPitchBendEnv interp gkPitchBendEnv
	asine poscil 0dbfs, gkcps0 + (aPitchBendEnv * 150)
	ashaped distort asine, 0.4, gifn
	aNoiseVcaEnv interp gkNoiseVcaEnv
	anoise noise 0dbfs * aNoiseVcaEnv, 0.999
	amixed distort anoise + ashaped, 0.4, gifn
	atubed tap_tubewarmth amixed, kDriveAmt, 0
	avca interp gkVcaEnv
	avca = (atubed * 3) * avca
	outleta "output", avca
endin

instr Reverb
	ainput1 inleta "input1"
	averb1, averb2 shimmer_reverb ainput1, ainput1, 0, 0.8, 10000, 0.45, 100, 1.5
	outleta "output1", averb1
	outleta "output2", averb2
endin

instr snare
	
endin

instr Mixer
  ainput1 inleta "input1"
  ainput2 inleta "input2"
  outleta "output", ainput1 + ainput2
endin

instr Outputs
  ainputL inleta "inputL"
  ainputR inleta "inputR"
  alimitedL clip ainputL, 0, 0dbfs
  alimitedR clip ainputR, 0, 0dbfs
  outs alimitedL, alimitedR
endin

</CsInstruments>

<CsScore>

</CsScore>

</CsoundSynthesizer>
