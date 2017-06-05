function [ result, optimalParam, model ] = SvmCrossValidation(ySVM, xSVM,  opt, targetParamName, targetParamRange, validateSize)
% 2014/10/01: check parameters of SVM tuning

    PARAM_SIZE = length(targetParamRange);

    result = zeros(PARAM_SIZE, 1);
    model = cell(PARAM_SIZE, 1);
    for paramIdx = 1:PARAM_SIZE,
        param = targetParamRange(paramIdx);
        
        optSvm = sprintf('%s %s %f', opt, targetParamName, param);
        
        result(paramIdx) = svmtrain(ySVM, xSVM, sprintf('%s -v %d', optSvm, validateSize));
        
        %model{paramIdx} = svmtrain(ySVM, xSVM, sprintf('%s -b 1', optSvm));
    end
    
    [maxResult, maxIdx] = max(result);
    optimalParam = targetParamRange(maxIdx);
end

