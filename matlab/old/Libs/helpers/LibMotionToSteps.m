function [ upPoints, stepAvg ] = LibMotionToSteps( motionData, motionStamps)
% 2015/11/15: This function changes the motion to steps

    if ~exist('motionData','var'),
        fprintf('[WARN]: use default motion data to estimate speed');
        DEFUALT_TRACE_PATH = '/Users/eddyxd/Downloads/note5debug/DebugOutput/motion.dat'
        [ motionStamps,  motionData] = LibLoadMotion( DEFUALT_TRACE_PATH );
    end
    DEBUG_SHOW = 0;
    
    acc = motionData(1:3,:);
    accMags = sum(acc.^2);
    
    if DEBUG_SHOW,
        figure;
        subplot(2,1,1);
        plot([acc; accMags]');
        legend('acc x','acc y','acc z', 'acc mag');
        subplot(2,1,2);
        cdfplot(motionStamps(2:end)-motionStamps(1:end-1));
        legend('stamp difference');
    end
    
    accMagMean = mean(accMags);
    accMagStd = std(accMags);
    
    stepStartPoint = 0;
    stepEndPoint = 0;

    stateUp = 1;
    
    transitionPoints = [];
    transitionPointIdx = 1;
    upPoints = [];
    upPointIdx = 1;
    for i = 1:length(accMags),
        accMag = accMags(i);
        
        if i==1, % init
            stepStartPoint = 1;
            if accMag > accMagMean,
                stateUp = 1;
            else
                stateUp = 0;
            end
        else
            if  stateUp && accMag < accMagMean,
                % transition from up to down
                diff = i - stepStartPoint;
                transitionPoints(transitionPointIdx) = (stepStartPoint + floor(diff/2));
                transitionPointIdx = transitionPointIdx+1;

                stateUp = 0;
                stepStartPoint = i;
                
            elseif stateUp==0 && accMag >= accMagMean,
                % transition from down to up
                diff = i - stepStartPoint;
                transitionPoints(transitionPointIdx) = (stepStartPoint + floor(diff/2));
                transitionPointIdx = transitionPointIdx+1;
                
                upPoints(upPointIdx) = (stepStartPoint + floor(diff/2));
                upPointIdx = upPointIdx+1;

                stateUp = 1;
                stepStartPoint = i;
            end
        end
    end

    stepAvg = length(upPoints)/(motionStamps(end)-motionStamps(1));
    
    if DEBUG_SHOW,
        figure; hold on;
        plot(accMags,'s-');
        plot(transitionPoints, accMags(transitionPoints),'gx');
        plot(upPoints, accMags(upPoints),'ro');
    end
%{
    temp = np.array(transitionPoints)
    diffs = temp[1:len(temp)] - temp[0:len(temp)-1]

    temp = np.array(upPoints)
    upDiffs = temp[1:len(temp)] - temp[0:len(temp)-1]
    durations = upDiffs*recordSampleDuration

    offsets = float(averagePace)/upDiffs# offset per step
%}

end

