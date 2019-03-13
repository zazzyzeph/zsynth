const Launchpad = require( 'launchpad-mini' ),
easymidi = require('easymidi');
pad = new Launchpad();
var MidiClock = require('midi-clock')

var clock = MidiClock();

setTimeout(function(){
    // change to 120bpm after 10 seconds
    clock.setTempo(135)
}, 10000)

pad.connect().then( () => {     // Auto-detect Launchpad
    var output = new easymidi.Output('zseq', true);
    let allBtns = Launchpad.Buttons.All
    pad.reset(0);
    clock.start()
    beatCounter = 0;
    rowCounter = 0;
    activePadsObj = {};
    activePadsArr = [];
    activeNotesArr = [];
    pad.on( 'key', k => {
        if (k.pressed){
            if (activePadsObj.hasOwnProperty(k.x + ',' + k.y)) {
                delete activePadsObj[k.x + ',' + k.y];
            }
            else{
                activePadsObj[k.x + ',' + k.y] = [k.x, k.y]
            }
            activePadsArr = [];
            for (const key in activePadsObj) {
                activePadsArr.push(activePadsObj[key]);
            }
        }
    });
    clock.on('position', function(position){
        var quarter = position % 16 == 0
        var eighth = position % 8 == 0
        var sixteenth = position % 4 == 0
        if (sixteenth){
            rowCounter > 7 ? rowCounter = 0 : '';
            let col = beatCounter % 8;
            let row = rowCounter
            new Promise((resolve)=>{
                pad.reset()
                resolve();
            }).then(pad.col(pad.green.low, [[col, row]]))
                .then(pad.col(pad.green.full, activePadsArr))
            if (activePadsObj.hasOwnProperty(col + ',' + row)){
                output.send('noteon', {
                    note: 28,
                    velocity: 127,
                    channel: 1
                });
                activeNotesArr.push(28);
            }
            else{
                for(i=0; i<activeNotesArr.length; i++){
                    output.send('noteoff', {
                        note: 28,
                        velocity: 0,
                        channel: 1
                    });
                }
                activeNotesArr = [];
            }
            beatCounter++;
            beatCounter % 8 == 0 ? rowCounter++ : '';
        }
        beatCounter % 64 == 0 ? beatCounter = 0 : '';
    })
} );