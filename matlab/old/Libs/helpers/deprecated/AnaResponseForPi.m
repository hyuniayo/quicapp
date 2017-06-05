%==========================================================================
% 2014/11/11: this is a analyze program for finding response of pi
%==========================================================================

%--------------------------------------------------------------------------
% 0. setting of global variables
%--------------------------------------------------------------------------

TRACE_PATH = '/Users/eddyxd/Documents/WalkSaferTrace/PiTest/sin/temp.wav';
SOURCE_MAT_PATH = 'source/hdsource_10repeat-96000period+chirp-1000Hz-24000Hz-1000samples+pilot+stereo_1cycle_0offset.mat'


load(SOURCE_MAT_PATH);


[traceVec, FS_READ] = wavread(TRACE_PATH);


NEQ_FS = FS/2;
FILTER_LOW_FREQ = 19000;
FILTER_HIGH_FREQ = 24500;





%--------------------------------------------------------------------------
% 1. FFT analysis
%--------------------------------------------------------------------------
BIN_START = 10000;
BIN_END = 50000;

signalT = traceVec;
[signalLen, channelCnt] = size(signalT);
    

[b,a] = butter(10, [FILTER_LOW_FREQ, FILTER_HIGH_FREQ]/NEQ_FS, 'bandpass');
signalTFiltered = filter(b,a,signalT);
%signalT = signalTFiltered; % update the singal with filtered copy

    
DT = 1/FS;
signalF = abs(fft(signalT));
for chIdx = 1:channelCnt,
    signalF(:,chIdx) = fftshift(signalF(:,chIdx), 1);
end
    
N = signalLen;
DF = FS/N;
freqs = -FS/2:DF:(FS/2-DF);
    
binMask = (freqs >= BIN_START).*(freqs <= BIN_END);
    
  
% *** start of section just for debug ***
figure; 
chTitles = {'channel R', 'channel L'};
for chIdx = 1:channelCnt,
    subplot(channelCnt, 1, chIdx); hold on;
    plot(freqs, signalF(:,chIdx)); plot(freqs, binMask.*max(max(signalF(:,chIdx))),'-mx');
    title(chTitles{chIdx})
    legend('signal F', 'binMask');
    ylabel('freq (Hz)');
    xlabel('abs of signal in freqs');
end
% ***  end of section just for debug  ***
    
    
fftBins = signalF(binMask==1,:);
freqs = freqs(binMask==1);

figure;
semilogy(freqs, fftBins(:,1),'b');
semilogy(freqs, fftBins(:,2),'r');
ylabel('freq (Hz)');
xlabel('abs of signal in freqs');

close all;