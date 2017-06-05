function [tp, fp, delayFromStart, delayAvgFromStart, delayFromTouch, delayAvgFromTouch, tpBySelect, delayAvgFromStartBySelect, delayAvgFromTouchBySelect, idleTime] = LoadTriggerTrace( traceFolderPath )
    if ~exist('traceFolderPath','var'),
        TRACE_FOLDER_PATH_DEFAULT = 'Traces/Trigger/TriggerData_sse_2_walking_huan_1/'
        traceFolderPath = TRACE_FOLDER_PATH_DEFAULT
        DEBUG_SHOW = 1;
    else
        DEBUG_SHOW = 0;
    end
    
    resultData = csvread(strcat(traceFolderPath,'result.csv'));
    resultCnt = size(resultData, 1);
    
    selectMax = max(resultData(:,1))+1;
    
    tp = sum((resultData(:,2)==1))/resultCnt;
    
    % chnage to only count tp data delay
    delayFromStart = resultData(:,5) - resultData(:,3);
    delayAvgFromStart = mean(delayFromStart);
    delayFromTouch = resultData(:,5) - resultData(:,4);
    delayAvgFromTouch = mean(delayFromTouch);
    
    tpBySelect = zeros(selectMax,1);
    delayAvgFromStartBySelect = zeros(selectMax,1);
    delayAvgFromTouchBySelect = zeros(selectMax,1);
    
    for select=1:selectMax,
        selectRange = logical(resultData(:,1)+1 == select);
        resultCntCntSelect = sum(selectRange==1);
        if ~isempty(selectRange),
            tpBySelect(select) = sum((resultData(selectRange,2)==1))/resultCntCntSelect;
            delayAvgFromStartBySelect(select) = mean(resultData(selectRange,5) - resultData(selectRange,3));
            delayAvgFromTouchBySelect(select) = mean(resultData(selectRange,5) - resultData(selectRange,4));
        end
    end
    
    d = dir(strcat(traceFolderPath,'fp.csv'));
    if d.bytes==0, % no data to read
        fp = 0;
    else
        fpData = csvread(strcat(traceFolderPath,'fp.csv'));
        % only count the fp after the test starts
        fp = sum(fpData>min(resultData(:,3)) & fpData<max(resultData(:,3)));
    end

    idleTime =sum( resultData(2:end,3) - resultData(1:end-1,5) ); % estimate the idle time for estimating false positive rate
end

