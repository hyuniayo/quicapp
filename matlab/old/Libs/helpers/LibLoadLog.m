function [ dataStampes, dataCodes, dataArg0s, dataArg1s] = LibLoadLog( traceFilePath )
    % 2015/11/01: load ground turth log
    if ~exist('traceFilePath','var'),
        fprintf('[WARN]: undefined traceFilePath, default traceFilePath is used\n')
        traceFilePath = '/Users/eddyxd/Downloads/squeeze.xcappdata/AppData/Documents/AudioAna/DebugOutput/pse.dat'; % ios traces
        %traceFilePath = '/Users/eddyxd/Downloads/s/DebugOutput/mfo.dat'; % note 4 traces
    end
    
    DATA_FILED_CNT = 4;
    
    if(~exist(traceFilePath, 'file')),
        fprintf('[ERROR]: unable to load force data at %s\n', traceFilePath);
        dataStampes = [];
        dataCodes = [];
        dataArg0s = [];
        dataArg1s = [];
        return
    end
    
    fileID = fopen(traceFilePath);
    dataTotal = fread(fileID, inf, 'uint32'); % note: load all data to int32 and make transformation latter (assume all use 4-byte to save data)
    fclose(fileID);
    
    dataTotalLen = length(dataTotal);
    assert(mod(dataTotalLen, DATA_FILED_CNT)==0,'[ERROR]: data format ummatched (wrong DATA_FILED_CNT or data format?)\n');
    dataRecordCnt = dataTotalLen/DATA_FILED_CNT;
    
    % 1. load stample
    dataStampes = dataTotal(1:DATA_FILED_CNT:end);
    
    
    % 2. load code
    fileID = fopen(traceFilePath);
    dataTotal = fread(fileID, inf, 'int32'); % note: load all data to int32 and make transformation latter (assume all use 4-byte to save data)
    fclose(fileID);
    dataCodes = dataTotal(2:DATA_FILED_CNT:end);
    
    
    % 3. load other args
    fileID = fopen(traceFilePath);
    dataTotal = fread(fileID, inf, 'single'); % note: load all data to int32 and make transformation latter (assume all use 4-byte to save data)
    fclose(fileID);
    
    dataArg0s = dataTotal(3:DATA_FILED_CNT:end);
    dataArg1s = dataTotal(4:DATA_FILED_CNT:end);

end

