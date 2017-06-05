function [ pilot, pilotToAdd] = LibPilotMaker( PilotMakerRequestPath )
% 2015/09/28: update as a common library to build pilot
% 2015/10/17: update repeat pilot mode which ensure acc pilot sync

load(PilotMakerRequestPath);

if strcmp(PILOT_SETTING, 'PILOT_SETTING_SIN_1'), 
    pilot = sin([0:PILOT_SIZE-1].*2*pi*(11025/44100));
elseif strcmp(PILOT_SETTING, 'PILOT_SETTING_CHIRP_HGIH_TO_LOW_1'),
    t = 0:1/FS:(PILOT_SIZE-1)/FS;
    tmp = chirp(t,PILOT_FREQ_MIN,(PILOT_SIZE-1)/FS,PILOT_FREQ_MAX);
    pilot = tmp(end:-1:1);
elseif strcmp(PILOT_SETTING, 'PILOT_SETTING_CHIRP_HGIH_TO_LOW_HAMMING_1'),
    t = 0:1/FS:(PILOT_SIZE-1)/FS;
    tmp = chirp(t,PILOT_FREQ_MIN,(PILOT_SIZE-1)/FS,PILOT_FREQ_MAX);
    pilot = tmp(end:-1:1);
    
    USE_HAMMING_PILOT_AS_THE_ADDED_PILOT = 1;
    
    % hamming window
    HAMMING_WIN_SIZE = floor(PILOT_SIZE*PILOT_HAMMING_RATIO);
    win = hamming(HAMMING_WIN_SIZE);
    win = win-min(win);
    win = win./max(win);
    [~,maxIdx] = max(win);
    winStart = win(1:maxIdx);
    winEnd = win(maxIdx+1:end);
        
        
    w = ones(1, PILOT_SIZE);
    w(1:length(winStart)) = winStart;
    w(end-length(winEnd)+1:end) = winEnd;
    pilotWithHamming = pilot.*w;
    pilotWithHamming = pilotWithHamming';
else
    assert(0, 'ERROR: undeinfed PILOT_SETTING');
end

pilot = pilot';


if exist('PILOT_REPEAT_IS_ENABLED', 'var') && PILOT_REPEAT_IS_ENABLED == 1, 
    pilotSingleRepeat = zeros(PILOT_SINGLE_REPEAT_LEN, 1);
    
    if exist('USE_HAMMING_PILOT_AS_THE_ADDED_PILOT','var') & USE_HAMMING_PILOT_AS_THE_ADDED_PILOT ==1,
        pilotSingleRepeat(1:length(pilotWithHamming)) = pilotWithHamming;
    else
        pilotSingleRepeat(1:length(pilot)) = pilot;
    end
    
    
    pilotToAdd = repmat(pilotSingleRepeat, [PILOT_REPEAT_CNT,1]);
else
    pilotToAdd = pilot;
end


save('pilot');

end

