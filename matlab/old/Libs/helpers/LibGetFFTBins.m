function [ signalF, freqs, fftBins ] = LibGetFFTBins( signalT, FS, BIN_START, BIN_END, BIN_CNT)
% 2014/09/20: function to make FFT analysis on time series data
% 2014/09/30: update function to aggregate SWEEP signals
% 2015/10/23: update to do fft at multi-dimensional data


    binRanges = linspace(BIN_START, BIN_END, BIN_CNT);
    [signalLen, repeatLen, channelCnt] = size(signalT);
    %signalF = fft(signalT);
    
    
    DT = 1/FS;
    signalF = abs(fft(signalT));
    for chIdx = 1:channelCnt,
        signalF(:,:,chIdx) = fftshift(signalF(:,:,chIdx), 1);
    end
    
    N = signalLen;
    DF = FS/N;
    freqs = -FS/2:DF:(FS/2-DF);
    
    binMask = (freqs >= BIN_START).*(freqs <= BIN_END);
    
    % *** start of section just for debug ***
    %{
    figure; 
    chTitles = {'channel R', 'channel L'};
    for chIdx = 1:channelCnt,
        subplot(channelCnt, 1, chIdx); hold on;
        plot(freqs, signalF(:,:,chIdx)); plot(freqs, binMask.*max(max(signalF(:,:,chIdx))),'-mx');
        title(chTitles{chIdx})
        legend('signal F', 'binMask');
        ylabel('freq (Hz)');
        xlabel('abs of signal in freqs');
    end
    %}
    % ***  end of section just for debug  ***
    
    
    fftBins = signalF(binMask==1,:,:);
    freqs = freqs(binMask==1);
    
    % *** start of packing bins ***
    if exist('BIN_CNT'),
        fprintf('[WARN]: bin is repackaged based on BIN_CNT = %d\n', BIN_CNT);
        binFreqBounds = linspace(freqs(1), freqs(end),BIN_CNT+1);
    
        fftBinsPacked = zeros(BIN_CNT, repeatLen, channelCnt);
    
        for binPackIdx = 1:BIN_CNT,
            binFreqMin = binFreqBounds(binPackIdx);
            binFreqMax = binFreqBounds(binPackIdx+1);
            binPackMask = (freqs >= binFreqMin).*(freqs < binFreqMax);
        
            fftBinsPacked(binPackIdx, :, :) = sum(fftBins(binPackMask==1,:,:),1); 
        end
    
        % *** update fftbins ***
        fftBins = fftBinsPacked;
        freqs = binFreqBounds(1:end-1);
        %}
        % ***  end of packing bins  ***
    end
    
    
end

