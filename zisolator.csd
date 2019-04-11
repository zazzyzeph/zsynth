<CsoundSynthesizer>

<CsOptions>
; find your desired alsa midi port  number w aconnect -i -o
; -odac -+rtmidi=alsaseq -+rtaudio=jack  -M14
-odac -iadc4 -+rtmidi=alsaseq -+rtaudio=jack  -M14
</CsOptions>

<CsInstruments>
;==============================================================================
;==============================================================================
;							 OPTIONS & TABLES
;==============================================================================
sr = 48000
nchnls = 2
0dbfs = 1
ksmps = 32

gifn	ftgen   2,0,0dbfs,"tanh",1,-1,0	; tanh
giwaveform ftgen 0, 0, 4, -2, 0, 2, 12, -1
giwaveform2 ftgen 0, 0, 3, -2, 0, 10, 12
gisine ftgen 1, 0, 16384, 10, 1


;==============================================================================
;==============================================================================
;								PATCHBAY
;==============================================================================

connect "Mixer",   "output",     "Outputs",     	"inputL"
connect "Mixer",   "output",     "Outputs",     	"inputR"

alwayson "Mixer"
alwayson "Outputs"


;==============================================================================
;==============================================================================
;								INSTRUMENTS
;==============================================================================

instr Mixer
	initc7 1, 1, 1
	initc7 1, 2, 1
	initc7 1, 3, 1
	initc7 1, 4, 0.5
	initc7 1, 5, 0.5
	kLowLvl ctrl7 1, 1, 0, 1
	kMidLvl ctrl7 1, 2, 0, 1
	kHighLvl ctrl7 1, 3, 0, 1
	aLowLvl interp kLowLvl
	aMidLvl interp kMidLvl
	aHighLvl interp kHighLvl
	kCrossover1Freq ctrl7 1, 4, 80, 640
	kCrossover2Freq ctrl7 1, 5, 1000, 8000

	aCrossover1Freq interp kCrossover1Freq
	aCrossover2Freq interp kCrossover2Freq

	; kLowWidth = kCrossover1Freq * 2
	; kMidWidth = kCrossover2Freq - kCrossover1Freq
	; kMidFreq = kCrossover2Freq + kCrossover1Freq / 2
	; kHighWidth = kCrossover2Freq * 2

	ain1, ain2 ins
	ain = ain1 * 0.5 + ain2 * 0.5
	; ain noise 1, 0
	; 3 way crossover
	; aLow is low passed at kCrossover1Freq
	; aMid is high passed at kCrossover1Freq, then low passed at kCrossover2Freq
	; each band is fed into a peaking filter that removes 3db(still tweaking) so the summed result doesn't clip

	; aLow clfilt ain, kCrossover1Freq, 0, 4, 0
	; aMid clfilt ain, kCrossover2Freq, 0, 4, 0
	; aMid clfilt aMid, kCrossover1Freq, 1, 4, 0
	; aHigh clfilt ain, kCrossover2Freq, 1, 4, 0

	; aLow butbp ain, 0, kLowWidth
	; aLow butbp aLow, 0, kLowWidth
	; aMid butbp ain, kMidFreq, kMidWidth
	; aMid butbp aMid, kMidFreq, kMidWidth
	; aHigh butbp ain, kHighWidth, kCrossover2Freq
	; aHigh butbp aHigh, kHighWidth, kCrossover2Freq


	aLow butlp ain, aCrossover1Freq
	aLow butlp aLow, aCrossover1Freq
	aMid butlp ain, aCrossover2Freq
	aMid butlp aMid, aCrossover2Freq
	aMid buthp aMid, aCrossover1Freq
	aMid buthp aMid, aCrossover1Freq
	aHigh buthp ain, aCrossover2Freq
	aHigh buthp aHigh, aCrossover2Freq


	aout = aLow * aLowLvl + aMid * aMidLvl + aHigh * aHighLvl
	; aout pareq aout, kCrossover1Freq, ampdb(-3), sqrt(0.5)
	; aout pareq aout, kCrossover2Freq, ampdb(-3), sqrt(0.5)
	; aout = ain


	; might be the thing to do, from http://forum.cabbageaudio.com/t/multiband/734
	;first band, 0, 500hz
	; aBand1 butterbp (a1+a2)/2, 0, 1000
	; ;second band, 500, 1500hz
	; aBand2 butterbp (a1+a2)/2, 1000, 1000
	; ;third band, 1500, 5500hz
	; aBand3 butterbp (a1+a2)/2, 3500, 5000

	outleta "output", aout
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
