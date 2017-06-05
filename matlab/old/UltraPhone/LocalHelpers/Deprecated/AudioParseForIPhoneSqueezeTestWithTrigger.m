function [conPulseCutted, conCorrected] = AudioParseForIPhoneSqueezeTest( TRACE_BASE_FOLDER, payload)
%==========================================================================
% redefine the audio parse process to use LibLoadAudio.m interface
% 15/09/30: update to parse sync data
% 15/10/04: update to bumpfree
% 15/10/14: chage the function to mainly focus on loading audio traces
% 15/11/01: test parsing iphone data
% 15/11/26: use the java trigger server to know the start time now
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
    %DEFAUGHT_TRACE_BASE_FOLDER = 'Traces/SqueezeTuningWithTrigger/init_test/DebugOutput_shake_first_walk_in_middle_and_walk+squeeze_in_end/';
    DEFAUGHT_TRACE_BASE_FOLDER = 'Traces/Trigger/PhoneTrace/DebugOutput_ssi_2_inpocket_choi_2/';
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
[conNowSorted, conNowSortedIdx] = sort(conNow, 1, 'descend');

conStamps = [1:SINGLE_REPEAT_LEN:repeatToProcess*SINGLE_REPEAT_LEN]+pilotLenToRemove;

%--------------------------------------------------------------------------
% 6. Load other sensor data
%--------------------------------------------------------------------------
[motionStamps, motion] = LibLoadMotion(strcat(TRACE_BASE_FOLDER,'motion.dat'));
acc = motion(1:3, :);
gyro = motion(4:6,:);
%accMag = sqrt(sum(motion(1:3, :).^2));
accMag = sqrt(abs(sum(motion(1:3, :).^2)-1));
accDiff = sqrt(sum((motion(1:3, 2:end)-motion(1:3, 1:end-1)).^2)); accDiff = [0, accDiff];
gyroMag = sqrt(sum(motion(4:6, :).^2));
gyroDiff = sqrt(sum((motion(4:6, 2:end)-motion(4:6, 1:end-1)).^2)); gyroDiff = [0, gyroDiff];


[trgStamps, trgCodes, trgArg0s, trgAarg1s] = LibLoadLog(strcat(TRACE_BASE_FOLDER,'trg.dat'));

ENABLE_CODE = 1;
ENABLE_DURATION_STAMP_OFFSET = 2*FS; % time to disable automatically

dataStamps = conStamps;
data = sum(conNow(595:605,:));
codes = trgCodes;
codeStamps = trgStamps;
%assert(sum(codes==ENABLE_CODE) == sum(codes==DISABLE_CODE));
codeStart = codes(codes==ENABLE_CODE);
codeStartStamps = codeStamps(codes==ENABLE_CODE);

% set diable stampe to certian period of time
codeEndStamps = codeStartStamps+ENABLE_DURATION_STAMP_OFFSET;
CODE_CNT = length(codeStart);
%--------------------------------------------------------------------------
% 7. make squeeze only detections
%--------------------------------------------------------------------------
figure; hold on;
plot(dataStamps, data);
plot(dataStamps, smooth(data,3),'m--');
for codeIdx = 1:length(codeStart),
    yLimNow = get(gca, 'ylim');
    plot([codeStartStamps(codeIdx),codeStartStamps(codeIdx)], yLimNow, 'r--');
    plot([codeEndStamps(codeIdx),codeEndStamps(codeIdx)], yLimNow, 'g--'); 
end

codeDetectPeakCnts = zeros(CODE_CNT, 1);
codeDetectChecks = zeros(CODE_CNT, 1);
for codeIdx = 1:length(codeStart),
    [sRatio, peakX, check] = SqueezeDetect(data(dataStamps >= codeStartStamps(codeIdx) & dataStamps <= codeEndStamps(codeIdx)));
    codeDetectPeakCnts(codeIdx) = length(peakX);
    %sRatios(:, x) = sRatio;
    codeDetectChecks(codeIdx) = check;
end

%--------------------------------------------------------------------------
% 8. make overall squeeze detections
%--------------------------------------------------------------------------
SQUEEZE_LEN_TO_CHECK = 25;

peakCnts = zeros(repeatToProcess, 1);
sRatios = zeros(SQUEEZE_LEN_TO_CHECK, repeatToProcess);
checks = zeros(repeatToProcess, 1);
motionStates = zeros(repeatToProcess, 1);
mAccMetricsIn = zeros(repeatToProcess, 1);
mAccMetricsBefore = zeros(repeatToProcess, 1);
mGyroMetricsIn = zeros(repeatToProcess, 1);
mGyroMetricsBefore = zeros(repeatToProcess, 1);

