function [movingStdNormal, movingStdNoise] = AudioParseForIPhoneInternalNoiseTest( TRACE_BASE_FOLDER, payload)
%==========================================================================
% redefine the audio parse process to use LibLoadAudio.m interface
% 15/09/30: update to parse sync data
% 15/10/04: update to bumpfree
% 15/10/14: chage the function to mainly focus on loading audio traces
% 15/11/01: test parsing iphone data
% 15/11/28: changed to reuse squeeze script to parse noise data
%         : *** There must have 4 squeeze trigger in the trace ***
%         : 1: normal start, 2: normal end, 3: noise start, 4: noise end
%==========================================================================
close all;

ParserConfig;
%GeneralSetting;

DEBUG_SHOW = 1;

PREPROCESS_FILTER_ENABLED = 0;

PULSE_DETECTION_MAX_RANGE_SAMPLES = 1500;
%--------------------------------------------------------------------------
% 0. setting of loading options
%    avaiable setting for audio request:
%    a. 'SERVER_TRACE' : raw data from sockets
%    b. 'WAV_TRACE'    : wav file
%    c. 'BINARY_TRACE' : binary file defined by me
%--------------------------------------------------------------------------

if ~exist('TRACE_BASE_FOLDER','var'),
    %DEFAUGHT_TRACE_BASE_FOLDER = 'Traces/ExternalNoiseFromLaptopTest/DebugOutput/';
    DEFAUGHT_TRACE_BASE_FOLDER = 'Traces/InternalNoiseFromPhoneTest/DebugOutput/';
    TRACE_BASE_FOLDER = DEFAUGHT_TRACE_BASE_FOLDER;
    fprintf('[WARN]: use the defualt TRACE_BASE_FOLDER = %s\n', DEFAUGHT_TRACE_BASE_FOLDER)
    DEBUG_SHOW = 1;
else
    DEBUG_SHOW = 0;
end

loadRequest.name = 'UltraPhone: load audio';
loadRequest.TRACE_BASE_FOLDER = TRACE_BASE_FOLDER;

if exist('payload','var'),
    loadRequest.payload = payload;
end

if length(findstr(TRACE_BASE_FOLDER,'.mat')>0), % get data directly from server
    loadRequest.setting = 'SERVER_TRACE'
    matlabSourceMatName = TRACE_BASE_FOLDER;
    traceChannelCnt = 2;
elseif length(findstr(TRACE_BASE_FOLDER,'.wav')>0),
    loadRequest.setting = 'WAV_TRACE'
    
    matlabSourceMatName = 'source_80repeat-4096period+sweep-4cycle-10lo-15ro-10000Hz-22000Hz-100samples+hamming+pilot+stereo_4cycle_1offset.mat';
    traceChannelCnt = 2;
else
    loadRequest.setting = 'BINARY_TRACE'
    [matlabSourceMatName, traceChannelCnt] = LibGetTraceMatlabSetting(TRACE_BASE_FOLDER);
end
load(strcat(AUDIO_SOURCE_FOLDER, matlabSourceMatName));

if ~exist('STEREO_CYCLE'),
    STEREO_CYCLE = 1; % define it here for backward compatibility
end

if ~exist('traceChannelCnt'),
    loadRequest.traceChannelCnt = 2 %TODO: need to update this
    fprintf('[WARN]: use the default value of traceChannelCnt = %d',loadRequest.traceChannelCnt);
else 
    loadRequest.traceChannelCnt = traceChannelCnt;
end


%--------------------------------------------------------------------------
% 1. setting of parsing options
%--------------------------------------------------------------------------
AUDIO_SAMPLE_TO_FIND_PILOT = 35000; % for iphone


%--------------------------------------------------------------------------
% 2. read trace file from files
%--------------------------------------------------------------------------
traceVec = LibLoadAudio(loadRequest);
traceSound = traceVec./WAV_READ_SIGNAL_MAX; % normalize to [1, -1] 

%--------------------------------------------------------------------------
% 3. find the pilot position and reshape the whole track to matrix
%    *** WARN: only use right channel for finding pilot in stereo data ***
%--------------------------------------------------------------------------
[pilotEndOffset] = LibFindPilot(traceVec(1:AUDIO_SAMPLE_TO_FIND_PILOT), pilot);
assert(pilotEndOffset>0, '[ERROR]: unable to find pilot, (AUDIO_SAMPLE_TO_FIND_PILOT is too short?)');
pilotLenToRemove = pilotEndOffset + PILOT_END_OFFSET;
traceVec = traceVec(pilotLenToRemove+1:end);
repeatToProcess = floor(size(traceVec,1)/SINGLE_REPEAT_LEN); % estimate how many records is made
traceVec = traceVec(1:repeatToProcess*SINGLE_REPEAT_LEN);

