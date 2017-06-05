%==========================================================================
% 2016/06/02: This calss help to generate engine sound played by app
%==========================================================================

FS = 48000;

LEN = 4*FS;

DATA_FREQ = 100;

t = 0:1/FS:(LEN-1)/FS;

data = square(2*pi*t*DATA_FREQ);

NEED_FILTER = 1
FILTER_ORDER = 15;
FILTER_CUT_FREQ_LOW = 15000; % Hz

% try to make hormanics
H_MAX = 10; % # of hormanics
dataHormanic = zeros(LEN,1);
for hIdx = 1:H_MAX,
    weigth = 1/H_MAX;
    dataHormanic = dataHormanic + weigth.*square(2*pi*t*DATA_FREQ*hIdx)';
end

%sound(dataHormanic,FS);
force = zeros(1, LEN); % alwyas low key
%force = [0:1/((LEN/2)-1):1, 1:-1/((LEN/2)-1):0];
DATA_FREQ_MIN = 50;
DATA_FREQ_MAX = 100;
DATA_FREQ_CNT = DATA_FREQ_MAX-DATA_FREQ_MIN;

% try to build sound table
TABLE_DATA_LEN = 960*4; % 1/10 second long signal
dataTable = zeros(TABLE_DATA_LEN, DATA_FREQ_CNT);

for fIdx = 1:DATA_FREQ_CNT,
    freqNow = DATA_FREQ_MIN+fIdx-1;
    tNow = 0:1/FS:(TABLE_DATA_LEN-1)/FS;
    
    for hIdx = 1:H_MAX,
        weigth = 1/H_MAX;
        dataTable(:, fIdx) = dataTable(:, fIdx) + weigth.*square(2*pi*tNow*freqNow*hIdx)';
    end
end

% filter the data if need
if exist('NEED_FILTER','var') && NEED_FILTER == 1,
    [pfB, pfA] = butter(FILTER_ORDER, FILTER_CUT_FREQ_LOW/(FS/2), 'low');
    dataTableOri = dataTable;
    dataTable = filter(pfB, pfA, dataTableOri);
    
    %{
    plotFreqIdx = 1;
    figure; hold on;
    plot(dataTableOri(:,plotFreqIdx),'b-');
    plot(dataTable(:,plotFreqIdx),'r--');
    
    figure;
    subplot(2,1,1); title('not filtered');
    spectrogram(dataTableOri(:,plotFreqIdx),256,250,256,FS,'yaxis');
    subplot(2,1,2); title('filtered');
    spectrogram(dataTable(:,plotFreqIdx),256,250,256,FS,'yaxis');
    %}
    
end

fid = fopen('engineSoundShort.dat','wt');
ampFloatToShort = 20000;
for fIdx = 1:DATA_FREQ_CNT,
    dataToWrite = floor(dataTable(:, fIdx)*ampFloatToShort);
    fwrite(fid, dataToWrite, 'int16');
end
fclose(fid);


%{
javaDataTableString = cell(DATA_FREQ_CNT,1);
for fIdx = 1:DATA_FREQ_CNT,
    fIdx
    if fIdx == 1,
        javaDataTableString{fIdx} = 'public double[][] data = {';
    end
    javaDataTableString{fIdx} = strcat(javaDataTableString{fIdx}, '{');
    for tIdx = 1:TABLE_DATA_LEN,
        dataNow = dataTable(tIdx, fIdx);
        if dataNow == 0, % optimization -> too many 1 and 0
            javaDataTableString{fIdx} = sprintf('%s0,',javaDataTableString{fIdx});
        elseif  abs(dataNow - 1) < 0.0001,
            javaDataTableString{fIdx} = sprintf('%s1,',javaDataTableString{fIdx});
        else
            javaDataTableString{fIdx} = sprintf('%s%.3f,',javaDataTableString{fIdx},dataNow);
        end
    end
    % remove the last ","
    javaDataTableString{fIdx}(end) = '}';
    
    if fIdx < DATA_FREQ_CNT,
        javaDataTableString{fIdx} = strcat(javaDataTableString{fIdx}, ',');
    else
        javaDataTableString{fIdx} = strcat(javaDataTableString{fIdx}, '};');
    end
end
strResult = strjoin(javaDataTableString);
fid = fopen('engineSound.txt','wt');
fprintf(fid, strResult);
fclose(fid);
%}


dataFreqIdxBasedOnForce = ceil(DATA_FREQ_CNT*force);
dataFreqIdxBasedOnForce(dataFreqIdxBasedOnForce==0) = 1; % avoid 0 index in matlab
ampBasedOnForce = 0.5+(force*0.5);
dataBasedOnForce = zeros(LEN,1); % control data based on force
for fIdx = 1:DATA_FREQ_CNT,
    dataIdxInFreq = find(dataFreqIdxBasedOnForce==fIdx);
    dataIdxInTable = mod(dataIdxInFreq, TABLE_DATA_LEN-1)+1;
    
    dataBasedOnForce(dataIdxInFreq) = dataTable(dataIdxInTable, fIdx);
end
dataBasedOnForce = dataBasedOnForce.*ampBasedOnForce';

sound(dataBasedOnForce, FS);

REF_TRACE_BASE_FOLDER = 'EngineSoundRef/engine-loop-1-normalized.wav'

REP_END_SMOOTH_SAMPLES = 5000;

[refSound, FS] = audioread(REF_TRACE_BASE_FOLDER);

CH_TO_USE = 1;
refSound = refSound(:,CH_TO_USE);

soundBase = refSound(:, CH_TO_USE);

soundBaseSmoothed = soundBase(1:length(soundBase)-REP_END_SMOOTH_SAMPLES,:);
fadeInMask = (0:REP_END_SMOOTH_SAMPLES-1)'./(REP_END_SMOOTH_SAMPLES-1);
fadeInMask = fadeInMask./2+0.5;
fadeOutMask = ones(REP_END_SMOOTH_SAMPLES, 1) - fadeInMask;
soundBaseSmoothed(1:REP_END_SMOOTH_SAMPLES) = soundBase(1:REP_END_SMOOTH_SAMPLES).*fadeInMask + soundBase(length(soundBase)-REP_END_SMOOTH_SAMPLES+1:length(soundBase)).*fadeOutMask;

soundBaseRep = repmat(soundBase, [5, 1]);

sound(soundBaseRep,FS);







amp = sin((1:len)*4*pi/len);

REP = 10;

dataRep = repmat(data, [REP, 1]);
repLen = length(dataRep);
amp = sin((1:repLen)*4*pi/len)';

sound(dataRep(:,2).*amp,FS);