% use the last point as reference
%for x = 1:repeatToProcess - SQUEEZE_LEN_TO_CHECK,
MOTION_BEFORE_OFFSET = 20; % // look 20 before
for x = 1+SQUEEZE_LEN_TO_CHECK+MOTION_BEFORE_OFFSET:repeatToProcess,
    rangeToDetect = x-SQUEEZE_LEN_TO_CHECK+1:x;
    rangeBefore = x-SQUEEZE_LEN_TO_CHECK-MOTION_BEFORE_OFFSET+1:x-SQUEEZE_LEN_TO_CHECK;
    
    [sRatio, peakX, check] = SqueezeDetect(data(rangeToDetect));
    
    peakCnts(x) = length(peakX);
    sRatios(:, x) = sRatio;
    checks(x) = check;
    
    motionInRange = logical(motionStamps>=dataStamps(rangeToDetect(1)) & motionStamps<=dataStamps(rangeToDetect(end)));
    motionBeforeRange = logical(motionStamps>=dataStamps(rangeBefore(1)) & motionStamps<=dataStamps(rangeBefore(end)));
    [motionState, accMetricIn, accMetricBefore, gyroMetricIn, gyroMetricBefore] =  MotionDetect(accMag(motionInRange), gyroMag(motionInRange), accMag(motionBeforeRange), gyroMag(motionBeforeRange));
    motionStates(x) = motionState;
    mAccMetricsIn(x) = accMetricIn;
    mAccMetricsBefore(x) = accMetricBefore;
    mGyroMetricsIn(x) = gyroMetricIn;
    mGyroMetricsBefore(x) = gyroMetricBefore;
end

% *** used for debug ***
figure;
subplot(4,1,1); hold on;
plot(data);
plot(smooth(data,2),'m--');
yLimNow = get(gca, 'ylim');
for codeIdx = 1:length(codeStart),
    codeSampleIdxs = LibFindStartAndEndRange([codeStartStamps(codeIdx), codeEndStamps(codeIdx)], dataStamps);
    plot([codeSampleIdxs(1),codeSampleIdxs(1)], yLimNow, 'r--');
    plot([codeSampleIdxs(2),codeSampleIdxs(2)], yLimNow, 'g--'); 
end
subplot(4,1,2); hold on;
plot(peakCnts);
plot(checks,'ro-');
ylim([-1,5]);
set(gca,'ytick',[-1:5]);
subplot(4,1,3); hold on;
stampToSampleScale = length(data)/motionStamps(end);
%plot((motionStamps-motionStamps(1))*stampToSampleScale, accMag);
%plot(repmat((motionStamps-motionStamps(1))*stampToSampleScale, [1,3]), motion(1:3, :)'); legend('x','y','z');
plot(repmat((motionStamps-motionStamps(1))*stampToSampleScale, [1,1]), accMag'); 
plot(mAccMetricsIn','--');
plot(mAccMetricsBefore','-.');
legend('accMag','in','before');
yLimNow = get(gca, 'ylim');
for codeIdx = 1:length(codeStart),
    codeSampleIdxs = LibFindStartAndEndRange([codeStartStamps(codeIdx), codeEndStamps(codeIdx)], dataStamps);
    plot([codeSampleIdxs(1),codeSampleIdxs(1)], yLimNow, 'r--');
    plot([codeSampleIdxs(2),codeSampleIdxs(2)], yLimNow, 'g--'); 
end

subplot(4,1,4); hold on;
%plot((motionStamps-motionStamps(1))*stampToSampleScale, gyroMag);
%plot(repmat((motionStamps-motionStamps(1))*stampToSampleScale, [1,3]), motion(4:6, :)'); legend('yaw','pitch','roll');
plot(repmat((motionStamps-motionStamps(1))*stampToSampleScale, [1,1]), gyroMag'); 
plot(mGyroMetricsIn');
plot(mGyroMetricsBefore');
legend('gyroMag','in','before');
yLimNow = get(gca, 'ylim');
for codeIdx = 1:length(codeStart),
    codeSampleIdxs = LibFindStartAndEndRange([codeStartStamps(codeIdx), codeEndStamps(codeIdx)], dataStamps);
    plot([codeSampleIdxs(1),codeSampleIdxs(1)], yLimNow, 'r--');
    plot([codeSampleIdxs(2),codeSampleIdxs(2)], yLimNow, 'g--'); 
end

%--------------------------------------------------------------------------
% 4. save trace to file if need
%--------------------------------------------------------------------------
save(strcat(TRACE_BASE_FOLDER,'trace.mat'),'data');


