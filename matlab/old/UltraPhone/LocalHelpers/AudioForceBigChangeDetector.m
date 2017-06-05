function [ bigchange, godown ] = AudioForceBigChangeDetector( data, ref,  searchRange, thres)
% 2016/10/31: This function detect if there is a big change in the begining
%             so I can help to handle it if need
    
    
    
    
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
    
    
    VAR_REF_RANGE = [3:10];
    
    d1std = sqrt(var(d1(VAR_REF_RANGE)));
    
    VAR_THRES = 2;
    if max(abs(d1(d1SearchRange))) > d1std*VAR_THRES,
    %VAR_THRES = 3;
    %if max(dataForSearch)-min(dataForSearch) > d1std*VAR_THRES,
        bigchange = 1;
    else
        bigchange = 0;
    end
    
    if bigchange == 1, % need to determine if the data is godown or goup
        if sum(d1(d1SearchRange)) < 0,
            godown = 1;
        else
            godown = -1;
        end
    else
        godown = 0; % nothing go up or go down
    end
    
    
    %{
    dataChange = data-ref;
    dataChangeRatio = dataChange./ref;
    dataChangeRatioToSearch = dataChangeRatio(searchRange);
    biggestchange = max(dataChangeRatioToSearch) - min(dataChangeRatioToSearch);
    if biggestchange > thres,
        bigchange = 1; % TODO: knwo the change direction as well
    else
        bigchange = 0; 
    end
    %}
    
end

