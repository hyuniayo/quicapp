function [ signalAveraged ] = LibMovingAverage( signal, setting, DEBUG_SHOW )
% 2015/10/14: making the moving average of first dimensions
    if exist('setting','var'),
        POST_AVG_LEN = setting.POST_AVG_LEN;
    else
        fprintf('[WARN]: LibMovingAverage use local average setting\n');
        POST_AVG_LEN = 10;
    end

    if ~exist('DEBUG_SHOW', 'var'),
        DEBUG_SHOW = 0; % default setting
    end
        
    
    signalAveraged = convn(signal, ones(POST_AVG_LEN,1), 'same');


end

