function [conPulseCutted, conCorrected] = AudioParse( TRACE_BASE_FOLDER, payload)
%==========================================================================
% redefine the audio parse process to use LibLoadAudio.m interface
% 15/09/30: update to parse sync data
% 15/10/04: update to bumpfree
% 15/10/14: chage the function to mainly focus on loading audio traces
% 15/11/01: test parsing iphone data
% 15/11/23: this correct the sensed data with external force sensors
%         : NOTE: this parser must have force_ext.csv file in the trace
%         : An external force over 4000uA must be in the beging and end
% 15/12/06: change to use apple 3d touch to correct only
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
    DEFAUGHT_TRACE_BASE_FOLDER = 'Traces/PressureCorrectByApple/DebugOutput_on_table_press_middle_ok/';
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
%PSE_DETECT_SAMPLE_RANGE = [595:605];
PSE_DETECT_SAMPLE_RANGE = [600:620];

dataStamps = conStamps;
%data = conNowSorted(1,:); % use max peak as indicator
data = sum(conNow(PSE_DETECT_SAMPLE_RANGE,:));
codeStamps = pseStamps;
codes = pseCodes;
assert(sum(codes==1) == sum(codes==2));
codeStart = codes(codes==1);
codeStartStamps = codeStamps(codes==1);
codeEnd = codes(codes==2);
codeEndStamps = codeStamps(codes==2);
codeResult = cell(length(codeStart), 1);

% variable to put concated datas

SampledDataChange = zeros(repeatToProcess,1);
SampledDataStamps = zeros(repeatToProcess,1);
SampledOffsets = zeros(repeatToProcess,1); % offset after the press
SampledIndxes = zeros(repeatToProcess,1); % just the number of touch
SampledIndex = 1;
SampledCnt = 0;

if DEBUG_SHOW == 1;
    figure; hold on;
    plot(data);
    xMaxToPlot = max(data);
end

for codeIdx = 1:length(codeStart),
    endOffset = 300; % samples
    startOffset = 300;
    dataIdxNow = dataStamps < codeEndStamps(codeIdx)+endOffset & dataStamps >  codeStartStamps(codeIdx)-startOffset;
    dataIdxStartNow = find(dataIdxNow>0);
    
    
    %fprintf('[WARN]: dataIdxStartNow is moved manually to get correct reference');
    %dataIdxStartNow = dataIdxStartNow;
    
    %DATA_REF_AHEAD_OFFSET = 10; % ad-hoc add a overset in case the ref data is not stable
    DATA_REF_AHEAD_OFFSET = 2; % ad-hoc add a overset in case the ref data is not stable
    
    if ~isempty(dataIdxStartNow),
        % estimate the pressure
        %ref = repmat(data(dataIdxStartNow(1) - DATA_REF_AHEAD_OFFSET), size(data(dataIdxNow)));
        ref = repmat(mean(data(dataIdxStartNow(1):-1:dataIdxStartNow(1)-DATA_REF_AHEAD_OFFSET)), size(data(dataIdxNow)));
        dataChangeNow = abs((data(dataIdxNow) - ref)./ref);
        %fprintf('[WARN]: use a absolute ref')
        %dataChangeNow = abs((data(dataIdxNow) - ref)./10^5);
        
        if DEBUG_SHOW == 1,
            plot([dataIdxStartNow(1), dataIdxStartNow(1)], [0, xMaxToPlot],'r-');
        end
        
        % put data in to the sampled vectors
        SampledSizeNow = length(dataChangeNow);
        SampledDataChange(SampledCnt+[1:SampledSizeNow]) = dataChangeNow;
        SampledDataStamps(SampledCnt+[1:SampledSizeNow]) = dataStamps(dataIdxNow);
        SampledOffsets(SampledCnt+[1:SampledSizeNow]) = 1:SampledSizeNow;
        SampledIndxes(SampledCnt+[1:SampledSizeNow]) = SampledIndex;
        SampledIndex = SampledIndex + 1;
        SampledCnt = SampledCnt + SampledSizeNow;
        
        
        % put data to code results
        codeResult{codeIdx}.data = data(dataIdxNow);
        codeResult{codeIdx}.dataStamps = dataStamps(dataIdxNow);
        codeResult{codeIdx}.dataIdxs = dataIdxNow;
        codeResult{codeIdx}.dataChange = dataChangeNow;
    end
end

% truncated sampled data
SampledDataChange = SampledDataChange(1:SampledCnt);
SampledDataStamps = SampledDataStamps(1:SampledCnt);
SampledOffsets = SampledOffsets(1:SampledCnt);

% sample the other data based on ultraphone sample points
SampledAppleForces = SampleDataByRefStamps(force, forceStamps, SampledDataStamps);



samplesValid = find(SampledAppleForces<0.99); % use only the samples when apple force < 0.99 to estiamted

% update dampled data to valid range
dataChangeValid = SampledDataChange(samplesValid);
appleForceValid = SampledAppleForces(samplesValid);

dataStamps = SampledDataStamps(samplesValid);
dataOffsets = SampledOffsets(samplesValid);
dataIndxes = SampledIndxes(samplesValid);

% build up regress model
samplesToRegress = (1:floor(length(dataChangeValid)*0.5)); % only use partial data to train
regerssOrders = [0, 0.5, 1];
dataChangeToRegress = PrepareDataToRegress(dataChangeValid(samplesToRegress), regerssOrders);
appleForceToRegress = appleForceValid(samplesToRegress);