%--------------------------------------------------------------------------
% 4. pass signal to filter if need
%--------------------------------------------------------------------------
if PREPROCESS_FILTER_ENABLED,
    fprintf('[WARN]: PREPROCESS_FILTER_ENABLED, need to tune the best parameter for filters\n');
    PRE_FILTER_ORDER = 15;
    %peakWindow = 80;
    PRE_FILTER_CUT_FREQ_LOW = 15000/(FS/2); % normalzed freq
    [pfB, pfA] = butter(PRE_FILTER_ORDER, PRE_FILTER_CUT_FREQ_LOW, 'high');
    
    traceVecNoFilter = traceVec;
    
    traceVec = filter(pfB, pfA, traceVec);
end

%--------------------------------------------------------------------------
% 5. parse the loaded data
%--------------------------------------------------------------------------
if (exist('HAMMING_IS_ENABLED','var') && HAMMING_IS_ENABLED == 1) || (exist('CUSTOMHAMMING_IS_ENABLED','var') && CUSTOMHAMMING_IS_ENABLED == 1),
    %pulseUsed = pulseNoHamming;
    fprintf('[WARN]: pulseUsed is truncated by middle section\n');
    pulseUsed = pulseNoHamming(300:end-300);
else
    pulseUsed = pulse;
end

audioToProcess = reshape(traceVec, [SINGLE_REPEAT_LEN, repeatToProcess, traceChannelCnt]);

conPulse = AudioProcessFindPulseMax(audioToProcess, pulseUsed);

conNow = conPulse(1:PULSE_DETECTION_MAX_RANGE_SAMPLES,:,:); % only take the begining sections

conStamps = [1:SINGLE_REPEAT_LEN:repeatToProcess*SINGLE_REPEAT_LEN]+pilotLenToRemove;

%--------------------------------------------------------------------------
% 6. Load stamps
%         : *** There must have 4 squeeze trigger in the trace ***
%         : 1: normal start, 2: normal end, 3: noise start, 4: noise end
%--------------------------------------------------------------------------
%{
[sseStamps, sseCodes, ~, ~] = LibLoadLog(strcat(TRACE_BASE_FOLDER,'sse.dat'));
codeStamps = sseStamps(sseCodes == 1);
assert(length(codeStamps)==4, '[ERROR]: Must have 4 sse stamps indicating the normal/noise range');
%}

[nosStamps, ~, ~, ~] = LibLoadLog(strcat(TRACE_BASE_FOLDER,'nos.dat'));
codeStamps = nosStamps;
assert(length(codeStamps)==4, '[ERROR]: Must have 4 sse stamps indicating the normal/noise range');

%--------------------------------------------------------------------------
% 7. Estimate overall std
%--------------------------------------------------------------------------
PSE_DETECT_SAMPLE_RANGE = [600:620]; % NOTE: this setting must be set as my force/pressure detection

data = sum(conNow(PSE_DETECT_SAMPLE_RANGE, :));
dataStamps = conStamps;

WAIT_STAMP_OFFSET = FS*1; % 1 sec delay after/before start/stop

if DEBUG_SHOW,
    figure; hold on;
    plot(dataStamps, data);
    YLIM = get(gca,'ylim');
    for codeIdx = 1:length(codeStamps),
        s = codeStamps(codeIdx);
        plot([s,s], YLIM ,'r--');
        if mod(codeIdx,2)==0,
            plot([s-WAIT_STAMP_OFFSET,s-WAIT_STAMP_OFFSET], YLIM ,'g--');
        else
            plot([s+WAIT_STAMP_OFFSET,s+WAIT_STAMP_OFFSET], YLIM ,'g--');
        end
    end
end

dataNormal = data(dataStamps>codeStamps(1)+WAIT_STAMP_OFFSET & dataStamps < codeStamps(2)-WAIT_STAMP_OFFSET); 
dataNoise = data(dataStamps>codeStamps(3)+WAIT_STAMP_OFFSET & dataStamps < codeStamps(4)-WAIT_STAMP_OFFSET);

preEstNormal = dataNormal./mean(dataNormal);
dataNoiseNoise = dataNoise./mean(dataNoise);

if DEBUG_SHOW,
    figure; hold on;
    cdfplot(preEstNormal);
    cdfplot(dataNoiseNoise);
    legend('normal','noise');
    title('overall std');
end
    
std(preEstNormal)
std(dataNoiseNoise)



%--------------------------------------------------------------------------
% 8. Esimate moving std
%--------------------------------------------------------------------------
MOVING_DEPTH = 10; % samples -> 20 samples = 1 second

movingStdNormal = zeros(length(dataNormal) - MOVING_DEPTH, 1);
for i = 1:length(dataNormal) - MOVING_DEPTH,
    movingStdNormal(i) = std(dataNormal(i:i+MOVING_DEPTH)./dataNormal(1));
end

movingStdNoise = zeros(length(dataNoise) - MOVING_DEPTH, 1);
for i = 1:length(dataNoise) - MOVING_DEPTH,
    movingStdNoise(i) = std(dataNoise(i:i+MOVING_DEPTH)./dataNoise(1));
end

if DEBUG_SHOW,
    figure; hold on;
    cdfplot(movingStdNormal);
    cdfplot(movingStdNoise);
    legend('normal','noise');
    title('overall std');
end

