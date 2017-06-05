%==========================================================================
% 2015/09/28: update to use common library
%==========================================================================
addpath('LocalHelpers');
addpath('Settings');
addpath('../Libs/helpers');
addpath('../Libs/jtcp');
addpath('../Libs/jtcp/tcp_helper');
%addpath('../../analyzers');

HELPER_CLASS_PATH = '/Users/eddyxd/Dropbox/WorkspacePartial/ProjectRunning/AudioParser/Libs/jtcp/tcp_helper'; % just for MAC

DEBUG_FOLDER = 'Debug/';
RESULT_FOLDER = 'Results/'; % path to save traces
FIGURE_FOLDER = 'Figures/'; % path to save figures
TEMP_FOLDER = '../Temp/'; % path to save temporal mat files
AUDIO_SOURCE_FOLDER = '../Source/';

GLOBAL_DETECTION_SETTING_PATH = 'GlobalDetectionSetting';