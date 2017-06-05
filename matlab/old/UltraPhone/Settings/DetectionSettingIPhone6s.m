%==========================================================================
% 2015/10/13: overwritted detection setting for note 4 only
%==========================================================================

% 1. re-initialize the current global detection setting
DetectionSettingBase;

% 2. update the device specific setting
gds.name = 'DetectionSettingIphone6s';

% 3. update audio parse setting
gds.NEED_TO_SEARCH_PILOT = 1;
gds.AUDIO_SAMPLE_TO_FIND_PILOT = 35000;
gds.NEED_PRE_FILTER = 1;

% 4. detection sepecific setting (Ultraphone only)
gds.SSE_DETECT_CH_IDX = 1; % use the top microphone to read
gds.SSE_DETECT_SAMPLE_RANGE = 600:620; % sample range to get reference

gds.PSE_DETECT_CH_IDX = 1; % use the top microphone to read
% *** NOTE: start of Mobisys paper setting ***
%gds.PSE_DETECT_SAMPLE_RANGE = 600:620; % sample range to get reference
% *** NOTE: end of Mobisys paper setting   ***
gds.PSE_DETECT_SAMPLE_RANGE = 590:610; % sample range to get reference


% 5. squeeze detection setting
gds.SQUEEZE_LEN_TO_CHECK = 30;
gds.USE_TWO_END_CORRECT = 1; % correct data by two end
gds.PEAK_WIN = 8;
gds.PEAK_HARD_THRES_HIGH = 0.08; % this is the hard threshold must feed    
gds.PEAK_HARD_THRES_LOW = 0.04;

% *** WARN: soft thres can only be used in TWO_END_CORRECT mode ->
% otherwise the mean will be too high ***
gds.PEAK_SORT_THRES_RATIO_HIGH = 1.5; % multiple of std to achieve for peak
gds.PEAK_SORT_THRES_RATIO_LOW = 0.5; % multiple of std to achieve for peak
gds.PEAK_LOW_WIDTH_MAX = 8; % with constrain of the peak values over low thres
gds.PEAK_LOW_WIDTH_MIN = 2;
gds.CHECK_PEAK_CNT = 2;
gds.CHECK_PEAK_DIFF_RANGE = [6, 25];
gds.CHECK_PEAK_OFFSET_START_RANGE = [0, 40];
gds.CHECK_PEAK_RATIO_MIN = 0.4; % 0.5 means peak should be twice as the edge



% save the current setting to global setting
save(GLOBAL_DETECTION_SETTING_PATH,'gds');