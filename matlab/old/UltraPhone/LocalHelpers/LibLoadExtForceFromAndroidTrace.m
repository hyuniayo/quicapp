function [ dataStampes,  dataForces ] = LibLoadExtForceFromAndroidTrace( traceFilePath )
% 2016/10/22: Load trace from arduino + android (defined in calibration activlity)
% assumed data formate:
% recordStamp(Uint32) | force(UInt32)
% Note force is not scaled -> basically 0~1023, and -5V is used to amplify
% force sensor circuit
    if ~exist('traceFilePath','var'),
        fprintf('[WARN]: undefined traceFilePath, default traceFilePath is used\n')
        %traceFilePath = '/Users/eddyxd/Downloads/test.xcappdata/AppData/Documents/AudioAna/DebugOutput/motion.dat'; % ios traces
        traceFilePath = '/Users/eddyxd/Downloads/audio/AudioAna/DebugOutput/ext.dat'; % ios traces
    end


    if(~exist(traceFilePath, 'file')),
        fprintf('[ERROR]: unable to load ext force data at %s\n', traceFilePath);
        return
    end
    
    fileID = fopen(traceFilePath);
    dataTotal = fread(fileID, inf, 'uint32'); % note: load all data to int32 and make transformation latter (assume all use 4-byte to save data)
    fclose(fileID);
    
    dataStampes = dataTotal(1:2:end);
    dataForces = dataTotal(2:2:end);




end

