function [ dataStampes,  dataMotions] = LibLoadMotion( traceFilePath )
    % 2015/11/01: this function load sensor motion data
    % TODO: improve performance by avoid reading file twice
    % assumed data formate:
    % recordStamp(Uint32) | accX(float32) | accY | accZ ....

    if ~exist('traceFilePath','var'),
        fprintf('[WARN]: undefined traceFilePath, default traceFilePath is used\n')
        %traceFilePath = '/Users/eddyxd/Downloads/test.xcappdata/AppData/Documents/AudioAna/DebugOutput/motion.dat'; % ios traces
        traceFilePath = '/Users/eddyxd/Downloads/bftemp/DebugOutput_100_custompilot20Hzlong_move_1/motion.dat'; % ios traces
    end
    
    DATA_FILED_CNT = 1+6;
    
    if(~exist(traceFilePath, 'file')),
        fprintf('[ERROR]: unable to load motion data at %s\n', traceFilePath);
        return
    end
    
    fileID = fopen(traceFilePath);
    dataTotal = fread(fileID, inf, 'uint32'); % note: load all data to int32 and make transformation latter (assume all use 4-byte to save data)
    fclose(fileID);
    
    dataTotalLen = length(dataTotal);
    assert(mod(dataTotalLen, DATA_FILED_CNT)==0,'[ERROR]: data format ummatched (wrong DATA_FILED_CNT or data format?)\n');
    dataRecordCnt = dataTotalLen/DATA_FILED_CNT;
    
    dataStampIdxs = [1:DATA_FILED_CNT:dataTotalLen];
    dataMotionIdxs = [1:dataTotalLen];
    dataMotionIdxs(dataStampIdxs) = [];
    
    
    dataStampes = dataTotal(dataStampIdxs);
    
    
    fileID = fopen(traceFilePath);
    dataTotal = fread(fileID, inf, 'single'); % note: load all data to int32 and make transformation latter (assume all use 4-byte to save data)
    fclose(fileID);
    dataMotions = dataTotal(dataMotionIdxs);
    dataMotions = reshape(dataMotions, [DATA_FILED_CNT-1, dataRecordCnt]);
    %dataMotions = typecast(dataMotions, 'single');
    
    assert(length(dataStampes) == size(dataMotions, 2), '[ERROR]: size of dataSamples and dataMotions unmatched (parse it worng?)\n');


end

