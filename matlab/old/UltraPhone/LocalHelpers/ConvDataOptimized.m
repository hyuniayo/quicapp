function [ data ] = ConvDataOptimized( signal, pulse, range)
% 2015/12/03: It is just a demo/test for JNI optimized convlution for
%           : getting data -> only the signal in range is conved
    
    if ~exist('signal', 'var'),
        %signal = [1;2;3;4;5;6;7;8;9;10];
        %signal = [signal, signal(end:-1:1)];
        %signal = round((rand(10,1)-0.5)*10);
        
        %pulse = [2;1];
        %pulse = round((rand(5,1)-0.5)*10);
        %range = [10:50];
        
        signal = [2,-1,-4,-4,3,2,-5,1,2,-4]';
        pulse = [-1,0,2,-4,6]';
        range = [3,5];
        
    end
    
    % *** just for debug ***
    DEBUG_SHOW = 1;
    % *** just for debug ***
    
    pulse = pulse(:); % make it to colume based
    
    
    [SAMPLE_CNT, REPEAT_CNT, CH_CNT] = size(signal);
    PULSE_LEN = length(pulse);
    RANGE_LEN = length(range);
    RANGE_OFFSET = round((PULSE_LEN-1)/2);
    
    if DEBUG_SHOW == 1,
        conByLib = convn(signal, pulse(end:-1:1), 'same');
    end
    
    data = zeros(REPEAT_CNT, CH_CNT);
    for chIdx = 1:CH_CNT, 
        for repeatIdx = 1:REPEAT_CNT,
            conByMe = zeros(RANGE_LEN, 1);
            conIdx = 1;
            for xStart = range(1)-RANGE_OFFSET:range(end)-RANGE_OFFSET,
                xEnd = min(SAMPLE_CNT, xStart+PULSE_LEN-1);
                signalNow = signal(xStart:xEnd, repeatIdx, chIdx);
                pulseNow = pulse(1:length(signalNow));
                
                conByMe(conIdx) = sum(signalNow(:).*pulseNow(:));
                conIdx = conIdx + 1;
            end
            
            if DEBUG_SHOW,         
                figure; hold on;
                plot(conByMe); 
                plot(conByLib(range, repeatIdx),'o'); 
                legend('by me', 'by lib');
            end
            
            data(repeatIdx, chIdx) = sum(abs(conByMe));
        end
    end

end

