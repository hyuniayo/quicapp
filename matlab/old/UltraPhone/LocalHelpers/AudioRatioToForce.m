function [ forcesApple, forces ] = AudioRatioToForce( audioRatios )
% 2015/11/29: This used the tuned parameter to conver audio ratio to force
%           : output is in g
    
    % hueiristic setting
    forces = (audioRatios.*8).*800; %g
    
    % apple-calibration setting
    forcesApple = 15+230*sqrt(audioRatios)+ 2880*audioRatios;
end