cofDataChangeToAppleForce = regress(appleForceToRegress, dataChangeToRegress);

% plot correlation between data to regress and regerss answer
figure; hold on;
plot(dataChangeValid(samplesToRegress), appleForceToRegress,'o');
plot(dataChangeValid(samplesToRegress), dataChangeToRegress*cofDataChangeToAppleForce,'x');
xlabel('data change'); ylabel('apple force')


forceEstimated = PrepareDataToRegress(dataChangeValid, regerssOrders)*cofDataChangeToAppleForce;
%forceEstimated = dataChangeValid.*10;


% estimate errors for all data samples
corrAll = corr(forceEstimated, appleForceValid)
errorAll = abs((forceEstimated)-appleForceValid);
mseAll = sqrt(sum(errorAll.^2)./length(errorAll))

% estimate errors/corrs only for the middle samples
OFFSET_MID_START = 15; % samples after the touch began
OFFSET_MID_END = 40;
errorMiddle = errorAll(dataOffsets>=OFFSET_MID_START & dataOffsets<=OFFSET_MID_END);
mseMiddle = sqrt(sum(errorMiddle.^2)./length(errorMiddle))


% show error figures
figure;
subplot(3,1,1);  hold on;
plot(appleForceValid,'-','linewidth',2);
plot(forceEstimated,'-','linewidth',2);
subplot(3,1,2); hold on;
plot(dataChangeValid);
subplot(3,1,3); hold on;
dataInMiddleStartToPlot = find(dataOffsets==OFFSET_MID_START);
for i = 1:length(dataInMiddleStartToPlot),
    plot([dataInMiddleStartToPlot(i), dataInMiddleStartToPlot(i)], [0,1],'r');
end
dataInMiddleEndToPlot = find(dataOffsets==OFFSET_MID_END);
for i = 1:length(dataInMiddleEndToPlot),
    plot([dataInMiddleEndToPlot(i), dataInMiddleEndToPlot(i)], [0,1],'g');
end
plot(errorAll);






% get those data for each 
validCorrs = zeros(max(SampledIndxes), 1);
for i = 1:max(SampledIndxes),
    corrNow = corr(forceEstimated(dataIndxes==i), appleForceValid(dataIndxes==i));
    validCorrs(i) = corrNow;
    
    figure; hold on;
    title(sprintf('corr = %.2f', corrNow));
    plot(forceEstimated(dataIndxes==i));
    plot(appleForceValid(dataIndxes==i),'-o');
    legend('ext force', 'estimated force');
end




if DEBUG_SHOW,
    figure; hold on;
    plotConfig;
    APPLE_TO_G = 500;
    plot(SampledExtForces,'-','linewidth',LINE_WIDTH);
    plot(dataChangeToRegress*dataChangeToExtForce,'-','linewidth',LINE_WIDTH);
    %plot(SampledAppleForces.*APPLE_TO_G,'g--','linewidth',LINE_WIDTH);
    plot((SampledAppleForces.^2).*APPLE_TO_G,'g--','linewidth',LINE_WIDTH);
    legend('ext','ultraphone','apple');
    ylabel('Force (g)');
    xlabel('Sample Index');
    
    % normalzied , just for debug
    figure; hold on;
    APPLE_SCALE = 0.5;
    plot(SampledExtCurrents./max(SampledExtCurrents));
    plot(SampledAppleForces.*APPLE_SCALE./max(SampledAppleForces));
    plot(SampledDataChange./max(SampledDataChange),'g-o');
    %plot(sqrt(SampledDataChange./max(SampledDataChange)),'k-');
    legend('ext','apple','ultraphone','sqrt');
end


%--------------------------------------------------------------------------
% 9. visualize data loaded (optional)
%--------------------------------------------------------------------------
if DEBUG_SHOW,
    figure;
    TOTAL_FIGURE_CNT = 4;
    X_LIM = [conStamps(1), conStamps(end)];
    subplot(TOTAL_FIGURE_CNT,1,1); ylabel('data');
    plot(conStamps, data,'-o');
    xlim(X_LIM);
    
    subplot(TOTAL_FIGURE_CNT,1,2); ylabel('ext');
    plot(extStamps, extCurrents);
    xlim(X_LIM);
    %{
    subplot(TOTAL_FIGURE_CNT,1,3); ylabel('accMag diff'); hold on;
    plot(motionStamps, accMag);
    %plot(motionStamps(2:end), abs(accMag(2:end)-accMag(1:end-1)));
    xlim(X_LIM);
    subplot(TOTAL_FIGURE_CNT,1,4); ylabel('gyroMag diff'); hold on;
    plot(motionStamps, gyroMag);
    %plot(motionStamps(2:end), abs(gyroMag(2:end)-gyroMag(1:end-1)));
    xlim(X_LIM);
    %}
    subplot(TOTAL_FIGURE_CNT,1,3); ylabel('force'); hold on;
    plot(forceStamps, force);
    xlim(X_LIM);
    subplot(TOTAL_FIGURE_CNT,1,4); ylabel('data change');
    hold on;
    for codeIdx = 1:length(codeStart),
        if ~isempty(codeResult{codeIdx}),
            plot(codeResult{codeIdx}.dataStamps, codeResult{codeIdx}.dataChange, 'o');
        end
    end
    xlim(X_LIM);
end
