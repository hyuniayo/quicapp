%==========================================================================
% 2015/11/19: this is a hack to load device setting to current workspace
%           : NOTE it needs "deviceIdx"
%==========================================================================

if deviceIdx == 0, % defualt is iphone
    DetectionSettingIPhone6s;
elseif deviceIdx == 1, % Note 4
    DetectionSettingNote4;
else
    fprintf('[ERROR]: undefined deviceIdx = %d\n', deviceIdx);
end


