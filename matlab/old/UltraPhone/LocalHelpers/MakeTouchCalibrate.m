function [ cof, regressValues, regressErros ] = MakeTouchCalibrate( soundSignals, targetValues, regressOrders, DEBUG_SHOW )
% 2016/03/26: make calibration based on regressions
    if ~exist('DEBUG_SHOW','var'),
        DEBUG_SHOW = 1;
    end

    soundSignalsToRegress = PrepareDataToRegress(soundSignals, regressOrders);
    cof = regress(targetValues, soundSignalsToRegress);

    regressValues = soundSignalsToRegress*cof;
    regressErros = abs(regressValues-targetValues);
    
    %corrAll = corr(forceEstimated, appleForceValid);
    %mseAll = sqrt(sum(errorAll.^2)./length(errorAll));
    
    if DEBUG_SHOW,
        figure; hold on;
        plot(soundSignals, targetValues,'o');
        plot(soundSignals, regressValues, 'x');
        
        figure;
        cdfplot(regressErros);
    end
end

