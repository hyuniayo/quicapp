%==========================================================================
% 2015/11/19: this is a hack to load device setting to current workspace
%           : NOTE it needs "deviceIdx"
%==========================================================================

if deviceIdx == 0, % defualt is iphone
    DetectionSettingIPhone6s;
elseif deviceIdx == 1, % Note 4
    DetectionSettingNote4;
elseif deviceIdx == 101, % Note 4 + top speaker    
    DetectionSettingNote4TopSpeaker;
elseif deviceIdx == 2,
    DetectionSettingSamsungAfterS6;
elseif deviceIdx == 3, % S7 (note edge)
    DetectionSettingSamsungS7;
elseif deviceIdx == 4, % Nexus 6p
    DetectionSettingNexus6p;
else
    fprintf('[ERROR]: undefined deviceIdx = %d\n', deviceIdx);
end


