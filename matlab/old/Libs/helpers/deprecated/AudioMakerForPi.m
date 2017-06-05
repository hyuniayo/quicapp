%==========================================================================
% 2014/09/17: this file is used to replace wavmaker python program
%           : PULSE: the meaningful singal in each repeat
%           : SIGNAL: includes the "zeros" in the end
% 2014/09/21: add functionality of stereo signals
% 2014/09/28: update short freq sweep function
% 2014/10/26: update overlap sweep function (controled by SWEEP_X_OVERLAP)
% 2014/10/28: this version is specialized for pi
% 2014/11/11: redefine sweep function as sin sweep
%==========================================================================
clear;
close all;

GeneralSetting;
load pilot

FS_PI = 96000;
FS = FS_PI; % *** override FS by new setting for pi ***

%AUDIO_BASE_FOLDER = '../source/';
AUDIO_BASE_FOLDER = 'source/';

%--------------------------------------------------------------------------
% 1. Audio setting
%--------------------------------------------------------------------------

%REPEAT_CNT = 40;
REPEAT_CNT = 10;
%PULSE_LEN = 120;
PULSE_LEN = 1000;
%SINGLE_REPEAT_LEN = 40960;
%SINGLE_REPEAT_LEN = 4096*2;
SINGLE_REPEAT_LEN = 96000;

FREQ_MIN = 20000;
FREQ_MAX = 20000;

HAMMING_IS_ENABLED = 0;
PILOT_IS_ENABLED = 1;
STEREO_IS_ENBALED = 1;
if STEREO_IS_ENBALED,
    STEREO_CYCLE = 1;
    STEREO_OFFSET = 0;
    assert(mod(REPEAT_CNT, STEREO_CYCLE) == 0, '[ERROR]: stereo cycle must be a factor of REPEAT_CNT\n');
else
    STEREO_CYCLE = 1; % dummy stere cycle for compatibility
end


%**************************************************************************
% = sin : single tone
% = chirp : one single long sweep
% = sweep : multiple short single tone to simluate sweep
%**************************************************************************
PULSE_TYPE = 'sin';
%PULSE_TYPE = 'chirp';
%PULSE_TYPE = 'sin';
if strcmp(PULSE_TYPE, 'sweep'),
    SWEEP_CYCLE = 20;
    %SWEEP_RIGHT_OVERLAP_RATIO = 1.5; % how much portion of freq (in the right side) shoud be used
    %SWEEP_LEFT_OVERLAP_RATIO = 1; % 1 means don't expand overlap in the left side
end

%--------------------------------------------------------------------------
% 2. Render pulse
%--------------------------------------------------------------------------
if strcmp(PULSE_TYPE,'chirp'),
    t = 0:1/FS:(PULSE_LEN-1)/FS;

    pulse = chirp(t,FREQ_MIN,(PULSE_LEN-1)/FS,FREQ_MAX);

    if HAMMING_IS_ENABLED == 1,
        pulseNoHamming = pulse;
        w = hamming(PULSE_LEN)';
        % normalize hamming window *** TODO: check if it is true ***
        w = w - min(w);
        w = w./max(w);
        pulse = pulse.*w;

        % *** just for debugging ***
        figure;
        subplot(2,1,1);
        plot(pulse,'b-'); legend('pulse w/ hamming');
        subplot(2,1,2);
        plot(pulseNoHamming,'r-'); legend('pulse w/o hamming');
    end

    % *** just for debugging ***
    figure;
    spectrogram(pulse,256,250,256,FS_PI,'yaxis')
end

if strcmp(PULSE_TYPE,'sin'),
    assert(FREQ_MIN==FREQ_MAX, 'Error: sin freq uninsistant');
    t = 0:1/FS:(PULSE_LEN-1)/FS;
    pulse = sin(t.*2.*pi.*FREQ_MAX);
    if HAMMING_IS_ENABLED,
        w = hamming(PULSE_LEN)';
        % normalize hamming window *** TODO: check if it is true ***
        w = w - min(w);
        w = w./max(w);
        pulse = pulse.*w;
    end
end
%--------------------------------------------------------------------------
% 3. Compose repetaed signal
%--------------------------------------------------------------------------

