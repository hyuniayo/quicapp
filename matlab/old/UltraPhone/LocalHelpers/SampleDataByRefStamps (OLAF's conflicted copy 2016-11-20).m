function [ dataSampled ] = SampleDataByRefStamps( data, stamps, stampsSampled )
% 2015/11/24: this scripts fetch the necessary data based on data

[DATA_CNT] = length(data);
[SAMPLE_CNT] = length(stampsSampled);
assert(DATA_CNT == length(stamps), '[ERROR]: data and stamp size unmated');
assert(min(stamps)<min(stampsSampled) & max(stamps)>max(stampsSampled), '[ERROR]: not enough data stamps to be sampled');

dataSampled = zeros(SAMPLE_CNT,1);
dataIdx = 1;
for sampleIdx = 1:SAMPLE_CNT,
    refStamp = stampsSampled(sampleIdx);
    
    while dataIdx < DATA_CNT,
        if stamps(dataIdx)<refStamp && stamps(dataIdx+1)>refStamp,
            dataSampled(sampleIdx) = (data(dataIdx) + data(dataIdx+1))/2;
            break;
        end
        dataIdx = dataIdx + 1;
    end
end

