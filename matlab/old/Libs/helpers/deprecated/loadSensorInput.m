function [ data, dataGyros, dataTilts, dataGeomags] = loadSensorInput( inputPath )
%==========================================================================
% 2014/12/28: read sensor input from sensor files
% 2015/02/16: adjust for new format
%==========================================================================
    inputPath
    
    
    % index of input data
    %index, shotPath, tiltX, tiltY, tiltZ, accX, accY,accZ, gravityX, gravityY, gravityZ, lightMag,accMag,linAccMag,geoX,geoY,geoZ
    
    
    fileID = fopen(inputPath,'r');
    
    
    % *** LONG FORMAT ***
    %{
    [data, count] = fscanf(fileID, '%f:%f:%f|%f:%f:%f|%f:%f:%f|%f:%f:%f|%f:%f:%f|%f:%f:%f', [18, inf]);
    dataTilts = data(1:3,:);
    dataGyros = data(13:15,:);
    dataGeomags = data(16:18,:);
    %}
    
    % *** SHORT FORMAT ***
    [data, count] = fscanf(fileID, '%f:%f:%f|%f:%f:%f|%f:%f:%f', [18, inf]);
    dataTilts = data(1:3,:);
    dataGyros = data(4:6,:);
    dataGeomags = data(7:9,:);
end

