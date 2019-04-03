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
giwaveform ftgen 0, 0, 4, -2, 0, 2, 12, -1
giwaveform2 ftgen 0, 0, 3, -2, 0, 10, 12
gisine ftgen 1, 0, 16384, 10, 1


;==============================================================================
;==============================================================================
;								PATCHBAY
;==============================================================================

connect "Osc1", "output", "LPF", "input"
connect "LPF", "output", "Reverb", "input1"
connect "LPF", "output", "Mixer", "input1"

; connect "Kick", "output", "Reverb", "input1"
connect "Reverb", "output1", "Mixer", "input2"

connect "Mixer",   "output",     "Outputs",     	"inputL"
connect "Mixer",   "output",     "Outputs",     	"inputR"

alwayson "Gate"
alwayson "Adsr1"
alwayson "Osc1"
alwayson "LPF"
alwayson "Reverb"
alwayson "Mixer"
alwayson "Outputs"


;==============================================================================
;==============================================================================
;							CUSTOM OPCODES
;==============================================================================

; Responsive analog style envelopes for MIDI instruments

#include "udo/adsd.udo"

; Shimmer Reverb

#include "udo/shimverb.udo"

; tube emulator for filter drive

#include "udo/tubewarmth.udo"

;==============================================================================
;==============================================================================
;								INSTRUMENTS
;==============================================================================
instr midiIn0
	icps cpsmidi
	gkcps = icps
endin

instr Gate
	kNoteCount active "midiIn0"
	if (kNoteCount > 0) then
		gkGate = 1
	else
		gkGate = 0
	endif
endin

instr Adsr1
	; initc7 = default adsr vals
	aRetrig = 0
	initc7 1,1,0.001
	initc7 1,2,1
	kAttack ctrl7 1,1,0.001,2
	kDecay ctrl7 1,2,0.001,2
	kenv ADSD 1, kAttack, kDecay, 0.8, gkGate
	gaAdsr1 interp kenv
endin

instr Osc1
	; kWaveformSelect1 ctrl7 1, 1, 0, 1, giwaveform
	; kPWM ctrl7 1, 2, 0.5, 0.1
	; kWaveReinitTrigger1 changed kWaveformSelect1
	; if (kWaveReinitTrigger1==1) then
	; 	reinit oscillator1
	; endif
	oscillator1:
		gkGate = gkGate
		aosc1 vco2 0dbfs * 0.4, gkcps
		; aosc1 = aosc1 * gaAdsr1
	rireturn

	outleta "output", aosc1
endin

instr LPF
	initc7 1, 3, 1
	initc7 1, 4, 0.0001
	initc7 1, 5, 0.0001
	kCutoff ctrl7 1, 3, 0, 10000
	kRes ctrl7 1, 4, 0, 0.9
	kDriveAmt ctrl7 1, 5, 2, 20
	ainput inleta "input"
	afilt moogladder ainput, (gaAdsr1 * kCutoff), kRes
	denorm afilt
	adistorted tap_tubewarmth afilt, kDriveAmt, -5
	alimitedL clip adistorted, 0, 0dbfs
	outleta "output", adistorted
endin

instr Reverb
	initc7 1, 6, 0.6
	initc7 1, 7, 0.5
	initc7 1, 8, 0.5
	initc7 1, 9, 0.5
	initc7 1, 10, 0.5
	kReverbFeebackLevel ctrl7 1, 6, 0, 0.95
	kReverbCutoff ctrl7 1, 7, 0, 10000
	kShimmerFeedbackLevel ctrl7 1, 8, 0, 0.95
	kShimmerDelayTime ctrl7 1, 9, 1, 600
	kPitchRatio ctrl7 1, 10, 1, 2
	ainput1 inleta "input1"
	averb1, averb2 shimmer_reverb ainput1, ainput1, 0, kReverbFeebackLevel, kReverbCutoff, kShimmerFeedbackLevel, kShimmerDelayTime, kPitchRatio
	outleta "output1", averb1
	outleta "output2", averb2
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
