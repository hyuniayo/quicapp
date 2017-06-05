function [ traceVec ] = LibLoadAudio( request )
% 2015/09/29: make a general version loading auido inside matlab
% 2015/10/18: update determine TRACE_TRACK_SIZE based on file size

%TODO: read channel based on channel parameters


if strcmp(request.setting, 'SERVER_TRACE'), % don't need to load trace but only use input as traces
    traceVec = request.payload;
elseif strcmp(request.setting, 'WAV_TRACE'),
    [traceVec, FS] = wavread(request.TRACE_BASE_FOLDER);
elseif strcmp(request.setting, 'BINARY_TRACE'),
    %TRACE_TRACK_SIZE = 40960; %TODO: include this variable to matlab files
    [TRACE_READ_NAMES, TRACE_READ_IDX_CNT] = LibGetTraceNames(request.TRACE_BASE_FOLDER);
    
    if TRACE_READ_IDX_CNT == 0,
        fprintf('[WARN]: there is no trace to load');
    end
    
    % assume all the file has the same size
    tempCheck = dir(strcat(request.TRACE_BASE_FOLDER,TRACE_READ_NAMES{1}));
    TRACE_TRACK_SIZE = tempCheck.bytes/(2); % 16-bit
    
    traceMat = zeros( TRACE_READ_IDX_CNT, TRACE_TRACK_SIZE);
    
    for fileIdx = 1:TRACE_READ_IDX_CNT,
        fileName = strcat(request.TRACE_BASE_FOLDER,TRACE_READ_NAMES{fileIdx});

        fileID = fopen(fileName);
        trackNow = fread(fileID, inf, 'int16');
        fclose(fileID);
        assert(length(trackNow)== TRACE_TRACK_SIZE, '[ERROR]: TRACE_TRACK_SIZE not matched');
        traceMat(fileIdx, :) = trackNow;
    end

    % concate signals back to a vector (sound track)
    if request.traceChannelCnt == 1, % single channel recording (ex: LG G Watch)
        traceVec = reshape(traceMat', TRACE_READ_IDX_CNT*TRACE_TRACK_SIZE, 1);
    elseif request.traceChannelCnt == 2, % stereo channel recording (ex: Samsung S5)
        traceMatR = traceMat(:, 1:2:end);
        traceMatL = traceMat(:, 2:2:end);

        traceVecR = reshape(traceMatR', TRACE_READ_IDX_CNT*TRACE_TRACK_SIZE/2, 1);
        traceVecL = reshape(traceMatL', TRACE_READ_IDX_CNT*TRACE_TRACK_SIZE/2, 1);

        traceVec = [traceVecR, traceVecL];
    end

    % *** just for debug ***
    %AnaFreqSpectrum(traceSound, FS);
    %spectrogram(traceSound,256,250,256,FS,'yaxis')
    %sound(traceSound, FS)
end


end

