function [ con ] = AudioProcessFindPulseMax( signal, pulse )
% 2015/10/18: This is a simple(trivial) process to find max value of pulse
%             corrleation
    filter = pulse(:); % column based
    filter = filter(end:-1:1);
    con = abs(convn(signal, filter, 'same'));
    %conSorted = sort(con, 1, 'descend');


end

