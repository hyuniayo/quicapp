%==========================================================================
% 2015/08/25: server to received data from phones
% 2015/10/15: update to a general server
% 2015/10/18: update saving loaded traces to file
% 2015/10/23: update sensor data reception
% 2015/10/26: update iOS compatibility
% 2015/11/03: update showing average peak value
% 2015/11/03: add response mode
% 2015/11/04: add response control
%==========================================================================
%cleanupObj = onCleanup(@cleanMeUp);
close all;
DEBUG_TO_PLOT_IDX = 2

%--------------------------------------------------------------------------
% 1. Audio related data
%--------------------------------------------------------------------------
DetectionSettingBase;
AUDIO_BUFF_MAX_SIZE = 500000; % maximize size of audio buffering (will be flush when data is processed)
SERVER_PORT = 50009


% actions for server to parse incoming data
ACTION_CONNECT  = 1;    % ACTION_CONNECT format: | ACTION_CONNECT |  
ACTION_DATA     = 2;    % ACTION_DATA format: | ACTION_SEND | data
ACTION_CLOSE    = -1;   % ACTION_CLOSE format: | ACTION_CLOSE |
ACTION_SET      = 3;    % ACTION_SET format: | ACTION_SET | type(int) | name(string) | var(byte[])
ACTION_INIT     = 4;    % ACTION_INIT format: | ACTION_INIT | 

% replys for server to reply // NOTE: ususaly set by phone app
REPLY_NONE      = 0;    % server will not reply
REPLY_PSE       = 1;    % server will reply sensed pressure resutls
REPLY_SSE       = 2;    % server will reply sensed squeeze results
REPLY_TVG       = 3;
REPLY_DLY       = 4;    % server will reply stamps to estimate delay

%--------------------------------------------------------------------------
% 2. Control parameters
%--------------------------------------------------------------------------

%++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
% = 0: use the data in workspace / 1: reload data  (0 for saving time)
% NOTE: those settings are going too be overwirte in future
%++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
NEED_TO_SEARCH_PILOT = 1; % disable it only for recording noise mode

if NEED_TO_SEARCH_PILOT,
    NEED_TO_REMOVE_PILOT = 1;
else
    NEED_TO_REMOVE_PILOT = 0;
end

%AUDIO_SAMPLE_TO_FIND_PILOT = 48000/2; % only search pilot in this window
%AUDIO_SAMPLE_TO_FIND_PILOT = 48000; % just for debugging
AUDIO_SAMPLE_TO_FIND_PILOT = 35000; % for iphone
%AUDIO_SAMPLE_TO_FIND_PILOT = 48000/1; % s5 setting



%++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
% = 1 : update the received byte array to a figure
%++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
SHOW_ANIMATION = 1;

NUM_RECORD_TO_UPDATE_ANIMATION = 4; % number of recorded in between animation updates
% FIG_PEAK is the figure showing continuous change of peak of conPulse
FIG_PEAK_X_LEN_TO_SHOW = 300; % 500 sweeps
FIG_PEAK_LINE_TO_SHOW = 1:3; % index of first few correlation to show

% FIG_FIX shows the convPulse value at fix places
FIG_FIX_X_LEN_TO_SHOW = FIG_PEAK_X_LEN_TO_SHOW; % 500 sweeps -> suggest set the same value as FIG_TVG_X_LEN_TO_SHOW
%FIG_FIX_OFFSET_TO_SHOW = 630+[-20, 0]; % convPulse offset related to peak
FIG_FIX_OFFSET_TO_SHOW = 630+[-20]; % convPulse offset related to peak
FIG_FIX_AVG_RANGE_TO_SHOW = [0, 20]; % wind to average data around the fix position (assign it to [0,0]) if you just want to show no-average data

% FIG_SHIFT shows the shift of top few peaks
FIG_SHIFT_X_LEN_TO_SHOW = FIG_PEAK_X_LEN_TO_SHOW; % 500 sweeps -> suggest set the same value as FIG_TVG_X_LEN_TO_SHOW
FIG_SHIFT_LINE_TO_SHOW = 1:3;
%FIG_SHIFT_COLOR_TO_SHOW = [];

% FIG_POWER shows the power of recorded audio at curtain level
FIG_POWER_X_LEN_TO_SHOW = FIG_PEAK_X_LEN_TO_SHOW; % 500 sweeps -> suggest set the same value as FIG_TVG_X_LEN_TO_SHOW
FIG_POWER_AGG_WIDTH_TO_SHOW = [20,40];
FIG_POWER_AGG_OFFSET = 620;


% FIG_SENSOR
FIG_SENSOR_X_LEN_TO_SHOW = FIG_PEAK_X_LEN_TO_SHOW; % 500 sweeps -> suggest set the same value as FIG_TVG_X_LEN_TO_SHOWF
FIG_SENSOR_DATA_GROUP_TO_SHOW = {[1,2,3], [4,5,6]};
FIG_SENSOR_TAG_TO_SHOW = {'tilt x','tilt y', 'tilt z'; 'gyro X', 'gyro Y', 'gyro Z'};


