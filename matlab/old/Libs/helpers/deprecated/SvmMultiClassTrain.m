function [ models ] = SvmMultiClassTrain(xTrain, yTrain, TARGET_CNT ,param , TARGET_DETAILS)
% 2014/11/23: extract the SVM part to here

    DATA_TRAIN_CNT = length(yTrain);

    % get the traiing model form svm
    models = cell(TARGET_CNT,1);
    for targetIdx = 1:TARGET_CNT,
        fprintf('---------- svm train of target model = %d , %s ----------\n', targetIdx, TARGET_DETAILS{targetIdx});
        %models{model_idx} = svmtrain(double(y_train==eid)', x_train','-t 2 -c 1 -g 1 -h 0 -b 1');
        %models{model_idx} = svmtrain(double(y_train==eid)', x_train','-t 3 -g 1 -h 0 -b 1');
        
        % --- 
        ySVM = zeros(DATA_TRAIN_CNT,1);
        ySVM(yTrain==targetIdx) = 1;
        ySVM(yTrain~=targetIdx) = -1;
        
        models{targetIdx} = svmtrain(ySVM, xTrain', param);
        
        
    end



end

