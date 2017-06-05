function [ dataSampled ] = SampleDataByRefStamps( data, stamps, stampsSampled )
% 2015/11/24: this scripts fetch the necessary data based on data

[DATA_CNT] = length(data);
[SAMPLE_CNT] = length(stampsSampled);
assert(DATA_CNT == length(stamps), '[ERROR]: data and stamp size unmated');

TOLERANCE_END_DELAY = 48000/40;
if max(stamps)<= max(stampsSampled) & max(stampsSampled) - max(stamps) < TOLERANCE_END_DELAY,
    fprintf('[WARN]: SampleDataByRefStamps: end samples is too early but in the TOLERANCE_END_DELAY, trying to extend the audio recording end time\n');
    stampsSampled(end) = stamps(end)-1;
end

assert(min(stamps)<min(stampsSampled) & max(stamps)>max(stampsSampled), '[ERROR]: not enough data stamps to be sampled');

dataSampled = zeros(SAMPLE_CNT,1);
dataIdx = 1;
for sampleIdx = 1:SAMPLE_CNT,
    refStamp = stampsSampled(sampleIdx);
    
    while dataIdx < DATA_CNT,
        if stamps(dataIdx)<refStamp && stamps(dataIdx+1)>refStamp,
            dataSampled(sampleIdx) = (data(dataIdx) + data(dataIdx+1))/2;
            % TODO: make it averaged if there are more than 1 data points
            % around the turning points
            break;
        end
        dataIdx = dataIdx + 1;
    end
end

