%==========================================================================
% 2015/10/13: overwritted detection setting for note 4 only
% 2016/04/25: this is compatbile setting to the Android setting
%==========================================================================

% 1. re-initialize the current global detection setting
DetectionSettingBase;

% 2. update the device specific setting
gds.name = 'DetectionSettingNexus6p';

% 3. update audio parse setting
gds.NEED_TO_SEARCH_PILOT = 1;
gds.AUDIO_SAMPLE_TO_FIND_PILOT = 48000
gds.NEED_PRE_FILTER = 1
gds.PULSE_DETECTION_MAX_RANGE_METERS = 6; % meter

% 4. detection sepecific setting (Ultraphone only)
gds.SSE_DETECT_CH_IDX = 1; % use the second microphone to read

%base = 610;
%offset = 10;
%gds.SSE_DETECT_SAMPLE_RANGE = base:base+offset; % sample range to get reference
gds.SSE_DETECT_SAMPLE_RANGE = 600:620;

% 16/05/21: CH_IDX 1 seems better than 2 (for bottom speaker)
gds.PSE_DETECT_CH_IDX = 2; % use the second microphone to read
gds.PSE_DETECT_SAMPLE_RANGE = 597:607; % sample range to get reference
% use small value might have trouble -> suggest to have bigger than 610


% 5. squeeze detection setting
gds.SQUEEZE_LEN_TO_CHECK = 30;
gds.USE_TWO_END_CORRECT = 1; % correct data by two end
gds.PEAK_WIN = 8;
gds.PEAK_HARD_THRES_HIGH = 0.15; % this is the hard threshold must feed    
gds.PEAK_HARD_THRES_LOW = 0.1;

% *** WARN: soft thres can only be used in TWO_END_CORRECT mode ->
% otherwise the mean will be too high ***
gds.PEAK_SORT_THRES_RATIO_HIGH = 1.5; % multiple of std to achieve for peak
gds.PEAK_SORT_THRES_RATIO_LOW = 0.5; % multiple of std to achieve for peak
gds.PEAK_LOW_WIDTH_MAX = 9; % with constrain of the peak values over low thres
gds.PEAK_LOW_WIDTH_MIN = 3;
gds.CHECK_PEAK_CNT = 2;
gds.CHECK_PEAK_DIFF_RANGE = [6, 25];
gds.CHECK_PEAK_OFFSET_START_RANGE = [0, 40];
gds.CHECK_PEAK_RATIO_MIN = 0.4; % 0.5 means peak should be twice as the edge


% save the current setting to global setting
save(GLOBAL_DETECTION_SETTING_PATH,'gds');