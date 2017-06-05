function [ result ] = LibFindStartAndEndRange( range,  data)
% this is a function to ease finding begin and end of array inside a range
% note range is a "2x1" array whcih is [RANGE_MIN; RANGE_MAX]
    assert(length(range)==2, '[ERRPR]: range is a "2x1" array whcih is [RANGE_MIN; RANGE_MAX]');
    
    % NOTE negative data is excluded
    mins = find(data>=0 & data>range(1));
    maxs = find(data>=0 & data<range(2));
    result = zeros(2,1);
    if isempty(mins),
        % all data is smaller RANGE_MIN -> set min index to end of data
        fprintf('[WARN]: all the data is smaller than RANGE_MIN = %d\n',rnage(1));
        result(1) = 1;
    else
        [~, minIdx] = min(data(mins));
        result(1) = mins(minIdx);
    end
    
    if isempty(maxs),
        fprintf('[WARN]: all the data is bigger than RANGE_MAX = %d\n',range(2));
        result(2) = length(data);
    else
        [~, maxIdx] = max(data(maxs));
        result(2) = maxs(maxIdx);
    end

end

