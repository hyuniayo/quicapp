%==========================================================================
% 2016/06/23: This file converts the sound file (wav) to binary dat file
%           : which is used to be played by AudioTrack
%==========================================================================

TRAGET_FILE_PREFIX = 'source_48000rate-5000repeat-2400period+chirp-18000Hz-24000Hz-1200samples+namereduced';
SOURCE_PATH = '../Source/';
TARGET_FILE_TO_LOAD_PATH = sprintf('%s%s.mat',SOURCE_PATH,TRAGET_FILE_PREFIX);
load(TARGET_FILE_TO_LOAD_PATH);

AMP_FROM_FLOAT_TO_SHORT = (2^15)-1; % do some adjustment in java later on

OUT_FILE_PATH_PILOT = sprintf('%s%s_pilot.dat', SOURCE_PATH, TRAGET_FILE_PREFIX);
OUT_FILE_PATH_SIGNAL = sprintf('%s%s_signal.dat', SOURCE_PATH, TRAGET_FILE_PREFIX);

pilotWithOffset = [zeros(PILOT_START_OFFSET,1); pilotToAdd ;zeros(PILOT_END_OFFSET,1)];

% write pilot
fid = fopen(OUT_FILE_PATH_PILOT,'wt');
pilotToWrite = floor(pilotWithOffset.*AMP_FROM_FLOAT_TO_SHORT);
fwrite(fid, pilotToWrite, 'int16');
fclose(fid);

% write signal
fid = fopen(OUT_FILE_PATH_SIGNAL,'wt');
signalToWrite = floor(signalOnce.*AMP_FROM_FLOAT_TO_SHORT);
fwrite(fid, signalToWrite, 'int16');
fclose(fid);