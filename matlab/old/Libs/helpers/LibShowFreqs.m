function [ dataFreq, freqs ] = LibShowFreqs( dataTime, FS, SMOOTH_FACTOR, SHOW_LOG_SCALE )
% 2016/11/07: This function helps to plot freq response of signal in time

    if ~exist('SMOOTH_FACTOR','var'),
        SMOOTH_FACTOR = 1;
    end
    
    if ~exist('SHOW_LOG_SCALE','var'),
        SHOW_LOG_SCALE = 0;
    end

    figure; hold on;
    
    [N, CH_CNT] = size(dataTime);
    DF = FS/N;
    freqs = -FS/2:DF:(FS/2-DF);
    
    dataFreq = zeros(size(dataTime));
    
    for chIdx = 1:CH_CNT,
        subplot(CH_CNT, 1, chIdx); hold on; title(sprintf('ch %d', chIdx)); ylabel('abs(signal) in freqs');
        dataFreq(:, chIdx) = fftshift(abs(fft(dataTime(:, chIdx))));
        
        if SHOW_LOG_SCALE == 1,
            plot(freqs, 10*log10(smooth(dataFreq(:, chIdx), SMOOTH_FACTOR)));
            ylabel('10log10');
        else
            plot(freqs, smooth(dataFreq(:, chIdx), SMOOTH_FACTOR));
            ylabel('amp');
        end
    end
    
    hold off;
    xlabel('freq (Hz)');
    
    
end

