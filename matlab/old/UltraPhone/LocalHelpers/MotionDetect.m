function [ motionState, accMetricIn, accMetricBefore, gyroMetricIn, gyroMetricBefore] = MotionDetect(accMagIn, gyroMagIn, accMagBefore, gyroMagBefore )
%function [ motionState, accMetricIn, accMetricBefore, gyroMetricIn, gyroMetricBefore] = MotionDetect(accMag, gyroMag, rangeIn, rangeBefore )
% 2015/11/26: used to detect if there is a serious moving
%{
    accMetricIn = mean(accMag(rangeIn));
    accMetricBefore = mean(accMag(rangeBefore));
    gyroMetricIn = mean(gyroMag(rangeIn));
    gyroMetricBefore = mean(gyroMag(rangeBefore));
%}

    accMetricIn = mean(accMagIn);
    accMetricBefore = mean(accMagBefore);
    gyroMetricIn = mean(gyroMagIn);
    gyroMetricBefore = mean(gyroMagBefore);

    motionState = -1; %default status
    
    
    
    
    
end

