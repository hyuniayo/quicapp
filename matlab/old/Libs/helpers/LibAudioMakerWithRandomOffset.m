function [ result ] = LibAudioMakerWithRandomOffset( AudioMakerRequestPath )
%==========================================================================
% 2015/09/28: update as a common library to be accessed by all Audio apps
%           : include pilot maker in this script
%==========================================================================
load(AudioMakerRequestPath);

assert(SINGLE_REPEAT_LEN >= PULSE_LEN, '[ERROR]: SINGLE_REPEAT_LEN must be greater than PULSE_LEN');

[pilot, pilotToAdd] = LibPilotMaker(AudioMakerRequestPath); % forward reqest to make pilot

%--------------------------------------------------------------------------
% 1. Audio setting
%--------------------------------------------------------------------------
% deprecated -> now load from request

EXTEND_CUSTOM_HAMMING = 0;

%--------------------------------------------------------------------------
% 2. Render pulse
%--------------------------------------------------------------------------
if strcmp(PULSE_TYPE,'chirp'),
    t = 0:1/FS:(PULSE_LEN-1)/FS;

    pulse = chirp(t,FREQ_MIN,(PULSE_LEN-1)/FS,FREQ_MAX);

    
    
    assert(~exist('HAMMING_IS_ENABLED', 'var') || ~exist('HAMMING_IS_ENABLED', 'var') || exist('HAMMING_IS_ENABLED', 'var') && HAMMING_IS_ENABLED*CUSTOMHAMMING_IS_ENABLED == 0, '[ERROR]: HAMMING_IS_ENABLED and HAMMING_IS_ENABLED cant be set at the same time');
    
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
    
    if exist('CUSTOMHAMMING_IS_ENABLED','var') && CUSTOMHAMMING_IS_ENABLED == 1,
        fprintf('CUSTOMHAMMING_IS_ENABLED not supported in sweep yet\n');
        pulseNoHamming = pulse;
        
        % hamming window
        win = hamming(CUSTOMHAMMING_WINDOW_SIZE);
        win = win-min(win);
        win = win./max(win);
        [~,maxIdx] = max(win);
        winStart = win(1:maxIdx);
        winEnd = win(maxIdx+1:end);
        
        % linear window
        %winStart = linspace(0,1,CUSTOMHAMMING_WINDOW_SIZE/2).';
        %winEnd = linspace(1,0,CUSTOMHAMMING_WINDOW_SIZE/2).';
        
        w = ones(1, PULSE_LEN);
        w(1:length(winStart)) = winStart;
        w(end-length(winEnd)+1:end) = winEnd;
        
        
        
        if EXTEND_CUSTOM_HAMMING == 1,
            fadeStart = chirp(t(1:CUSTOMHAMMING_WINDOW_SIZE/2),FREQ_MAX,(CUSTOMHAMMING_WINDOW_SIZE/2-1),FREQ_MAX).*(winStart.');
            fadeEnd = chirp(t(1:CUSTOMHAMMING_WINDOW_SIZE/2),FREQ_MIN,(CUSTOMHAMMING_WINDOW_SIZE/2-1),FREQ_MIN).*(winEnd.');
        else
            pulse = pulse.*w;
        end
        
        
        % *** just for debugging ***
        figure;
        subplot(2,1,1);
        plot(pulse,'b-'); legend('pulse w/ hamming');
        subplot(2,1,2);
        plot(pulseNoHamming,'r-'); legend('pulse w/o hamming');
        
        figure;
        plot(abs(conv(pulseNoHamming, pulseNoHamming(end:-1:1))), '-o');
    end
        

    % *** just for debugging ***
    %figure;
    %spectrogram(pulse,256,250,256,FS,'yaxis')
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
    
    
    % expand the overlaping!
    for freqIdx = 1:SWEEP_CYCLE,
        diffFreq = sweepEndFreqs(freqIdx) - sweepStartFreqs(freqIdx);
        midFreq = (sweepStartFreqs(freqIdx) + sweepEndFreqs(freqIdx))/2;
        
        % update freqs
        sweepStartFreqs(freqIdx) = midFreq +diffFreq/2 - diffFreq*SWEEP_LEFT_OVERLAP_RATIO;
        sweepEndFreqs(freqIdx) = midFreq -diffFreq/2 + diffFreq*SWEEP_RIGHT_OVERLAP_RATIO;
    end
    
    % parse necessary 
    assert(mod(REPEAT_CNT,STEREO_CYCLE*SWEEP_CYCLE)==0, 'ERROR: sweep/stereo cycle setting error');

    
    
    sweepSignalOnce = zeros(SINGLE_REPEAT_LEN, SWEEP_CYCLE*STEREO_CYCLE);
    repeatIdx = 1;
    for freqIdx = 1:SWEEP_CYCLE,
        
        t = 0:1/FS:(PULSE_LEN-1)/FS;
        sweepSignalNow = chirp(t,sweepStartFreqs(freqIdx),(PULSE_LEN-1)/FS,sweepEndFreqs(freqIdx));
        
        
        % just add normal hamming windows
        if exist('HAMMING_IS_ENABLED', 'var') && HAMMING_IS_ENABLED == 1,
            fprintf('HAMMING_IS_ENABLED\n');
            sweepSignalNowNoHamming = sweepSignalNow;
            w = hamming(PULSE_LEN)';
            % normalize hamming window *** TODO: check if it is true ***
            w = w - min(w);
            w = w./max(w);
            sweepSignalNow = sweepSignalNow.*w;
        end
        
        
        % *** start debug ***
            figure;
            subplot(2,1,1);
            plot(sweepSignalNow,'b-'); legend('pulse w/ hamming');
            subplot(2,1,2);
            plot(sweepSignalNowNoHamming,'r-'); legend('pulse w/o hamming');
        % *** endof debug ***
        
        
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
    
    
    % *** overwirte the signalOnce by fade-in fade-out effects
    if exist('CUSTOMHAMMING_IS_ENABLED','var') && CUSTOMHAMMING_IS_ENABLED == 1 && EXTEND_CUSTOM_HAMMING == 1,
        signalOnce(PULSE_LEN+1:PULSE_LEN+CUSTOMHAMMING_WINDOW_SIZE/2) = fadeEnd;
        signalOnce(end-CUSTOMHAMMING_WINDOW_SIZE/2+1:end) = fadeStart;
    end
    
    % add random offset here
    randomOffsets = ceil(rand(REPEAT_CNT, 1)*(SINGLE_REPEAT_LEN-PULSE_LEN));
    signalTrack = zeros(SINGLE_REPEAT_LEN, REPEAT_CNT);
    for repeatIdx = 1:REPEAT_CNT,
        repeatIdx
        signalTrack(randomOffsets(repeatIdx):randomOffsets(repeatIdx)+PULSE_LEN-1, repeatIdx) = pulse;
    end
    
    %signalTrack = repmat(signalOnce, 1, REPEAT_CNT);
    
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
    signalTrack = [zeros(PILOT_START_OFFSET,1); pilotToAdd ;zeros(PILOT_END_OFFSET,1); signalTrack];
    
    % *** overwirte the pilot before signalOnce by fade-in effects
    if exist('CUSTOMHAMMING_IS_ENABLED','var') && CUSTOMHAMMING_IS_ENABLED == 1 && EXTEND_CUSTOM_HAMMING == 1,
        signalTrack(end-length(signalTrackNoPilot)-CUSTOMHAMMING_WINDOW_SIZE/2+1:end-length(signalTrackNoPilot)) = fadeStart;
    end
    
    if STEREO_IS_ENBALED,
        signalTrackStereoNoPilot = signalTrackStereo;
        signalTrackStereo = [zeros(PILOT_START_OFFSET,2); repmat(pilotToAdd, 1, 2) ;zeros(PILOT_END_OFFSET,2); signalTrackStereo];
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


fileName = sprintf('random_offset_source_%drate-%drepeat-%dperiod+',FS,REPEAT_CNT,SINGLE_REPEAT_LEN);
%fileName = sprintf('source_%drate_%drepeat_%dperiod+',FS,REPEAT_CNT,SINGLE_REPEAT_LEN);
if strcmp(PULSE_TYPE,'chirp'),
    fileName = strcat(fileName, sprintf('chirp-%dHz-%dHz-%dsamples', FREQ_MIN, FREQ_MAX, PULSE_LEN));    
elseif strcmp(PULSE_TYPE,'sweep')
    fileName = strcat(fileName, sprintf('sweep-%dcycle-%dlo-%dro-%dHz-%dHz-%dsamples', SWEEP_CYCLE, SWEEP_LEFT_OVERLAP_RATIO*10, SWEEP_RIGHT_OVERLAP_RATIO*10, FREQ_MIN, FREQ_MAX, PULSE_LEN));    
else
    assert(0,'[ERROR]: undefined pulse type\n');
end

if HAMMING_IS_ENABLED,
    fileName = strcat(fileName,'+hamming');
end

if exist('CUSTOMHAMMING_IS_ENABLED','var') && CUSTOMHAMMING_IS_ENABLED,
    fileName = strcat(fileName,'+chwin'); %custom hamming window
    fileName = strcat(fileName,num2str(CUSTOMHAMMING_WINDOW_SIZE));
end

if PILOT_IS_ENABLED,
    if strcat(PILOT_SETTING,'PILOT_SETTING_CHIRP_HGIH_TO_LOW_1'),
        fileName = strcat(fileName,'+pilotchirp');
    else
        fileName = strcat(fileName,'+pilot');
    end
    if exist('PILOT_REPEAT_IS_ENABLED','var') && PILOT_REPEAT_IS_ENABLED == 1,
        fileName = strcat(fileName,'repeat');
    end
end

if STEREO_IS_ENBALED,
    fileName = strcat(fileName, sprintf('+stereo_%dcycle_%doffset', STEREO_CYCLE, STEREO_OFFSET));
end

% *** just for debug ***
%{
figure; title('correlation');
subplot(3,1,1); title('pilot correlation'); % plot pilot correlation
plot(abs(conv(signalTrack(:,1),pilot(end:-1:1))));
ylabel('pilot correlation');
subplot(3,1,2); title('signal correlation');
plot(abs(conv(signalTrack(:,1),pulse(end:-1:1))));
ylabel('pulse correlation');
if exist('CUSTOMHAMMING_WINDOW_SIZE','var'),
    subplot(3,1,3); title('signal correlation (inside window)');
    plot(abs(conv(signalTrack(:,1),pulse(end-CUSTOMHAMMING_WINDOW_SIZE/2:-1:1+CUSTOMHAMMING_WINDOW_SIZE/2))));
    ylabel('pulse correlation (only inside window)');
end
%}
% *** the deubg ends ***

fileName

% ourput wav files
DEBUG_GAIN = 0.95;
fprintf('[WARN]: DEBUG_GAIN = %f\n',DEBUG_GAIN);
%audiowrite(signalTrack.*DEBUG_GAIN,FS,WAV_WRITE_N_BITS,strcat(strcat(AUDIO_SOURCE_FOLDER,fileName),'.wav'));
audiowrite(strcat(strcat(AUDIO_SOURCE_FOLDER,fileName),'.wav'), signalTrack.*DEBUG_GAIN,FS, 'BitsPerSample', WAV_WRITE_N_BITS);

% check the wav file
[y,fs] = audioread(strcat(strcat(strcat(AUDIO_SOURCE_FOLDER,fileName)),'.wav'));
assert(fs==FS,'[ERROR]: fs is ummatched');
figure; title('read the rendered wav file');
plot(y);



% output mat setting file (for future reference by parser program)
save(strcat(AUDIO_SOURCE_FOLDER,fileName));
%spectrogram(y(:,1),256,250,256,FS,'yaxis')

result.y = y;

end

