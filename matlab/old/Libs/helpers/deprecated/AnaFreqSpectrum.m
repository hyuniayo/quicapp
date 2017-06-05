function [  ] = AnaFreqSpectrum( signal ,FS )
% 2014/09/17: this is a function to plot
    DT = 1/FS;
    pilotFreq = fftshift(fft(signal));
    N = length(signal);
    DF = FS/N;
    f = -FS/2:DF:(FS/2-DF);

    figure;
    title('Freq Analysis');
    plot(f, abs(pilotFreq));
    xlabel('Freq (hertz)');
    ylabel('Amplitude')
end

