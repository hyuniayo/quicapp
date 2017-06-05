%==========================================================================
% 2014/09/17: this is the file to render pilots
%==========================================================================
PilotConfig;

if PILOT_SETTING == PILOT_SETTING_SIN_1, 
    pilot = sin([0:PILOT_SIZE-1].*2*pi*(11025/44100));
elseif PILOT_SETTING == PILOT_SETTING_CHIRP_HGIH_TO_LOW_1,
    PILOT_FS = 44100;
    PILOT_FREQ_MIN = 11000;
    PILOT_FREQ_MAX = 22000;
    
    t = 0:1/PILOT_FS:(PILOT_SIZE-1)/PILOT_FS;
    tmp = chirp(t,PILOT_FREQ_MIN,(PILOT_SIZE-1)/PILOT_FS,PILOT_FREQ_MAX);
    pilot = tmp(end:-1:1);
else
    assert(0, 'ERROR: undeinfed PILOT_SETTING');
end

pilot = pilot';

save('pilot');