% FIG_CON is the instaneous changes of con right now
FIG_CON_X_LEN_TO_SHOW = 1500; % 500 sweeps
FIG_CON_LINE_TO_SHOW = 1:3; % index of first 
FIG_CON_COLOR_TO_SHOW = repmat(linspace(0,0.8,length(FIG_CON_LINE_TO_SHOW)), [length(FIG_CON_LINE_TO_SHOW),1]);

% FIG_TVG shows the conPulse after 
FIG_TVG_X_LEN_TO_SHOW = 600; % 500 sweeps
FIG_TVG_LINE_TO_SHOW = 1:3; % index of first 
FIG_TVG_COLOR_TO_SHOW = repmat(linspace(0,0.8,length(FIG_CON_LINE_TO_SHOW)), [length(FIG_CON_LINE_TO_SHOW),1]);

FFT_BIN_START = 100; %hz
FFT_BIN_END = 24000; %hz
FFT_BIN_CNT = 100;
% FIG_FFT shows the frequency response of received siganl
FIG_FFT_X_LEN_TO_SHOW = FFT_BIN_CNT;
FIG_FFT_LINE_TO_SHOW = 1:3;


%++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
% WRITE_TRACE_TO_FILE = 1 : write the received traces to files
%++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
WRITE_TRACE_TO_FILE = 0;

SENSOR_DATA_VALUE_CNT = 9; % only recorded tilt data
PULSE_DETECTION_MAX_RANGE_SAMPLES = 1500;

% create necessary trace folder
if WRITE_TRACE_TO_FILE,
    SERVER_TRACE_BASE_PATH = 'Traces/server/';
    SERVER_TRACE_FOLDER_PREFIX = 'ServerOutput_';
    SERVER_TRACE_FILE_PREFIX = 'record_';
    SERVER_TRACE_FILE_SUFFIX = '.txt';
    
    if ~exist(SERVER_TRACE_BASE_PATH,'dir'),
        mkdir(SERVER_TRACE_BASE_PATH);
    end

    for SERVER_TRACE_NAME_SUFFIX_IDX = 1:1000,
        pathNow = sprintf('%s%s%03d/',SERVER_TRACE_BASE_PATH, SERVER_TRACE_FOLDER_PREFIX,SERVER_TRACE_NAME_SUFFIX_IDX);
        if ~exist(pathNow, 'dir'),
            SERVER_TRACE_FOLDER_PATH = pathNow;
            mkdir(SERVER_TRACE_FOLDER_PATH);
            break;
        end
    end
end

%++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
% NEED_PRE_FILTER = 1 : put conPulse to filter before use it
%++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
NEED_PRE_FILTER = 1
PRE_FILTER_ORDER = 15;
PRE_FILTER_CUT_FREQ_LOW = 15000; % Hz

%--------------------------------------------------------------------------
% 3. Add socket library help class
%--------------------------------------------------------------------------
% add helper java class path if need
USE_HELPER_CLASS = 1; % always use the helper class
if USE_HELPER_CLASS,
    % Use of the helper class has been specified, but the class has
    % to be on the java class path to be useable.
    dynamicJavaClassPath = javaclasspath('-dynamic');

    % Add the helper class path if it isn't already there.
    if ~ismember(HELPER_CLASS_PATH,dynamicJavaClassPath)
        javaaddpath(HELPER_CLASS_PATH);

        % javaaddpath issues a warning rather than an error if it
        % fails, so can't use try/catch here. Test again to see if
        % helper path added.
        dynamicJavaClassPath = javaclasspath('-dynamic');

        if ~ismember(HELPER_CLASS_PATH,dynamicJavaClassPath)
            warning('jtcp:helperClassNotFound',[mfilename '.m--Unable to add Java helper class; reverting to byte-by-byte (slow) algorithm.']);
            USE_HELPER_CLASS = false;
        end % if
    end % if
end % if


%--------------------------------------------------------------------------
% 4. Wait internet connections
%--------------------------------------------------------------------------
action = zeros(1, 1, 'int8'); % init value
reply = REPLY_NONE; % default value is not replying anything
pseRefConBufRowIdx = 0;

% show network interface
[status,result]=system('ifconfig en0 inet')


% wait for the first connection
SERVER_ACCEPT_TIMEOUT = 20*1000; % minisecond
fprintf('Start waiting network connection, timeout = %d\n...', SERVER_ACCEPT_TIMEOUT);
jTcpObj = jtcp('accept',SERVER_PORT,'timeout',SERVER_ACCEPT_TIMEOUT,'serialize',false);


