function [SampledDataAll, SampledExtForces, SampledIndxes, SampledDataStamps, SampledOffsets] = AudioParse( TRACE_BASE_FOLDER, payload, PSE_DETECT_SAMPLE_RANGE, PSE_CH_IDXS, PSE_DATA_SAMPLE_PRE_OFFSET)
%==========================================================================
% redefine the audio parse process to use LibLoadAudio.m interface
% 15/09/30: update to parse sync data
% 15/10/04: update to bumpfree
% 15/10/14: chage the function to mainly focus on loading audio traces
% 15/11/01: test parsing iphone data
% 15/11/23: this correct the sensed data with external force sensors
%         : NOTE: this parser must have force_ext.csv file in the trace
%         : An external force over 4000uA must be in the beging and end
% 16/10/22: Note this load the external trace in android
% 16/10/22: Note this is changed to 
%==========================================================================
close all;

ParserConfig;
%GeneralSetting;

DEBUG_SHOW = 1;

PREPROCESS_FILTER_ENABLED = 1;

PULSE_DETECTION_MAX_RANGE_SAMPLES = 1500;
%--------------------------------------------------------------------------
% 0. setting of loading options
%    avaiable setting for audio request:
%    a. 'SERVER_TRACE' : raw data from sockets
%    b. 'WAV_TRACE'    : wav file
%    c. 'BINARY_TRACE' : binary file defined by me
%--------------------------------------------------------------------------
if ~exist('TRACE_BASE_FOLDER','var'),
    DEFAUGHT_TRACE_BASE_FOLDER = '/Users/eddyxd/Downloads/audio/AudioAna/DebugOutput/';
    TRACE_BASE_FOLDER = DEFAUGHT_TRACE_BASE_FOLDER;
    fprintf('[WARN]: use the defualt TRACE_BASE_FOLDER = %s\n', DEFAUGHT_TRACE_BASE_FOLDER)
    
    
    fprintf('[WARN]: defautl sample settin is used\n');
    PSE_DETECT_SAMPLE_RANGE = [595:605]; % This should be set to a larger range -> and the necessary range is fetced out later
    PSE_CH_IDXS = [1:2];
    PSE_DATA_SAMPLE_PRE_OFFSET = 10; % ad-hoc add a overset in case the ref data is not stable
    
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


if ~exist('traceChannelCnt','var'),
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
[pilotEndOffset] = LibFindPilot(traceVec(1:AUDIO_SAMPLE_TO_FIND_PILOT,:), pilot);
assert(pilotEndOffset>0, '[ERROR]: unable to find pilot, (AUDIO_SAMPLE_TO_FIND_PILOT is too short?)');
pilotLenToRemove = pilotEndOffset + PILOT_END_OFFSET;
traceVec = traceVec(pilotLenToRemove+1:end,:);
repeatToProcess = floor(size(traceVec,1)/SINGLE_REPEAT_LEN); % estimate how many records is made
traceVec = traceVec(1:repeatToProcess*SINGLE_REPEAT_LEN,:);

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
% 6. Load other sensor data
%--------------------------------------------------------------------------
[motionStamps, motion] = LibLoadMotion(strcat(TRACE_BASE_FOLDER,'motion.dat'));
accMag = sqrt(sum(motion(1:3, :).^2));
gyroMag = sqrt(sum(motion(4:6, :).^2));

[extStamps, extCurrents] = LibLoadExtForceFromAndroidTrace(strcat(TRACE_BASE_FOLDER,'ext.dat'));
[pseStamps, pseCodes, pseArg0s, pseAarg1s] = LibLoadLog(strcat(TRACE_BASE_FOLDER,'pse.dat'));


%--------------------------------------------------------------------------
% 7. make some app-based processing
%--------------------------------------------------------------------------


dataStamps = conStamps;
%data = conNowSorted(1,:); % use max peak as indicator
dataAll = conNow(PSE_DETECT_SAMPLE_RANGE,:,PSE_CH_IDXS);
codeStamps = pseStamps;
codes = pseCodes;
assert(sum(codes==1) == sum(codes==2));
codeStart = codes(codes==1);
codeStartStamps = codeStamps(codes==1);
codeEnd = codes(codes==2);
codeEndStamps = codeStamps(codes==2);

% variable to put concated datas
SampledDataAll = zeros(length(PSE_DETECT_SAMPLE_RANGE), repeatToProcess, length(PSE_CH_IDXS));

SampledDataPre = zeros(length(PSE_DETECT_SAMPLE_RANGE), repeatToProcess, length(PSE_CH_IDXS));

SampledDataStamps = zeros(repeatToProcess,1);
SampledOffsets = zeros(repeatToProcess,1); % offset after the press
SampledIndxes = zeros(repeatToProcess,1); % just the number of touch
SampledIndex = 1;
SampledCnt = 0;

for codeIdx = 1:length(codeStart),
    endOffset = 300; % samples (avoid the pre data is selected correctly)
    startOffset = 300;
    dataIdxNow = dataStamps < codeEndStamps(codeIdx)+endOffset & dataStamps >  codeStartStamps(codeIdx)-startOffset;
    dataIdxStartNow = find(dataIdxNow>0);
    
    dataIdxRangeIncludePre = dataIdxStartNow(1)-PSE_DATA_SAMPLE_PRE_OFFSET:dataIdxStartNow(end);
    
    %DATA_REF_AHEAD_OFFSET = 2; % ad-hoc add a overset in case the ref data is not stable
    
    if ~isempty(dataIdxStartNow),
        % estimate the pressure
        %ref = repmat(data(dataIdxStartNow(1) - DATA_REF_AHEAD_OFFSET), size(data(dataIdxNow)));
        %ref = repmat(mean(data(dataIdxStartNow(1)-1:-1:dataIdxStartNow(1)-DATA_REF_AHEAD_OFFSET)), size(data(dataIdxNow)));
        %dataChangeNow = abs((data(dataIdxNow) - ref)./ref);
        
        
        
        % put data in to the sampled vectors
        SampledSizeNow = length(dataIdxRangeIncludePre); % include the previous data for reference
        SampledDataAll(:,SampledCnt+[1:SampledSizeNow],:) = dataAll(:,dataIdxRangeIncludePre,:);
        
        SampledDataStamps(SampledCnt+[1:SampledSizeNow]) = dataStamps(dataIdxRangeIncludePre);
        SampledOffsets(SampledCnt+[1:SampledSizeNow]) = 1:SampledSizeNow;
        SampledIndxes(SampledCnt+[1:SampledSizeNow]) = SampledIndex;
        SampledIndex = SampledIndex + 1;
        SampledCnt = SampledCnt + SampledSizeNow;
        
    end
end

% truncated sampled data
SampledDataAll = SampledDataAll(:,1:SampledCnt,:);
SampledDataStamps = SampledDataStamps(1:SampledCnt);
SampledOffsets = SampledOffsets(1:SampledCnt);
SampledIndxes = SampledIndxes(1:SampledCnt);

% sample the other data based on ultraphone sample points
SampledExtForces = SampleDataByRefStamps(extCurrents, extStamps, SampledDataStamps);


