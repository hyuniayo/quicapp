function [bssids, levels] = loadWifiInput( inputPath )
%==========================================================================
% 2014/12/28: read sensor input from sensor files
% 2015/02/16: adjust for new format
% 2015/02/23: update to wifi format
%==========================================================================
    inputPath
    
    
    fileID = fopen(inputPath,'r');
    
    [data, count] = fscanf(fileID, '%x:%x:%x:%x:%x:%x,%d', [7, inf]);
    
    [~, traceCnt] = size(data);
    
    bssids = zeros(1,traceCnt);

    for i = 1:6,
        bssids = bssids.*256 + data(i,:);
    end
    
    levels = data(7,:);
end

