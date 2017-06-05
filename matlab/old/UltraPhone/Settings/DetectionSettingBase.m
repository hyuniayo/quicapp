%==========================================================================
% 2015/10/13: this is used as default setting of detection algorithm
% *** NOTE: the name "gds" is reserved for "Global Detection Setting" ***
%==========================================================================
clear gds; 

gds.name = 'DetectionSettingBase';

% general audio setting
gds.FS = 48000; % Hz
gds.SOUND_SPEED = 340; % m/s

% pilot detection ratio
gds.PILOT_SEARCH_CH_IDXS = [2];

% time vary gain = tvgAlpha*log10(t) + beta
gds.TVG_ALPHA = 0.65;
gds.TVG_BETA = 0;

% moving average after TVG
gds.POST_AVG_LEN = 10;

% detect control variables
gds.DETECT_WIN_SIZE = 20;
gds.DETECT_THRE = 0.5;

% motion filter and soft counting setting
gds.MOTION_FILTER_RANGE_MIN = 1.5; % meters
gds.MOTION_FILTER_RANGE_MAX = 5; % meters
gds.MOTION_FILTER_WIDTH = 3; % num of records to make filter
gds.SOFT_COUNTING_PERCENTILE = 25; % 25 meanse use 25% as indicator
gds.SOFT_COUNTING_THRE = 5*10^4; % thres hold hafter percentile


gds.DEBUG_SHOW = 0;

save(GLOBAL_DETECTION_SETTING_PATH,'gds');