%--------------------------------------------------------------------------
% 5. Main loop to receive data
%--------------------------------------------------------------------------
dotCnt = 0;
for i = 1:100000,
    numBytesAvailable = jTcpObj.socketInputStream.available;
    fprintf('.'); % plot dot for user interface
    dotCnt = dotCnt + 1;
    if dotCnt >= 80, % switch dot to a new line
        fprintf('\n');
        dotCnt = 0;
    end
    
    if numBytesAvailable > 0,
        fprintf('\n');
        action = jTcpObj.inputStream.readByte

        %******************************************************************
        % ACTION_CONNECT: just connect the socket -> doing nothing
        %******************************************************************
        if action == ACTION_CONNECT,
            fprintf('Socket is connected and system setting is read from app\n');
            
        %******************************************************************
        % ACTION_INIT: initialize necessary commponentPars
        %  ***NOTE***: This action is triggered only when necessary
        %            : variables are setted by ACTION_SET
        %******************************************************************
        elseif action == ACTION_INIT,
            fprintf('Parsing vraibles is initilzed\n');
            % TODO: do animation and audio initization here
            assert(exist('traceChannelCnt','var') && exist('matlabSourceMatName','var'), '[ERROR]: parsing setting is not set when ACTION_INIT\n');
            
            assert(1==exist('deviceIdx','var'), '[ERROR]: new version of server ask deviceIdx as default\n');
            fprintf('[WARN]: some setting is overwirteen by devuce-specific setting\n');
            LoadDeviceSettingBasedOnDeviceIdx; % this load setting to workspace with assigned deviceIdx
            % overwirte global setting from device-specic settings
            AUDIO_SAMPLE_TO_FIND_PILOT = gds.AUDIO_SAMPLE_TO_FIND_PILOT
            SSE_DETECT_CH_IDX = gds.SSE_DETECT_CH_IDX; % use the second microphone to read
            SSE_DETECT_SAMPLE_RANGE = gds.SSE_DETECT_SAMPLE_RANGE; % sample range to get reference
            PSE_DETECT_CH_IDX = gds.PSE_DETECT_CH_IDX; % use the second microphone to read
            PSE_DETECT_SAMPLE_RANGE = gds.PSE_DETECT_SAMPLE_RANGE; % sample range to get reference
            
            % overwrite the FIG_FIX plot range for better visulization
            FIG_FIX_OFFSET_TO_SHOW(1) = PSE_DETECT_SAMPLE_RANGE(1);
            FIG_FIX_AVG_RANGE_TO_SHOW(2) = PSE_DETECT_SAMPLE_RANGE(end)-SSE_DETECT_SAMPLE_RANGE(1);
            
            % load source traces (and other audio source settings)
            load(strcat(AUDIO_SOURCE_FOLDER, matlabSourceMatName));
            
            % init necessary vairalbes
            audioBuf = zeros(AUDIO_BUFF_MAX_SIZE, traceChannelCnt);
            audioBufEnd = 0;
            
            conBuf = zeros(PULSE_DETECTION_MAX_RANGE_SAMPLES, REPEAT_CNT, traceChannelCnt);
            replyBuf = zeros(REPEAT_CNT, 1); % just for debug
            conFFTBuf = zeros(FFT_BIN_CNT, REPEAT_CNT, traceChannelCnt);
            conSortedBuf = zeros(PULSE_DETECTION_MAX_RANGE_SAMPLES, REPEAT_CNT, traceChannelCnt);
            conSortedIdxBuf = zeros(PULSE_DETECTION_MAX_RANGE_SAMPLES, REPEAT_CNT, traceChannelCnt);
            conBufRowEnd = 0;
            
            pseCnt = 0;
            pseIdxs = zeros(REPEAT_CNT,1)-1;
            pseCodes = zeros(REPEAT_CNT,1)-1;
            
            sensorDataBuf = zeros(SENSOR_DATA_VALUE_CNT,REPEAT_CNT*2);
            sensorDataTimeBuf = zeros(REPEAT_CNT*2, 1);
            sensorDataBufEnd = 0;
            
            % init filter if need
            if exist('NEED_PRE_FILTER','var') && NEED_PRE_FILTER == 1,
                [pfB, pfA] = butter(PRE_FILTER_ORDER, PRE_FILTER_CUT_FREQ_LOW/(FS/2), 'high');
            end
            
            % init animation variables (if necessary)
            animationPrevUpdateIdx = 0;
            if SHOW_ANIMATION == 1,
                % FIG_PEAK
                %{
                conPeakFig = figure;
                conPeakPlots = cell(traceChannelCnt, 1);
                for chIdx = 1:traceChannelCnt,
                    subplot(traceChannelCnt, 1, chIdx); 
                    conPeakPlots{chIdx} = plot(conSortedBuf(FIG_PEAK_LINE_TO_SHOW, 1:FIG_PEAK_X_LEN_TO_SHOW, chIdx).');
                    ylabel('con peak');
                    legend('1','2','3','location','southwest');
                end
                %}
                
                % FIG_SHIFT
                %{
                conShiftFig = figure;
                conShiftPlots = cell(traceChannelCnt, 1);
                for chIdx = 1:traceChannelCnt,
                    subplot(traceChannelCnt, 1, chIdx); 
                    conShiftPlots{chIdx} = plot(conSortedBuf(FIG_SHIFT_LINE_TO_SHOW, 1:FIG_SHIFT_X_LEN_TO_SHOW, chIdx).');
                    ylabel('con shift');
                    legend(cellstr(num2str(FIG_SHIFT_LINE_TO_SHOW'))','location','southwest');
                end
                %}
                
                % FIG_FIX
                conFixFig = figure; set(conFixFig, 'Renderer', 'painters');
                conFixPlots = cell(traceChannelCnt, 1);
                conFixReplyStartPlots = cell(traceChannelCnt, 1);
                
                
                for chIdx = 1:traceChannelCnt,
                    subplot(traceChannelCnt, 1, chIdx); 
                    hold on;
                    conFixPlots{chIdx} = plot(conSortedBuf(FIG_FIX_OFFSET_TO_SHOW, 1:FIG_FIX_X_LEN_TO_SHOW, chIdx).','linewidth',3);
                    conFixReplyStartPlots{chIdx} = plot([0,0], [0,1], 'r--', 'linewidth', 3);
                    hold off;
                    ylabel('con fix');
                    legend(cellstr(num2str(FIG_FIX_OFFSET_TO_SHOW'))','location','southwest');
                end
                
                
                %{
                % uncomment it if you want to plot only one line for debug
                for chIdx = 1:traceChannelCnt,
                    %subplot(1, 1, chIdx); 
                    if(chIdx == DEBUG_TO_PLOT_IDX),
                        conFixPlots{chIdx} = plot(conSortedBuf(FIG_FIX_OFFSET_TO_SHOW, 1:FIG_FIX_X_LEN_TO_SHOW, chIdx).','r-','linewidth',5);
                        ylabel('con fix');
                        %legend(cellstr(num2str(FIG_FIX_OFFSET_TO_SHOW'))','location','southwest');
                    end
                end
                
                
                f =gcf()
                ax = findobj(f,'Type','axes');
                for k = 1:length(ax)
                    ax(k).FontSmoothing = 'off';
                end
                set(f,'DefaultFigureGraphicsSmoothing','off')
                %}
                
                % FIG_POWER
                %{
                conPowerFig = figure;
                conPowerPlots = cell(traceChannelCnt, 1);
                for chIdx = 1:traceChannelCnt,
                    subplot(traceChannelCnt, 1, chIdx); 
                    conPowerPlots{chIdx} = plot(conSortedBuf(FIG_POWER_AGG_WIDTH_TO_SHOW, 1:FIG_POWER_X_LEN_TO_SHOW, chIdx).');
                    ylabel('con power');
                    legend(cellstr(num2str(FIG_POWER_AGG_WIDTH_TO_SHOW'))','location','southwest');
                end
                %}
                
                % FIG_SENSOR
                %{
                sensorDataFig = figure;
                sensorDataPlots = cell(length(FIG_SENSOR_DATA_GROUP_TO_SHOW), 1);
                for plotIdx = 1:length(sensorDataPlots),
                    dataToShow = FIG_SENSOR_DATA_GROUP_TO_SHOW{plotIdx};
                    tagToShow = FIG_SENSOR_TAG_TO_SHOW(1,:);
                    subplot(length(sensorDataPlots), 1, plotIdx);
                    sensorDataPlots{plotIdx} = plot(sensorDataBuf(dataToShow, 1:FIG_SENSOR_X_LEN_TO_SHOW).');
                    ylabel('sensor');
                    legend(tagToShow,'location','southwest');
                end
                %}
                
                
                % FIG_CON
                %{
                conFig = figure;
                conPlots = cell(traceChannelCnt, 1);
                for chIdx = 1:traceChannelCnt,
                    subplot(traceChannelCnt, 1, chIdx); ylabel('con');
                    % update color
                    co = get(gca,'ColorOrder'); % Initial
                    set(gca, 'ColorOrder', [0.8, 0.8, 0.8; 0.5,0.5,0.5; 1,0,0], 'NextPlot', 'replacechildren'); % Change to new colors.
                    co = get(gca,'ColorOrder'); % Verify it changed
                
                    conPlots{chIdx} = plot(conBuf(1:FIG_CON_X_LEN_TO_SHOW,FIG_CON_LINE_TO_SHOW,chIdx));
                end
                %}
                
                % FIG_TVG
                %{
                tvgFig = figure;
                tvgPlots = cell(traceChannelCnt, 1);
                for chIdx = 1:traceChannelCnt,
                    subplot(traceChannelCnt, 1, chIdx); ylabel('tvg');
                    % update color
                    co = get(gca,'ColorOrder'); % Initial
                    set(gca, 'ColorOrder', [0.8, 0.8, 0.8; 0.5,0.5,0.5; 1,0,0], 'NextPlot', 'replacechildren'); % Change to new colors.
                    co = get(gca,'ColorOrder'); % Verify it changed
                    tvgPlots{chIdx} = plot(conBuf(1:FIG_TVG_X_LEN_TO_SHOW,FIG_TVG_LINE_TO_SHOW,chIdx));
                end
                %}
                
                % FIG_FFT
                %{
                binRanges = linspace(FFT_BIN_START, FFT_BIN_END, FFT_BIN_CNT);
                fftFig = figure;
                fftPlots = cell(traceChannelCnt, 1);
                for chIdx = 1:traceChannelCnt,
                    subplot(traceChannelCnt, 1, chIdx); ylabel('fft');
                    % update color
                    co = get(gca,'ColorOrder'); % Initial
                    set(gca, 'ColorOrder', [0.8, 0.8, 0.8; 0.5,0.5,0.5; 1,0,0], 'NextPlot', 'replacechildren'); % Change to new colors.
                    co = get(gca,'ColorOrder'); % Verify it changed
                    fftPlots{chIdx} = plot(repmat(binRanges',[1,length(FIG_FFT_LINE_TO_SHOW)]), conFFTBuf(:,FIG_FFT_LINE_TO_SHOW,chIdx));
                end
                %}
                
            end
            
            % init trace saving
            if WRITE_TRACE_TO_FILE,
                serverTraceFileIdx = 1;
                settingFile = fopen(strcat(SERVER_TRACE_FOLDER_PATH, 'matlab.txt'),'w');
                fprintf(settingFile, '%s\n%d\n%f\n',matlabSourceMatName, traceChannelCnt, traceVol);
                fclose(settingFile);
            end
            
            % build necessary process variables
            if (exist('HAMMING_IS_ENABLED','var') && HAMMING_IS_ENABLED == 1) || (exist('CUSTOMHAMMING_IS_ENABLED','var') && CUSTOMHAMMING_IS_ENABLED == 1),
                %pulseUsed = pulseNoHamming;
    
                fprintf('[WARN]: pulseUsed is truncated by middle section\n');
                pulseUsed = pulseNoHamming(300:end-300);
            else
                pulseUsed = pulse;
            end
            
            % *** just for debug ***
            %jtcp('write',jTcpObj,int8('Hello, server'));
            %jtcp('write',jTcpObj,typecast(55.66, 'int8'));
            
        %******************************************************************
        % ACTION_DATA: received audio data 
        %******************************************************************
        elseif action == ACTION_DATA,
            %fprintf('Going to read packet data\n');
            dataBytes = LibReadFullData(jTcpObj);
            
            % save dataBytes to file if necessary
            if WRITE_TRACE_TO_FILE,
                traceFile = fopen(sprintf('%s%s%03d%s',SERVER_TRACE_FOLDER_PATH, SERVER_TRACE_FILE_PREFIX, serverTraceFileIdx,SERVER_TRACE_FILE_SUFFIX),'w');
                fwrite(traceFile,dataBytes,'int8');
                fclose(traceFile);
                serverTraceFileIdx = serverTraceFileIdx+1;
            end
            
            % a. parse the recieved payload as audio
            dataTemp = double(typecast(dataBytes,'int16'));
            if traceChannelCnt == 1, % single-chanell ->ex: iphone
                audioNow = dataTemp';
            else % stereo-recroding
                audioNow = [dataTemp(1:2:end).', dataTemp(2:2:end).'];
            end
            
            % b. update auido to global buffer
            audioBuf(audioBufEnd+1:audioBufEnd+size(audioNow,1),:) = audioNow;
            audioBufEnd = audioBufEnd + size(audioNow,1);
            
            % c. search pilot in the first packet
            if NEED_TO_SEARCH_PILOT && audioBufEnd > AUDIO_SAMPLE_TO_FIND_PILOT,
                [pilotEndOffset] = LibFindPilot(audioBuf(1:AUDIO_SAMPLE_TO_FIND_PILOT,:), pilot, gds.PILOT_SEARCH_CH_IDXS);
                assert(pilotEndOffset>0, '[ERROR]: unable to find pilot, (AUDIO_SAMPLE_TO_FIND_PILOT is too short?)');
                pilotLenToRemove = pilotEndOffset + PILOT_END_OFFSET;
                NEED_TO_SEARCH_PILOT = 0;
            end
            
            % d. remove pilot if receive enough audio data
            if NEED_TO_SEARCH_PILOT == 0 && NEED_TO_REMOVE_PILOT && audioBufEnd > pilotLenToRemove,
                newAudioBufEnd = audioBufEnd - pilotLenToRemove;
                audioBuf(1:newAudioBufEnd, :) = audioBuf(pilotLenToRemove+1:audioBufEnd, :);
                audioBufEnd = newAudioBufEnd;
                NEED_TO_REMOVE_PILOT = 0;
            end
            
            % e. start cut the audio data for processing
            if NEED_TO_SEARCH_PILOT == 0 && NEED_TO_REMOVE_PILOT == 0 && audioBufEnd > SINGLE_REPEAT_LEN,
                repeatToProcess = floor(audioBufEnd/SINGLE_REPEAT_LEN);
                lenToProcess = repeatToProcess*SINGLE_REPEAT_LEN;
                newAudioBufEnd = audioBufEnd - lenToProcess;
                audioToProcess = audioBuf(1:lenToProcess,:);
                audioBuf(1:newAudioBufEnd,:) = audioBuf(lenToProcess+1:audioBufEnd,:);
                audioBufEnd = newAudioBufEnd;
                
                % do audio process
                audioToProcess = reshape(audioToProcess, [SINGLE_REPEAT_LEN, repeatToProcess, traceChannelCnt]);
                
                if NEED_PRE_FILTER,
                    audioToProcess = filter(pfB, pfA, audioToProcess);
                end
                
                conNow = AudioProcessFindPulseMax(audioToProcess, pulseUsed);
                conNow = conNow(1:PULSE_DETECTION_MAX_RANGE_SAMPLES,:,:); % only take the begining sections
                [conNowSorted, conNowSortedIdx] = sort(conNow, 1, 'descend');
                conBuf(:, conBufRowEnd+1:conBufRowEnd+repeatToProcess, :) = conNow;
                
                % uncomment it if you really want the sorted value
                %{
                conSortedBuf(:, conBufRowEnd+1:conBufRowEnd+repeatToProcess, :) = conNowSorted;
                conSortedIdxBuf(:, conBufRowEnd+1:conBufRowEnd+repeatToProcess, :) = conNowSortedIdx;
                %}
                
                % umcomment it if you really want fft
                %{
                [~, freqs, fftBins ] = LibGetFFTBins( audioToProcess, FS, FFT_BIN_START, FFT_BIN_END, FFT_BIN_CNT);
                conFFTBuf(:, conBufRowEnd+1:conBufRowEnd+repeatToProcess, :) = fftBins;
                %}
                
                conBufRowEnd = conBufRowEnd+repeatToProcess;
            end
            
            % *** just to test network speed ***
            %jtcp('write',jTcpObj,typecast(conBufRowEnd, 'int8'));
            % *** end for test network spedd ***
            
            % f. update figure if need
            if SHOW_ANIMATION == 1 && NEED_TO_SEARCH_PILOT == 0 && NEED_TO_REMOVE_PILOT == 0  && (conBufRowEnd - animationPrevUpdateIdx)>=NUM_RECORD_TO_UPDATE_ANIMATION ,
                animationPrevUpdateIdx = conBufRowEnd;
                
                % update con peak figure
                if exist('conPeakFig','var') && ishandle(conPeakFig),
                    for chIdx = 1:traceChannelCnt,
                        for dataIdx = FIG_PEAK_LINE_TO_SHOW
                            if conBufRowEnd <= FIG_PEAK_X_LEN_TO_SHOW,
                                yData = conSortedBuf(dataIdx, 1:FIG_PEAK_X_LEN_TO_SHOW, chIdx);
                            else
                                yData = conSortedBuf(dataIdx, conBufRowEnd-FIG_PEAK_X_LEN_TO_SHOW+1:conBufRowEnd, chIdx);
                            end
                            yData(1,1) = 0; % make sure the zero is included in figure
                            set(conPeakPlots{chIdx}(dataIdx), 'yData', yData);
                        end
                    end
                end
                
                % update con shift figure
                if exist('conShiftFig','var') && ishandle(conShiftFig),
                    for chIdx = 1:traceChannelCnt,
                        for dataIdx = FIG_SHIFT_LINE_TO_SHOW
                            if conBufRowEnd <= FIG_SHIFT_X_LEN_TO_SHOW,
                                yData = conSortedIdxBuf(dataIdx, 1:FIG_SHIFT_X_LEN_TO_SHOW, chIdx);
                            else
                                yData = conSortedIdxBuf(dataIdx, conBufRowEnd-FIG_SHIFT_X_LEN_TO_SHOW+1:conBufRowEnd, chIdx);
                            end
                            yData(1,1) = 550; % make sure the zero is included in figure
                            set(conShiftPlots{chIdx}(dataIdx), 'yData', yData);
                        end
                    end
                end
                
                % update con fix figure
                
                if exist('conFixFig','var') && ishandle(conFixFig),
                    for chIdx = 1:traceChannelCnt,
                        %if(chIdx == DEBUG_TO_PLOT_IDX),
                            for dataIdx = 1:length(FIG_FIX_OFFSET_TO_SHOW),
                                %dataRange = FIG_FIX_OFFSET_TO_SHOW(dataIdx)+FIG_FIX_AVG_RANGE_TO_SHOW(1):FIG_FIX_OFFSET_TO_SHOW(dataIdx)+FIG_FIX_AVG_RANGE_TO_SHOW(2);
                                dataRange = PSE_DETECT_SAMPLE_RANGE;
                                if conBufRowEnd <= FIG_FIX_X_LEN_TO_SHOW,
                                    yData = sum(conBuf(dataRange, 1:FIG_FIX_X_LEN_TO_SHOW, chIdx),1);
                                else
                                    yData = sum(conBuf(dataRange, conBufRowEnd-FIG_FIX_X_LEN_TO_SHOW+1:conBufRowEnd, chIdx),1);
                                end
                                yData(1,1) = 0; % make sure the zero is included in figure
                                set(conFixPlots{chIdx}(dataIdx), 'yData', yData);
                                if exist('pseRefConBufRowIdx','var') && pseRefConBufRowIdx - (conBufRowEnd-FIG_FIX_X_LEN_TO_SHOW+1) > 0,
                                    pseStartToShowX = pseRefConBufRowIdx - (conBufRowEnd-FIG_FIX_X_LEN_TO_SHOW+1);
                                    set(conFixReplyStartPlots{chIdx}, 'xData', [pseStartToShowX, pseStartToShowX], 'yData', [min(yData), max(yData)]);
                                end
                            end
                        %end
                    end
                end
                
                % update FIG_POWER
                if exist('conPowerFig','var') && ishandle(conPowerFig),
                    for chIdx = 1:traceChannelCnt,
                        for dataIdx = 1:length(FIG_POWER_AGG_WIDTH_TO_SHOW),
                            aggWidth = FIG_POWER_AGG_WIDTH_TO_SHOW(dataIdx);
                            
                            if conBufRowEnd <= FIG_POWER_X_LEN_TO_SHOW,
                                dataToAgg = conSortedBuf(1:aggWidth, 1:FIG_POWER_X_LEN_TO_SHOW, chIdx);
                            else
                                dataToAgg = conSortedBuf(1:aggWidth, conBufRowEnd-FIG_POWER_X_LEN_TO_SHOW+1:conBufRowEnd, chIdx);
                            end
                            
                            yData = sum(dataToAgg.^2)./aggWidth;
                            
                            yData(1,1) = 0; % make sure the zero is included in figure
                            set(conPowerPlots{chIdx}(dataIdx), 'yData', yData);
                        end
                    end
                end
                
                % update FIG_SENSOR
                if exist('sensorDataFig','var') && ishandle(sensorDataFig),
                    for plotIdx = 1:length(FIG_SENSOR_DATA_GROUP_TO_SHOW),
                        dataToShow = FIG_SENSOR_DATA_GROUP_TO_SHOW{plotIdx};
                        for dataIdx = 1:length(dataToShow),
                            if sensorDataBufEnd <= FIG_SENSOR_X_LEN_TO_SHOW,
                                yData = sensorDataBuf(dataToShow(dataIdx), 1:FIG_SENSOR_X_LEN_TO_SHOW);
                            else
                                yData = sensorDataBuf(dataToShow(dataIdx), sensorDataBufEnd-FIG_SENSOR_X_LEN_TO_SHOW+1:sensorDataBufEnd);
                            end
                            set(sensorDataPlots{plotIdx}(dataIdx),'yData', yData);
                        end
                    end
                end
                
                
                % update con figure
                if exist('conFig','var') && ishandle(conFig),
                    for chIdx = 1:traceChannelCnt,
                        for lineIdx = FIG_CON_LINE_TO_SHOW
                            dataIdx = conBufRowEnd - (length(FIG_CON_LINE_TO_SHOW) - lineIdx); % plot latest data first
                            if dataIdx >= 1, % valid dataIdx
                                yData = conBuf(1:FIG_CON_X_LEN_TO_SHOW, dataIdx, chIdx);
                                set(conPlots{chIdx}(lineIdx), 'yData', yData);
                            end                        
                        end
                    end
                end
                
                % update tvg figure
                if exist('tvgFig','var') && ishandle(tvgFig),
                    for chIdx = 1:traceChannelCnt,
                        for lineIdx = FIG_CON_LINE_TO_SHOW
                            dataIdx = conBufRowEnd - (length(FIG_TVG_LINE_TO_SHOW) - lineIdx); % plot latest data first
                            if dataIdx >= 1, % valid dataIdx
                                yDataOffset = 600; % make the data start from the conPeak
                                yData = conBuf(1+yDataOffset:FIG_TVG_X_LEN_TO_SHOW+yDataOffset, dataIdx, chIdx);
                                yData = LibTimeVaryingGainCorrect(yData);
                                yData = smooth(yData, 20);
                                set(tvgPlots{chIdx}(lineIdx), 'yData', yData);
                            end                        
                        end
                    end
                end
                
                % update FIG_FFT
                if exist('fftFig','var') && ishandle(fftFig),
                    for chIdx = 1:traceChannelCnt,
                        for lineIdx = FIG_FFT_LINE_TO_SHOW
                            dataIdx = conBufRowEnd - (length(FIG_FFT_LINE_TO_SHOW) - lineIdx); % plot latest data first
                            if dataIdx >= 1, % valid dataIdx
                                yData = conFFTBuf(:, dataIdx, chIdx);
                                set(fftPlots{chIdx}(lineIdx), 'yData', yData);
                            end                        
                        end
                    end
                end
            end
            
            % g. reply to remove if need
            if reply > REPLY_NONE,
                if reply == REPLY_PSE, % return estimated pressure
                    %pseRange = [600:620];
                    %pseRange = PSE_DETECT_SAMPLE_RANGE;
                    data = sum(conBuf(PSE_DETECT_SAMPLE_RANGE, conBufRowEnd, PSE_DETECT_CH_IDX),1);
                    ref = sum(conBuf(PSE_DETECT_SAMPLE_RANGE, pseRefConBufRowIdx, PSE_DETECT_CH_IDX), 1);
                    
                    %result = abs(data-ref)/ref;
                    result = abs(data-ref)/(log10(ref)*10^6);
                    jtcp('write',jTcpObj,typecast(result, 'int8'));
                    
                    
                elseif reply == REPLY_SSE,
                    sseRange = gds.SSE_DETECT_SAMPLE_RANGE;
                    SQUEEZE_LEN_TO_CHECK = gds.SQUEEZE_LEN_TO_CHECK;
                    
                    % check once only
                    if conBufRowEnd - sseRefConBufRowIdx > SQUEEZE_LEN_TO_CHECK,
                        %data = sum(conBuf(sseRange,sseRefConBufRowIdx:pseRefConBufRowIdx+SQUEEZE_LEN_TO_CHECK),1);
                        data = sum(conBuf(sseRange,conBufRowEnd-SQUEEZE_LEN_TO_CHECK+1:conBufRowEnd, SSE_DETECT_CH_IDX), 1);
                        [~, peaks, check] = SqueezeDetect(data, gds);
                        replyBuf(conBufRowEnd) = check;
                        jtcp('write',jTcpObj,typecast(check, 'int8'));
                        
                        % *** comment it will continuously sense the squeeze ***
                        % reply = REPLY_NONE; 
                    end
                elseif reply == REPLY_DLY,
                    stampFromAudioStart = pilotLenToRemove + conBufRowEnd*SINGLE_REPEAT_LEN;
                    jtcp('write',jTcpObj,typecast(stampFromAudioStart, 'int8'));
                else
                    fprintf('[ERROR]: undefined reply mode = %d\n', reply);
                end
            end
        %******************************************************************
        % ACTION_SET: set matlab variable based on code
        %******************************************************************
        elseif action == ACTION_SET,
            [name, value, evalString] = LibReadSetAction(jTcpObj);
            evalString;
            eval(evalString);
            
            % receive sensor data -> fill into sensor data buf
            if strcmp(name, 'sensorDataNow') && conBufRowEnd>0,
                sensorDataBufEnd = sensorDataBufEnd+1;
                sensorDataBuf(:,sensorDataBufEnd) = sensorDataNow(1:SENSOR_DATA_VALUE_CNT);
                sensorDataTimeBuf(sensorDataBufEnd) = conBufRowEnd;
            end
            
            if strcmp(name, 'pse'),
                % pse application tag is set
                if pse == 1, % enable mode
                   pseRefConBufRowIdx = conBufRowEnd;
                   
                   reply = REPLY_PSE;
                elseif pse == 2, % diable mode
                   reply = REPLY_NONE;
                end
                
                pseCnt = pseCnt+1; % just for debug -> get quick reference
                pseIdxs(pseCnt) = conBufRowEnd;
                pseCodes(pseCnt) = pse;
            end
            
            if strcmp(name, 'sse'),
                % sse application tag is set
                if sse == 1, % enable mode
                   sseRefConBufRowIdx = conBufRowEnd;
                   reply = REPLY_SSE;
                elseif sse == 2, % diable mode
                   reply = REPLY_NONE;
                end
            end
            
            if strcmp(name, 'dly'),
                % dly application tag is set
                if dly == 1, % enable mode
                   reply = REPLY_DLY;
                elseif dly == 2, % diable mode
                   reply = REPLY_NONE;
                end
            end
            
            
        %******************************************************************
        % ACTION_CLOSE: read the end of sockets -> close loop
        %******************************************************************
        elseif action == ACTION_CLOSE,
            fprintf('[WARN]: socket is closed remotely\n');
            break;
        else
            fprintf('[ERROR]: undefined action=%d\n',action);
            break;
        end
    end
    
    pause(0.001); % real-time mode
    %pause(0.01); % no figure mode
    %pause(1); % debug mode
end

jtcp('close',jTcpObj);


%==========================================================================
% Visualize final results
%==========================================================================
forceRef = squeeze(sum(conBuf(PSE_DETECT_SAMPLE_RANGE, 1:conBufRowEnd, :),1)); % force reference
figure; title('force referece');
plot(forceRef);
legend('ch1', 'ch2');
ylabel('force reference'); xlabel('sample index (20Hz)');

% For pse debug
%{
for chIdx = 1:traceChannelCnt,
    
    data = sum(conBuf(PSE_DETECT_SAMPLE_RANGE, 1:conBufRowEnd, chIdx),1); % force reference
    
    pseStartIdxs = pseIdxs(pseCodes==1);
    pseEndIdxs = pseIdxs(pseCodes==2);
    assert(length(pseStartIdxs)==length(pseEndIdxs), '[ERROR] pse code length not matches\n');
    
    pseDurations = pseEndIdxs - pseStartIdxs + 1;
    
    pseTouchCnt = length(pseStartIdxs);
    
    figure; hold on;
    plot(data); title(sprintf('ch %d', chIdx));
    for codeIdx = 1:pseTouchCnt,
        theMax = max(data);
        plot([pseStartIdxs(codeIdx), pseStartIdxs(codeIdx)], [0, theMax],'r--');
        plot([pseEndIdxs(codeIdx), pseEndIdxs(codeIdx)], [0, theMax],'g--');
    end
    
    figure;
    hold on; title(sprintf('ch %d', chIdx));
    plotDataIdx = 1;
    for codeIdx = 1:pseTouchCnt,
        ref = data(pseStartIdxs(codeIdx));
        dataNow = data(pseStartIdxs(codeIdx):pseEndIdxs(codeIdx));
        
        dataToPlot = abs(dataNow-ref)/ref;
        
        plot(plotDataIdx:plotDataIdx+length(dataNow)-1, dataToPlot);
        plotDataIdx = plotDataIdx+length(dataNow);
    end
end
%}
