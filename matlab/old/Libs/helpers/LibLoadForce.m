function [ dataStampes, dataForces ] = LibLoadForce( traceFilePath )
    % 2015/11/01: a similar funcation as LibLoadMotion which is used to
    %             load force data instead

    if ~exist('traceFilePath','var'),
        fprintf('[WARN]: undefined traceFilePath, default traceFilePath is used\n')
        traceFilePath = '/Users/eddyxd/Downloads/test.xcappdata/AppData/Documents/AudioAna/DebugOutput/force.dat'; % server traces
    end
    
    DATA_FILED_CNT = 2;
    
    if(~exist(traceFilePath, 'file')),
        fprintf('[ERROR]: unable to load force data at %s\n', traceFilePath);
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
    dataForces = dataTotal(dataMotionIdxs);
    dataForces = reshape(dataForces, [DATA_FILED_CNT-1, dataRecordCnt])';
    
    
end

