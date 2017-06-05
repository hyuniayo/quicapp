function [ names, namesCnt ] = LibGetTraceNames( targetFolder )
% 2014/09/20: this function fetches record names in the folder
    ds = dir(strcat(targetFolder,'record_*.txt'));
    
    names = {};
    nameIdx = 1;
    for nameIdx = 1:length(ds),
        names{nameIdx} = ds(nameIdx).name;
    end
    namesCnt = length(names);
end

