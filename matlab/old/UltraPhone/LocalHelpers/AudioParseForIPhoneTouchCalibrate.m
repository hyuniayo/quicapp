function [SampledDataChange, SampledCalibrateTargetValues, SampledAppleForces, SampledExtForces] = AudioParseForIPhoneTouchCalibrate( TRACE_BASE_FOLDER, DEBUG_SHOW)
%==========================================================================
% 16/03/25: update to calibrate with latest
% 17/05/06: update the method to clibrate by external forces
%==========================================================================
close all;

ParserConfig;
%GeneralSetting;

if ~exist('DEBUG_SHOW','var'),
    DEBUG_SHOW = 1;
end

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
    DEFAUGHT_TRACE_BASE_FOLDER = 'Traces/TouchClibrate/iphone6sbump_woodentable_with_arduino/DebugOutput_tablewood_eraser1_25_368_1/';
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
[pseStamps, pseCodes, pseArg0s, pseArg1s] = LibLoadLog(strcat(TRACE_BASE_FOLDER,'pse.dat'));

% add dummy pseCode end
if pseCodes(end) == 1,
    fprintf('[WARN]: pseCode ends with 1, add a dummy 0 (end)\n');
    pseCodes = [pseCodes; 2];
    pseStamps = [pseStamps; pseStamps(end)];
end

% remove successive "2"
for i = length(pseCodes):-1:1
    needToRemoveRedundent = -1;
    if i==1,
        if pseCodes(i) == 2
            needToRemoveRedundent = 1;
        end
    else
        if pseCodes(i) == 2 && pseCodes(i-1) == 2 ,
            needToRemoveRedundent = 1;
        end
    end
        
    if needToRemoveRedundent==1,
        pseStamps(i) = [];
        pseCodes(i) = [];
        pseArg0s(i) = [];
        pseArg1s(i) = [];
    end
end
[clbStamps, clbCodes, ~, ~] = LibLoadLog(strcat(TRACE_BASE_FOLDER,'clb.dat'));

%--------------------------------------------------------------------------
% 7. Load external force data and calibrate it
% NOTE: we now use the 
%--------------------------------------------------------------------------
EXT_FORCE_FILE_PATH = strcat(TRACE_BASE_FOLDER, 'force_vol.csv');
if exist(EXT_FORCE_FILE_PATH, 'file'),
    EXTERNAL_SENSOR_DATA_EXISTED = 1;
    
    %dataExt = csvread(EXT_FORCE_FILE_PATH);
    %{
    fid  = fopen(EXT_FORCE_FILE_PATH);
    dataExt = textscan(fid,'%f%f','Delimiter',',','HeaderLines',2); % ignore the header
    fclose(fid);
    extCurrents = dataExt{2}; % uA
    extStamps = dataExt{1}*FS;
    %}
    %extForces = CurrentToExForce(extCurrents*10^-6);
    dataExt = csvread(EXT_FORCE_FILE_PATH);
    extValues = dataExt(:,2);
    dts = dataExt(:,1); % in milliseconds
    extStamps = floor((cumsum(dts)./1000).*FS);
    

    [extStamps, extCalibratedStartStamp, extCalibratedEndStamp] = CalibrateExtForceByTouchEvent(extStamps, extValues, pseStamps, pseCodes);
    
    % remove the unnecessary code triggers
    pseCodes = pseCodes(pseStamps>extCalibratedStartStamp & pseStamps < extCalibratedEndStamp);
    pseStamps = pseStamps(pseStamps>extCalibratedStartStamp & pseStamps < extCalibratedEndStamp);

    % remove the peak only used for reference of external sensors
    clbStamps = clbStamps(3:end-2);
    clbCodes = clbCodes(3:end-2);
end




assert(length(pseStamps)==length(clbStamps), '[ERROR]: umatched pse and clb traces\n');
assert(all(clbCodes>=0), '[ERROR]: reference clbCodes are not remvoed sucessfully\n');


%--------------------------------------------------------------------------
% 7. make some app-based processing
%--------------------------------------------------------------------------
%PSE_DETECT_SAMPLE_RANGE = [560:590];
PSE_DETECT_SAMPLE_RANGE = [590:610];
%PSE_DETECT_SAMPLE_RANGE = [600:620];

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
clbCodeStart = clbCodes(clbCodes>0);
clbCodeStartStamps = clbStamps(clbCodes>0);
clbCodeEndStamps = clbStamps(clbCodes==0);
assert(length(clbCodeStartStamps)==length(clbCodeEndStamps));
% variable to put concated datas

SampledDataChange = zeros(repeatToProcess,1);
SampledDataStamps = zeros(repeatToProcess,1);
SampledOffsets = zeros(repeatToProcess,1); % offset after the press
SampledIndxes = zeros(repeatToProcess,1); % just the number of touch
SampledIndex = 1;
SampledCnt = 0;
SampledCalibrateTargetValues = zeros(repeatToProcess,1); % clibrate target values

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
        %dataChangeNow = abs((data(dataIdxNow) - ref)); fprintf('[WARN]: no divide in the r(t)\n');
        
        
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
        
        targetValues = zeros(length(dataStamps(dataIdxNow)), 1);
        targetValues(dataStamps(dataIdxNow) > clbCodeStartStamps(codeIdx) & dataStamps(dataIdxNow) < clbCodeEndStamps(codeIdx)) = clbCodeStart(codeIdx);
        SampledCalibrateTargetValues(SampledCnt+[1:SampledSizeNow]) = targetValues;
        
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
SampledCalibrateTargetValues = SampledCalibrateTargetValues(1:SampledCnt);

% sample the other data based on ultraphone sample points
SampledAppleForces = SampleDataByRefStamps(force, forceStamps, SampledDataStamps);
if exist('EXTERNAL_SENSOR_DATA_EXISTED','var') && EXTERNAL_SENSOR_DATA_EXISTED == 1,
    SampledExtForces = SampleDataByRefStamps(extValues, extStamps, SampledDataStamps);
else
    SampledExtForces = [];
end


if DEBUG_SHOW,
    debugFigureCnt = 3;
    if exist('EXTERNAL_SENSOR_DATA_EXISTED','var') && EXTERNAL_SENSOR_DATA_EXISTED == 1,
        debugFigureCnt = 4;
    end
    
    
    figure;
    subplot(debugFigureCnt,1,1);
    plot(SampledDataChange); legend('data');
    subplot(debugFigureCnt,1,2);
    plot(SampledAppleForces); legend('apple');
    subplot(debugFigureCnt,1,3);
    plot(SampledCalibrateTargetValues); legend('target');
    if exist('EXTERNAL_SENSOR_DATA_EXISTED','var') && EXTERNAL_SENSOR_DATA_EXISTED == 1,
        subplot(debugFigureCnt,1,4);
        plot(SampledExtForces);
    end
end



end