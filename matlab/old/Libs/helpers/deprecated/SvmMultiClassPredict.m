function [ probs, yPredict, confuseMatrix, accMean, yCandidates, accCandidates, yCandidateCorrectIdx, yDiff ] = SvmMultiClassPredict( xTest, yTest, TARGET_CNT, models, param , TARGET_DETAILS)
% 2014/11/23: extract the SVM part to here
% 2014/11/26: give the candidate options
% 2015/02/25: update reporting new metric: yDiff

    DATA_TEST_CNT = length(yTest);
    % predict based on svm
    probs = zeros(TARGET_CNT, DATA_TEST_CNT);
    neg_probs = zeros(TARGET_CNT, DATA_TEST_CNT);
    for targetIdx = 1:TARGET_CNT,
        fprintf('---------- svm predict of target model = %d , %s ----------\n', targetIdx, TARGET_DETAILS{targetIdx});
        model = models{targetIdx};
        
        ySVM = zeros(DATA_TEST_CNT,1);
        ySVM(yTest==targetIdx) = 1;
        ySVM(yTest~=targetIdx) = -1;
        
        [result, acc, prob]  = svmpredict(ySVM,xTest',model, param);
        probs(targetIdx,:) = prob(:,model.Label==1);
        neg_probs(targetIdx,:) = prob(:,model.Label==-1);
    end
    
    
    [yConfidence, yPredict] = max(probs);

    yDiff = zeros(TARGET_CNT-1, DATA_TEST_CNT)
    for i = 1:DATA_TEST_CNT,
        probCorret = probs(yTest(i), i);
        probsWrong = probs(:, i);
        probsWrong(yTest(i)) = [];
        probsWrong = sort(probsWrong, 'descend');
        probDiff = probCorret - probsWrong;
        yDiff(:, i) = probDiff;
    end
    
    
    confuseMatrix = zeros(TARGET_CNT,TARGET_CNT);
    for truthTargetIdx = 1:TARGET_CNT,
        for predictTargetIdx = 1:TARGET_CNT,
            confuseMatrix(truthTargetIdx, predictTargetIdx) = sum(yPredict(yTest==truthTargetIdx)==predictTargetIdx)/sum(yTest==truthTargetIdx);
        end
    end
    accMean = mean(diag(confuseMatrix))
    
    
    [yConfidences, yCandidates] = sort(probs, 'descend');
    yCandidateCorrectIdx = zeros(DATA_TEST_CNT, 1);
    
    for traceIdx = 1:DATA_TEST_CNT,
        yCandidateCorrectIdx(traceIdx) = find(yCandidates(:,traceIdx)==yTest(traceIdx));
    end
    
    
    accCandidates = zeros(TARGET_CNT,TARGET_CNT);
    for candidateIdx = 1:TARGET_CNT,
        for truthTargetIdx = 1:TARGET_CNT,
            yTargetRange = find(yTest==truthTargetIdx);
            accCandidates(truthTargetIdx, candidateIdx) = sum(yCandidateCorrectIdx(yTargetRange)<=candidateIdx)/length(yTargetRange);
        end
    end 
end

