function [ extStampsCorrected, extCalibratedStartStamp, extCalibratedEndStamp ] = CalibrateExtForceByTouchEvent( extStamps, extCurrents, pseStamps, pseCodes, DEBUG_SHOW)
% 2015/11/23: calibrate the ext data by start and end instant forces

    if ~exist('DEBUG_SHOW','var'),
        DEBUG_SHOW = 1;
    end

    % *** just for debug *** MUST REMOVE IT
    %pseCodes = pseCodes(1:length(pseCodes)-2);
    %pseCodes = pseCodes(1:length(pseCodes)-2);
    % *** just for debug *** MUST REMOVE IT
    EXT_CALIBRATE_THRE = 4000; %uA
    EXT_CALIBRATE_WIDTH = 5000;
    EXT_CALIBRATE_TRUNCATE_STAMPE_OFFSET = 10000;
    SMOOTH_LEN = 10;
    
    extOverThre = find(smooth(extCurrents, SMOOTH_LEN) > EXT_CALIBRATE_THRE);
    
    extAnchorStarts = [];
    extAnchorEnds = [];
    
    extAnchorCnt = 0;
    
    extCurrentsCorrected = extCurrents;
    
    extOverThreIdx = 1; % index of extOverThre
    while extOverThreIdx <= length(extOverThre),
        
        startNow = extOverThre(extOverThreIdx);
        extAnchorCnt = extAnchorCnt+1; 
        extAnchorStarts = [extAnchorStarts; startNow];
        inWindowOffsets = find(extOverThre(extOverThreIdx:end)-extOverThre(extOverThreIdx)<EXT_CALIBRATE_WIDTH);
        endNow = extOverThre(extOverThreIdx+(inWindowOffsets(end)-1));
        extAnchorEnds = [extAnchorEnds; endNow];
        
        extCurrentsCorrected(startNow-EXT_CALIBRATE_WIDTH:endNow+EXT_CALIBRATE_WIDTH) = 0;
        
        extOverThreIdx = extOverThreIdx+length(inWindowOffsets);
    end
    
    % check the anchor statistics
    assert(length(extAnchorStarts)==2 && length(extAnchorEnds) == 2, '[ERROR]: anchor not matched');
    
    %extFisrtTriggerPeak = floor((extStamps(extAnchorStarts(1)) +  extStamps(extAnchorEnds(1)))/2)
    %pseFirstTriggerPeak = floor((pseStamps(1) + pseStamps(2))/2)
    
    fprintf('[WARN]: only the peak start used as calibirate reference now\n');
    extFisrtTriggerPeak = extStamps(extAnchorStarts(1));
    pseFirstTriggerPeak = pseStamps(1);
    
    
    extStampOffset = extFisrtTriggerPeak - pseFirstTriggerPeak;
    
    
    extStampsCorrected = extStamps - extStampOffset; % correct stamps
    
    % remove the peaks/touchs used for only calibarations
    extCalibratedStartStamp = pseStamps(2) + EXT_CALIBRATE_TRUNCATE_STAMPE_OFFSET;
    extCalibratedEndStamp = pseStamps(end-1) - EXT_CALIBRATE_TRUNCATE_STAMPE_OFFSET;
    
    if DEBUG_SHOW,
        extStampsToPlot = extStamps - extStampOffset;
        figure; 
        subplot(2,1,1); hold on;
        plot(extStampsToPlot,extCurrents);
        %plot(extStampsToPlot,smooth(extCurrents,10));
        ymaxs = get(gca,'ylim');
        xminNow = get(gca,'xlim');
        for i = 1:length(extAnchorStarts),
            plot([extStampsToPlot(extAnchorStarts(i)),extStampsToPlot(extAnchorStarts(i))], ymaxs, 'g-');
        end
        for i = 1:length(extAnchorEnds),
            plot([extStampsToPlot(extAnchorEnds(i)),extStampsToPlot(extAnchorEnds(i))], ymaxs, 'm-');
        end
        for i = 1:length(extAnchorEnds),
            plot([(extStampsToPlot(extAnchorEnds(i))+extStampsToPlot(extAnchorEnds(i)))/2,(extStampsToPlot(extAnchorEnds(i))+extStampsToPlot(extAnchorEnds(i)))/2], ymaxs, 'k-');
        end
        
        subplot(2,1,2);
        plot(pseStamps, pseCodes, '-o');
        xlim(xminNow);
    end

    
    
    
end

