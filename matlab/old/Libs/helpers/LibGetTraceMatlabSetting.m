function [ matFileName, traceChannelCnt, deviceIdx] = LibGetTraceMatlabSetting( targetFolder )
% read matlab setting from config
    matlabTraceFileName = 'matlab.txt';
    textFull = fileread(strcat(targetFolder, matlabTraceFileName));
    texts = strsplit(textFull, '\n');
    
    matFileName = texts{1};
    traceChannelCnt = str2num(texts{2});
    traceVol = str2num(texts{3});
    
    if length(texts)>=4, % has device trace
        deviceIdx = str2num(texts{4});
    else
        deviceIdx = -1;
    end
    
    matFileName = strcat(matFileName,'.mat');
end

