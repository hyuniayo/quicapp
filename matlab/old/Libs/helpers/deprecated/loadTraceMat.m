%==========================================================================
% 2014/07/09: this is a file used to load trace mat file rendered by python
% 2014/09/21: update it to read mat file from matlab instead
%==========================================================================
%clear;

%ANA_RESULT_FOLDER = '/Users/eddyxd/Documents/SL_RESULTS/anaResult_s5_tung_yuan_krishna/'
%ANA_RESULT_FOLDER = '/Users/eddyxd/Documents/SL_RESULTS/anaResult_s5shiftoffset1_finalized/'
ANA_RESULT_FOLDER = 'debug/'
TRACE_FILE_NAME = 'trace.mat'

load(strcat(ANA_RESULT_FOLDER,TRACE_FILE_NAME));


[BIN_CNT, TRACK_CNT, CHANNEL_CNT] = size(fftBins);