if strcmp(PULSE_TYPE, 'sweep') ,
    %assert(STEREO_IS_ENBALED==1, 'ERROR: sweep must come with stereo');
    % TODO: implement mono one
    
    % estimate sweep freqs
    sweepTotalFreqs = linspace(FREQ_MIN, FREQ_MAX, SWEEP_CYCLE+1);
    sweepStartFreqs = sweepTotalFreqs(1:end-1);
    sweepEndFreqs = sweepTotalFreqs(2:end);
    
    
    sweepSignalOnce = zeros(SINGLE_REPEAT_LEN, SWEEP_CYCLE*STEREO_CYCLE);
    repeatIdx = 1;
    for freqIdx = 1:SWEEP_CYCLE,
        
        t = 0:1/FS:(PULSE_LEN-1)/FS;
        %sweepSignalNow = chirp(t,sweepStartFreqs(freqIdx),(PULSE_LEN-1)/FS,sweepEndFreqs(freqIdx));
        sweepSignalNow = sin(t.*2.*pi.*sweepStartFreqs(freqIdx));
        
        if HAMMING_IS_ENABLED == 1,
            sweepSignalNowNoHamming = sweepSignalNow;
            w = hamming(PULSE_LEN)';
            % normalize hamming window *** TODO: check if it is true ***
            w = w - min(w);
            w = w./max(w);
            sweepSignalNow = sweepSignalNow.*w;

            % *** just for debugging ***
            %{
            figure;
            subplot(2,1,1);
            plot(sweepSignalNow,'b-'); legend('pulse w/ hamming');
            subplot(2,1,2);
            plot(sweepSignalNowNoHamming,'r-'); legend('pulse w/o hamming');
            %}
        end
        
        
        % repeat for stereo setting
        sweepSignalOnce(1:PULSE_LEN, repeatIdx:repeatIdx+STEREO_CYCLE-1) = repmat(sweepSignalNow',1,STEREO_CYCLE);
        
        repeatIdx = repeatIdx + STEREO_CYCLE;
    end
    sweepSignalFull = repmat(sweepSignalOnce, 1, REPEAT_CNT/(SWEEP_CYCLE*STEREO_CYCLE));
    signalTrack = reshape(sweepSignalFull, REPEAT_CNT*SINGLE_REPEAT_LEN, 1);
    %{
    figure;
    spectrogram(signalTrack(:,1),256,250,256,FS,'yaxis')
    %}
else
    % repeat signals
    signalOnce = zeros(SINGLE_REPEAT_LEN, 1);
    signalOnce(1:PULSE_LEN) = pulse;
    signalTrack = repmat(signalOnce, 1, REPEAT_CNT);
    signalTrack = reshape(signalTrack, REPEAT_CNT*SINGLE_REPEAT_LEN, 1);

    
end

% delay signals based on stereo setting
if STEREO_IS_ENBALED,
    signalTrackDelayed = reshape(signalTrack, SINGLE_REPEAT_LEN ,REPEAT_CNT);
    for i = 2:STEREO_CYCLE,
        offsetNow = (i-1)*STEREO_OFFSET;

        signalTrackDelayed(:, i:STEREO_CYCLE:end) = circshift(signalTrackDelayed(:, i:STEREO_CYCLE:end), offsetNow);

    end
    signalTrackDelayed = reshape(signalTrackDelayed, REPEAT_CNT*SINGLE_REPEAT_LEN, 1);
    signalTrackStereo = [signalTrack, signalTrackDelayed];
end




%--------------------------------------------------------------------------
% 4. append pilot and other processing if necessary
%--------------------------------------------------------------------------
if PILOT_IS_ENABLED,
    signalTrackNoPilot = signalTrack;
    % add a polit in the end too -> knowing the sound is end
    signalTrack = [zeros(PILOT_START_OFFSET,1); pilot ;zeros(PILOT_END_OFFSET,1); signalTrack ;zeros(PILOT_END_OFFSET,1); pilot ;zeros(PILOT_START_OFFSET,1);];
    
    
    
    
    if STEREO_IS_ENBALED,
        signalTrackStereoNoPilot = signalTrackStereo;
        signalTrackStereo = [zeros(PILOT_START_OFFSET,2); repmat(pilot, 1, 2) ;zeros(PILOT_END_OFFSET,2); signalTrackStereo;zeros(PILOT_END_OFFSET,2); repmat(pilot,1,2) ;zeros(PILOT_START_OFFSET,2)];
    end
end

%--------------------------------------------------------------------------
% 5. Update signalTrack to signalTrackStereo if necessary
%--------------------------------------------------------------------------
if STEREO_IS_ENBALED,
    signalTrackNoPilot = signalTrackStereoNoPilot;
    signalTrack = signalTrackStereo;
    clear signalTrackStereoNoPilot;
    clear signalTrackStereo;
end

%--------------------------------------------------------------------------
% 6. Output files
%--------------------------------------------------------------------------

fileName = sprintf('hdsource_%drepeat-%dperiod+',REPEAT_CNT,SINGLE_REPEAT_LEN);
if strcmp(PULSE_TYPE,'chirp'),
    fileName = strcat(fileName, sprintf('chirp-%dHz-%dHz-%dsamples', FREQ_MIN, FREQ_MAX, PULSE_LEN));    
elseif strcmp(PULSE_TYPE,'sweep')
    fileName = strcat(fileName, sprintf('sweep-%dcycle-%dHz-%dHz-%dsamples', SWEEP_CYCLE, FREQ_MIN, FREQ_MAX, PULSE_LEN));    
elseif strcmp(PULSE_TYPE,'sin'),
    fileName = strcat(fileName, sprintf('sin-%dHz-%dsamples', FREQ_MIN, PULSE_LEN));    
else
    assert(0,'[ERROR]: undefined pulse type\n');
end

if HAMMING_IS_ENABLED,
    fileName = strcat(fileName,'+hamming');
end

if PILOT_IS_ENABLED,
    fileName = strcat(fileName,'+pilot');
end

if STEREO_IS_ENBALED,
    fileName = strcat(fileName, sprintf('+stereo_%dcycle_%doffset', STEREO_CYCLE, STEREO_OFFSET));
end

fileName

% ourput wav files

wavwrite(signalTrack,FS_PI,WAV_WRITE_N_BITS,strcat(strcat(AUDIO_BASE_FOLDER,fileName),'.wav'));
audiowrite(strcat(strcat(AUDIO_BASE_FOLDER,fileName),'.flac'), signalTrack,FS_PI,'Artist','Fuck');

% check the wav file
[y,fs] = wavread(strcat(strcat(AUDIO_BASE_FOLDER,fileName)));
assert(fs==FS,'[ERROR]: fs is ummatched');
figure; title('read the rendered wav file');
plot(y);

% output mat setting file (for future reference by parser program)
save(strcat(AUDIO_BASE_FOLDER,fileName));
%spectrogram(y(:,1),256,250,256,FS,'yaxis')
