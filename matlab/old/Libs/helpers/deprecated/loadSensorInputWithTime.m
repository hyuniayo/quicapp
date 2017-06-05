function [ data, dataGyros, dataTilts, dataGeomags, dataTimes] = loadSensorInputWithTime( sensorInputPath, timeInputPath )
%==========================================================================
% 2014/12/28: read sensor input from sensor files
% 2015/02/16: adjust for new format
% 2015/03/06: this is a short version to get both trace data and time stamp
%==========================================================================
    sensorInputPath
    timeInputPath
    
    
    
    %tiltX, tiltY, tiltZ, gyroX, gyroY ,gyroZ, geoMagX, geoMagY, geoMagZ
    
    
    fileID = fopen(sensorInputPath, 'r');
    
    [data, count] = fscanf(fileID, '%f:%f:%f|%f:%f:%f|%f:%f:%f', [9, inf]);
    

    dataTilts = data(1:3,:);
    dataGyros = data(4:6,:);
    dataGeomags = data(7:9,:);
    
    fileID = fopen(timeInputPath, 'r');
    
    [time, count] = fscanf(fileID, '%d-%d_%d-%d-%d-%d', [6, inf]);
    
    
    dataTimes = ((time(2,:).*100 + time(3,:)).*100 + time(4,:)).*100;
    dataMinutes = ((time(2,:).*24 + time(3,:)).*60 + time(4,:));
    
end

