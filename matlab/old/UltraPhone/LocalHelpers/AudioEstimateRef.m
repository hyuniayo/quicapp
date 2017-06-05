function [ ref ] = AudioEstimateRef( data, searchRange, godown )
% 2016/10/25: This is the new process to estimate the reference signal
    d1 = diff(data);
    d2 = diff(d1);
    
    d1SearchRange = searchRange - 1;
    d1SearchRange = d1SearchRange(d1SearchRange>0 & d1SearchRange<length(d1));
    
    d2SearchRange = searchRange - 2; % compensate the diff function offset
    d2SearchRange = d2SearchRange(d2SearchRange>0);
    d2SearchRange = d2SearchRange(d2SearchRange<=length(d2));

    dSearchRange = searchRange;
    searchRange = dSearchRange(dSearchRange>0 & dSearchRange<length(data));
    dataForSearch = data(searchRange);

if ~exist('godown','var') || godown == 0, % no godown or goup is detected
    % Use only fixed point to estimate
    refMean = mean(data(searchRange<length(data)));
    ref = repmat(refMean, size(data));
elseif godown == 1, % means godown
    [~, d2MaxIdx] = max(d2(d2SearchRange));
    refIdx = d2SearchRange(d2MaxIdx)+2;
    
    % keep the ref before data
    ref = data;
    ref(refIdx:end) = data(refIdx);
    
    %{
    maxRef = data(refIdx);
    for i = refIdx+1:length(ref),
        if data(i) > maxRef,
            maxRef = data(i);
        end 
        ref(i) = maxRef;
    end
    %}
elseif godown == -1,
    [~, d2MinIdx] = min(d2(d2SearchRange));
    refIdx = d2SearchRange(d2MinIdx)+2;
    
    % keep the ref before data
    ref = data;
    ref(refIdx:end) = data(refIdx);
    
    %{
    maxRef = data(refIdx);
    for i = refIdx+1:length(ref),
        if data(i) > maxRef,
            maxRef = data(i);
        end 
        ref(i) = maxRef;
    end
    %}
end
    

end

