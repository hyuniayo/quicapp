%==========================================================================
% 2015/11/11: this script is copy from audio Parse functions
%           : for comparing matlab or JNI parse results
% 2015/12/03: add function to load data
%==========================================================================

close all;

ParserConfig;

DEBUG_SHOW = 1;
PREPROCESS_FILTER_ENABLED = 1;

PULSE_DETECTION_MAX_RANGE_SAMPLES = 1500;

TRACE_BASE_FOLDER = '/Users/eddyxd/Downloads/note5debug/DebugOutput/';
JNI_LOG_FOLDER = strcat(TRACE_BASE_FOLDER, 'log/')

loadRequest.name = 'UltraPhone: load audio';
loadRequest.TRACE_BASE_FOLDER = TRACE_BASE_FOLDER;
loadRequest.setting = 'BINARY_TRACE'
[matlabSourceMatName, traceChannelCnt] = LibGetTraceMatlabSetting(TRACE_BASE_FOLDER);
load(strcat(AUDIO_SOURCE_FOLDER, matlabSourceMatName));
loadRequest.traceChannelCnt = traceChannelCnt;

%--------------------------------------------------------------------------
% 1. setting of parsing options
%--------------------------------------------------------------------------
%AUDIO_SAMPLE_TO_FIND_PILOT = 48000; % for iphone
AUDIO_SAMPLE_TO_FIND_PILOT = 35000; % for iphone


%--------------------------------------------------------------------------
% 2. read trace file from files
%--------------------------------------------------------------------------
traceVec = LibLoadAudio(loadRequest);
traceSound = traceVec./WAV_READ_SIGNAL_MAX; % normalize to [1, -1] 


%**************************************************************************
% load debug csv files
%**************************************************************************
jni_pilot_signal = csvread(strcat(JNI_LOG_FOLDER,'jni_pilot_signal.csv'));
jni_pilot_con = csvread(strcat(JNI_LOG_FOLDER,'jni_pilot_con.csv'));
jni_audio_before_remove = csvread(strcat(JNI_LOG_FOLDER,'jni_audio_before_remove.csv'));
jni_audio_after_remove = csvread(strcat(JNI_LOG_FOLDER,'jni_audio_after_remove.csv'));

matlab_pilot_con = abs(convn(traceVec(1:AUDIO_SAMPLE_TO_FIND_PILOT,2), pilot(end:-1:1),'same'));
conMeans = mean(matlab_pilot_con);
conStds = std(matlab_pilot_con);
thres = conMeans + 15*conStds;
PILOT_SEARCH_PEAK_WINDOW = 30;
validPeakIdxs = LibGetValidPeaks( matlab_pilot_con, thres,  PILOT_SEARCH_PEAK_WINDOW, 1);
PILOT_REPEAT_DIFF = 1000;
pilotEndOffset = validPeakIdxs(end) - floor(length(pilot)/2) + PILOT_REPEAT_DIFF;

%--------------------------------------------------------------------------
% 3. find the pilot position and reshape the whole track to matrix
%    *** WARN: only use right channel for finding pilot in stereo data ***
%--------------------------------------------------------------------------
%[pilotEndOffset] = LibFindPilot(traceVec(1:AUDIO_SAMPLE_TO_FIND_PILOT,:), pilot);


assert(pilotEndOffset>0, '[ERROR]: unable to find pilot, (AUDIO_SAMPLE_TO_FIND_PILOT is too short?)');
pilotLenToRemove = pilotEndOffset + PILOT_END_OFFSET;
traceVec = traceVec(pilotLenToRemove+1:end,:);
repeatToProcess = floor(size(traceVec,1)/SINGLE_REPEAT_LEN); % estimate how many records is made
traceVec = traceVec(1:repeatToProcess*SINGLE_REPEAT_LEN,:);

%--------------------------------------------------------------------------
% 4. pass signal to filter if need
%--------------------------------------------------------------------------
%{
if PREPROCESS_FILTER_ENABLED,
    fprintf('[WARN]: PREPROCESS_FILTER_ENABLED, need to tune the best parameter for filters\n');
    PRE_FILTER_ORDER = 15;
    %peakWindow = 80;
    PRE_FILTER_CUT_FREQ_LOW = 15000/(FS/2); % normalzed freq
    [pfB, pfA] = butter(PRE_FILTER_ORDER, PRE_FILTER_CUT_FREQ_LOW, 'high');
    
    traceVecNoFilter = traceVec;
    
    traceVec = filter(pfB, pfA, traceVec);
end
%}
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

if PREPROCESS_FILTER_ENABLED,
    audioToProcessNoFilter = audioToProcess;
    PRE_FILTER_ORDER = 15;
    PRE_FILTER_CUT_FREQ_LOW = 15000/(FS/2); % normalzed freq
    [pfB, pfA] = butter(PRE_FILTER_ORDER, PRE_FILTER_CUT_FREQ_LOW, 'high');
    
    audioToProcess = filter(pfB, pfA, audioToProcessNoFilter);
    %{
    audioMyFiltered = zeros(size(audioToProcess));
    for chIdx =1:traceChannelCnt,
        for repeatIdx = 1:repeatToProcess,
            audioMyFiltered(:,repeatIdx, chIdx) = FilterImplementTest(pfB, pfA, audioToProcessNoFilter(:,repeatIdx, chIdx));
        end
    end
    %}
end


conPulse = AudioProcessFindPulseMax(audioToProcess, pulseUsed);

conNow = conPulse(1:PULSE_DETECTION_MAX_RANGE_SAMPLES,:,:); % only take the begining sections
[conNowSorted, conNowSortedIdx] = sort(conNow, 1, 'descend');


