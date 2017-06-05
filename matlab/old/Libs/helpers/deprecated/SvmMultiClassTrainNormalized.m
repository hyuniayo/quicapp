function [ models ] = SvmMultiClassTrainNormalized(xTrain, yTrain, TARGET_CNT ,param , TARGET_DETAILS)
% 2014/11/23: extract the SVM part to here
% 2014/11/26: this version of SVM try to normalized the postive and
% negative training sequence by random selection

    DATA_TRAIN_CNT = length(yTrain);

    SINGLE_TARGET_TRAIN_CNT = DATA_TRAIN_CNT/TARGET_CNT
    
    TO_KEEP_RATIO = 1; % factor of keeping more neg data than pos data
    MIN_TO_KEEP = 1;
    NEGATIVE_DATA_TO_KEEP = max(min(floor(SINGLE_TARGET_TRAIN_CNT*TO_KEEP_RATIO/(TARGET_CNT-1)),SINGLE_TARGET_TRAIN_CNT),MIN_TO_KEEP);
    
    % ex: train positive = 5 / negative = 95 -> to_keep = 
    
    % get the traiing model form svm
    models = cell(TARGET_CNT,1);
    for targetIdx = 1:TARGET_CNT,
        fprintf('---------- svm train of target model = %d , %s ----------\n', targetIdx, TARGET_DETAILS{targetIdx});
        %models{model_idx} = svmtrain(double(y_train==eid)', x_train','-t 2 -c 1 -g 1 -h 0 -b 1');
        %models{model_idx} = svmtrain(double(y_train==eid)', x_train','-t 3 -g 1 -h 0 -b 1');
        
        yRemoved = yTrain;
        xRemoved = xTrain;
        % --- remove more negative traces ---
        for removeIdx = 1:TARGET_CNT,
            if removeIdx~=targetIdx,
                % those are trace need to be removed
                removeRange = find(yRemoved==removeIdx);
                selectIdxs = randperm(length(removeRange));
                removeRangeSelected = removeRange(selectIdxs(NEGATIVE_DATA_TO_KEEP+1:end));
                yRemoved(removeRangeSelected) = [];
                xRemoved(:,removeRangeSelected) = [];
            end
        end
        
        assert(length(yRemoved) == SINGLE_TARGET_TRAIN_CNT*1 + NEGATIVE_DATA_TO_KEEP*(TARGET_CNT-1),'[ERROR]: unmatched removed size');
        
        
        ySVM = zeros(length(yRemoved),1);
        ySVM(yRemoved==targetIdx) = 1;
        ySVM(yRemoved~=targetIdx) = -1;
        
        
        models{targetIdx} = svmtrain(ySVM, xRemoved', param);
        
        
    end



end

