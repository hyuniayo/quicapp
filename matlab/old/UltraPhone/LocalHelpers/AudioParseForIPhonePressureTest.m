function [conPulseCutted, conCorrected] = AudioParse( TRACE_BASE_FOLDER, payload)
%==========================================================================
% redefine the audio parse process to use LibLoadAudio.m interface
% 15/09/30: update to parse sync data
% 15/10/04: update to bumpfree
% 15/10/14: chage the function to mainly focus on loading audio traces
% 15/11/01: test parsing iphone data
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

if ~exist('TRACE_BASE_FOLDER'),
    DEFAUGHT_TRACE_BASE_FOLDER = 'Traces/iOSDiffPressureTest/AudioAna/DebugOutput/'; % server traces
    TRACE_BASE_FOLDER = DEFAUGHT_TRACE_BASE_FOLDER;
    fprintf('[WARN]: use the defualt TRACE_BASE_FOLDER = %s\n', DEFAUGHT_TRACE_BASE_FOLDER)
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
AUDIO_SAMPLE_TO_FIND_PILOT = 23000; % for iphone


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
[conNowSorted, conNowSortedIdx] = sort(conNow, 1, 'descend');

conStamps = [1:SINGLE_REPEAT_LEN:repeatToProcess*SINGLE_REPEAT_LEN]+pilotLenToRemove;

%--------------------------------------------------------------------------
% 6. Load other sensor data
%--------------------------------------------------------------------------
[motionStamps, motion] = LibLoadMotion(strcat(TRACE_BASE_FOLDER,'motion.dat'));
accMag = sqrt(sum(motion(1:3, :).^2));
gyroMag = sqrt(sum(motion(4:6, :).^2));

[forceStamps, force] = LibLoadForce(strcat(TRACE_BASE_FOLDER,'force.dat'));
[pseStamps, pseCodes, pseArg0s, pseAarg1s] = LibLoadLog(strcat(TRACE_BASE_FOLDER,'pse.dat'));

%--------------------------------------------------------------------------
% 7. make some app-based processing
%--------------------------------------------------------------------------

dataStamps = conStamps;
%data = conNowSorted(1,:); % use max peak as indicator
data = sum(conNow(595:605,:));
codeStamps = pseStamps;
codes = pseCodes;
assert(sum(codes==1) == sum(codes==2));
codeStart = codes(codes==1);
codeStartStamps = codeStamps(codes==1);
codeEnd = codes(codes==2);
codeEndStamps = codeStamps(codes==2);

codeResult = cell(length(codeStart), 1);
for codeIdx = 1:length(codeStart),
    endOffset = 300; % samples
    startOffset = 300;
    dataIdxNow = dataStamps < codeEndStamps(codeIdx)+endOffset & dataStamps >  codeStartStamps(codeIdx)-startOffset;
    dataIdxStartNow = find(dataIdxNow>0);
    
    if length(dataIdxStartNow)>0,
        codeResult{codeIdx}.data = data(dataIdxNow);
        codeResult{codeIdx}.dataStamps = dataStamps(dataIdxNow);
        codeResult{codeIdx}.dataIdxs = dataIdxNow;
        
        ref = repmat(data(dataIdxStartNow(1)), size(data(dataIdxNow)));
        codeResult{codeIdx}.dataChange = abs((data(dataIdxNow) - ref)./ref);
    end
end


%--------------------------------------------------------------------------
% 8. visualize data loaded (optional)
%--------------------------------------------------------------------------
if DEBUG_SHOW,
    figure;
    TOTAL_FIGURE_CNT = 5;
    X_LIM = [conStamps(1), conStamps(end)];
    subplot(TOTAL_FIGURE_CNT,1,1); ylabel('data');
    plot(conStamps, data,'-o');
    xlim(X_LIM);
    subplot(TOTAL_FIGURE_CNT,1,2); ylabel('accMag diff'); hold on;
    plot(motionStamps, accMag);
    %plot(motionStamps(2:end), abs(accMag(2:end)-accMag(1:end-1)));
    xlim(X_LIM);
    subplot(TOTAL_FIGURE_CNT,1,3); ylabel('gyroMag diff'); hold on;
    plot(motionStamps, gyroMag);
    %plot(motionStamps(2:end), abs(gyroMag(2:end)-gyroMag(1:end-1)));
    xlim(X_LIM);
    subplot(TOTAL_FIGURE_CNT,1,4); ylabel('force'); hold on;
    plot(forceStamps, force);
    xlim(X_LIM);
    subplot(TOTAL_FIGURE_CNT,1,5); ylabel('data change');
    hold on;
    for codeIdx = 1:length(codeStart),
        if ~isempty(codeResult{codeIdx}),
            plot(codeResult{codeIdx}.dataStamps, codeResult{codeIdx}.dataChange, 'o');
        end
    end
    xlim(X_LIM);
end

%--------------------------------------------------------------------------
% 4. save trace to file if need
%--------------------------------------------------------------------------
save(strcat(TRACE_BASE_FOLDER,'trace.mat'));


%{
WIN_SIZE = 21; % must be a odd number
p = PeakDetection(conCorrected{2}(:,2), WIN_SIZE);
ShowEachDetection(conCorrected, 5, 6, SOUND_SPEED, FS);
%}