%**************************************************************************
% load debug csv files
%**************************************************************************
%{
jni_audio_0_0 = csvread(strcat(JNI_LOG_FOLDER,'jni_audio_0_0.csv'));
jni_audio_0_1 = csvread(strcat(JNI_LOG_FOLDER,'jni_audio_0_1.csv'));
jni_audio_1_0 = csvread(strcat(JNI_LOG_FOLDER,'jni_audio_1_0.csv'));
jni_audio_1_1 = csvread(strcat(JNI_LOG_FOLDER,'jni_audio_1_1.csv'));

jni_audio_filtered_0_0 = csvread(strcat(JNI_LOG_FOLDER,'jni_audio_filtered_0_0.csv'));
jni_audio_filtered_0_1 = csvread(strcat(JNI_LOG_FOLDER,'jni_audio_filtered_0_1.csv'));
jni_audio_filtered_1_0 = csvread(strcat(JNI_LOG_FOLDER,'jni_audio_filtered_1_0.csv'));
jni_audio_filtered_1_1 = csvread(strcat(JNI_LOG_FOLDER,'jni_audio_filtered_1_1.csv'));

jni_con_0_0 = csvread(strcat(JNI_LOG_FOLDER,'jni_con_0_0.csv'));
jni_con_0_1 = csvread(strcat(JNI_LOG_FOLDER,'jni_con_0_1.csv'));
jni_con_1_0 = csvread(strcat(JNI_LOG_FOLDER,'jni_con_1_0.csv'));
jni_con_1_1 = csvread(strcat(JNI_LOG_FOLDER,'jni_con_1_1.csv'));


close all;
plot(jni_audio_0_0,'bx-');
hold on; plot(audioToProcessNoFilter(:,1,1), 'ro');

close all;
plot(jni_audio_filtered_0_0,'bx-');
hold on; plot(audioToProcess(:,1,1), 'ro');

close all;
plot(jni_con_0_0,'bx-');
hold on; plot(conNow(:,1,1), 'ro');

close all;
plot(csvread(strcat(JNI_LOG_FOLDER,'jni_con_17_1.csv')),'bx-');
hold on; plot(conNow(:,18,2), 'ro');

conStamps = [1:SINGLE_REPEAT_LEN:repeatToProcess*SINGLE_REPEAT_LEN]+pilotLenToRemove;
%}

% load data
LOAD_REPEAT_CNT = 5;
LOAD_CH_IDX = 2; % here is the matlab index -> need to minus 1 for c++
LOAD_DETECT_RANGE = [600:620]; 
jni_conCell = cell(LOAD_REPEAT_CNT,1);
jni_dataCell = cell(LOAD_REPEAT_CNT,1);
for repeatIdx = 1:LOAD_REPEAT_CNT,
    repeatIdx
    % NOTE con csv might not be outputed due to optimization
    %jni_conCell{repeatIdx} = csvread(sprintf('%sjni_con_%d_%d.csv',JNI_LOG_FOLDER, repeatIdx-1, LOAD_CH_IDX-1));
    jni_dataCell{repeatIdx} = csvread(sprintf('%sjni_data_%d.csv',JNI_LOG_FOLDER, repeatIdx-1));
    
    
    figure; hold on;
    %plot(jni_conCell{repeatIdx}); 
    plot(conNow(:,repeatIdx, LOAD_CH_IDX), '-'); 
    plot(LOAD_DETECT_RANGE, jni_dataCell{repeatIdx}, 'rx');
    legend('matlab con','jni optimized');
    %legend('jni con','matlab con','jni optimized');
end


%--------------------------------------------------------------------------
% 6. Load other sensor data
%--------------------------------------------------------------------------
[pseStamps, pseCodes, pseArg0s, pseAarg1s] = LibLoadLog(strcat(TRACE_BASE_FOLDER,'pse.dat'));

%--------------------------------------------------------------------------
% 7. make some app-based processing
%--------------------------------------------------------------------------
data = sum(conNow(LOAD_DETECT_RANGE,:,LOAD_CH_IDX)); % trace parsed by matlab 
jni_dataSum = csvread(sprintf('%sjni_dataSum.csv',JNI_LOG_FOLDER));

figure; hold on;
plot(data);
plot(jni_dataSum, 'rx', 'markersize', 20);
legend('matlab data','jni data optimized');



%{
codeStamps = pseStamps;
codes = pseCodes;
assert(sum(codes==1) == sum(codes==2));
codeStart = codes(codes==1);
codeStartStamps = codeStamps(codes==1);
codeEnd = codes(codes==2);
codeEndStamps = codeStamps(codes==2);

codeResult = cell(length(codeStart), 1);
for codeIdx = 1:length(codeStart),
    endOffset = 0; % samples
    startOffset = 0;
    dataIdxNow = dataStamps < codeEndStamps(codeIdx)+endOffset & dataStamps >  codeStartStamps(codeIdx)-startOffset;
    dataIdxStartNow = find(dataIdxNow>0);
    
    %dataIdxStartNow = 10:30; % just for debug
    
    if length(dataIdxStartNow)>0,
        ref = repmat(data(dataIdxStartNow(1)), size(data(dataIdxStartNow)));
        result = abs((data(dataIdxStartNow) - ref)./ref)
        
        jni_reply = csvread(strcat(JNI_LOG_FOLDER,'jni_reply.csv'));
        
        figure; hold on;
        plot(jni_reply,'b-');
        plot(result,'ro');
    end
end
%}