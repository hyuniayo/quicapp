clear all;
close all;
clc;

% ------------------------------data import----------------------------------------
downsamplingRate = 5;
% folderName = './note2/1/';
folderName = './s5/staircase/9/';
% folderName = './s5/hold/14/';
% folderName = './s5/vchange/1/';
% folderName = './s5/handsway/2/';
% folderName = './s5/pantpocket/1/';
% folderName = './s5/users/peng/';
% folderName = './s5/turn test/5/';
% folderName = './s5/outdoor/1/';
% folderName = './s5/car/2/';
% folderName = './s5/long/2/';
% folderName = './s5/android debug/step/';
% folderName = './s5/android debug/turn/1/';
% folderName = './s5/elevator/1/';
% folderName = './s5/android debug/1/';
% folderName = './s5/traces/2/';
sensor = func_importfile(strcat(folderName, 'sensor.txt'));
Tick = importdata(strcat(folderName, 'tick.txt'));
sizeReading = size(sensor, 1);
% lengCut = 25 * downsamplingRate; % length of the cut part at the beginning
% lengCut = 21 * downsamplingRate;
lengCut = 0;
sizeReading = sizeReading - lengCut;

Ts = zeros(sizeReading, 1);
Tilt = zeros(sizeReading, 3);
Acc = zeros(sizeReading, 3);
Gra = zeros(sizeReading, 3);
Mag = zeros(sizeReading, 3);
Gyro = zeros(sizeReading, 3);
Acclin = zeros(sizeReading, 3);
Light = zeros(sizeReading, 1);
Temp = zeros(sizeReading, 1);
Prox = zeros(sizeReading, 1);
Baro = zeros(sizeReading, 1);
Step = zeros(sizeReading, 1);
Humi = zeros(sizeReading, 1);
Ori = zeros(sizeReading, 3);

for i = 1 : sizeReading
    try
        %timestamp
        Ts(i, 1) = sensor{i + lengCut, 3};
        
        % tilt
        strTilt = sensor{i + lengCut, 5};
        tmp = regexp(strTilt, ':', 'split');
        for j = 1 : 3
            Tilt(i, j) = str2double(char(tmp{j}));
        end
        
        % acc
        strAcc = sensor{i + lengCut, 6};
        tmp = regexp(strAcc, ':', 'split');
        for j = 1 : 3
            Acc(i, j) = str2double(char(tmp{j}));
        end
        
        % gravity
        strGra = sensor{i + lengCut, 7};
        tmp = regexp(strGra, ':', 'split');
        for j = 1 : 3
            Gra(i, j) = str2double(char(tmp{j}));
        end
        
        % mag
        strMag = sensor{i + lengCut, 8};
        tmp = regexp(strMag, ':', 'split');
        for j = 1 : 3
            Mag(i, j) = str2double(char(tmp{j}));
        end
        
        % gyro
        strGyro = sensor{i + lengCut, 9};
        tmp = regexp(strGyro, ':', 'split');
        for j = 1 : 3
            Gyro(i, j) = str2double(char(tmp{j}));
        end
        
        % acclin
        strAcclin = sensor{i + lengCut, 10};
        tmp = regexp(strAcclin, ':', 'split');
        for j = 1 : 3
            Acclin(i, j) = str2double(char(tmp{j}));
        end
        
        %light
        Light(i, 1) = sensor{i + lengCut, 11};
        
        %temperature
        Temp(i, 1) = sensor{i + lengCut, 12};
        
        %proximity
        Prox(i, 1) = sensor{i + lengCut, 13};
        
        %baro
        Baro(i, 1) = sensor{i + lengCut, 14};
        
        %step
        Step(i, 1) = sensor{i + lengCut, 15};
        
        %humidity
        Humi(i, 1) = sensor{i + lengCut, 16};
        
        % orientation
        strOri = sensor{i + lengCut, 17};
        tmp = regexp(strOri, ':', 'split');
        for j = 1 : 3
            Ori(i, j) = str2double(char(tmp{j}));
        end
    catch
        
    end
end
Tick = Tick - Ts(1, 1);
Ts = Ts - Ts(1, 1);

% ----------downsampling----------
if (folderName(3) == 's') % s5
    i = ceil(sizeReading / downsamplingRate);
    Ts = Ts(1 : downsamplingRate : (i-1) * downsamplingRate + 1);
    Tilt = Tilt(1 : downsamplingRate : (i-1) * downsamplingRate + 1, :);
    Gra = Gra(1 : downsamplingRate : (i-1) * downsamplingRate + 1, :);
    Acc = Acc(1 : downsamplingRate : (i-1) * downsamplingRate + 1, :);
    Acclin = Acclin(1 : downsamplingRate : (i-1) * downsamplingRate + 1, :);
    Gyro = Gyro(1 : downsamplingRate : (i-1) * downsamplingRate + 1, :);
    Mag = Mag(1 : downsamplingRate : (i-1) * downsamplingRate + 1, :);
    Ori = Ori(1 : downsamplingRate : (i-1) * downsamplingRate + 1, :);
    Light = Light(1 : downsamplingRate : (i-1) * downsamplingRate + 1);
    Temp = Temp(1 : downsamplingRate : (i-1) * downsamplingRate + 1);
    Prox = Prox(1 : downsamplingRate : (i-1) * downsamplingRate + 1);
    Baro = Baro(1 : downsamplingRate : (i-1) * downsamplingRate + 1);
    Step = Step(1 : downsamplingRate : (i-1) * downsamplingRate + 1);
    Humi = Humi(1 : downsamplingRate : (i-1) * downsamplingRate + 1);
    sizeReading = i;
else
    
end
f = sizeReading / Ts(end) * 1000; % approx sampling frequency (Hz)

save(strcat(folderName, 'data'));