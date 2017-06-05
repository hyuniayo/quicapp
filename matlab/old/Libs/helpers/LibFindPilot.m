function [ pilotEndOffset, pilotDiffers ] = LibFindPilot( signal, pilot, serchChIdxs, DEBUG_SHOW)
% 2015/10/17: check if pilot is found successfully
%             pilotEndOffset is the end sample offset of last pilot signal
	
    if ~exist('DEBUG_SHOW','var'),
        DEBUG_SHOW = 0;
    end

    if exist('serchChIdxs', 'var'),
        PILOT_SEARCH_CH_IDXS = serchChIdxs;
    else
        PILOT_SEARCH_CH_IDXS = [2]; % default used for andorid -> bottom microphone and bottom speaker
    end
    
    
    if size(signal,2) == 1,
        fprintf('[WARN]: recording is single track -> use only the first channel to findn pilot\n');
        PILOT_SEARCH_CH_IDXS = [1]
    end
    
    PILOT_SEARCH_CH_CNT = length(PILOT_SEARCH_CH_IDXS);
    PILOT_SEARCH_PEAK_WINDOW = 30;
    PILOT_REPEAT_CNT = 10;
    
    % *** start of debugging ***
    %{
    fprintf('[WARN]: PILOT_REPEAT_CNT is manually reset -> (debugging?)\n');
    PILOT_REPEAT_CNT = 8; 
    %}
    % *** end of debugging ***
    
    PILOT_REPEAT_DIFF = 1000;
    
    %DEBUG_SHOW = 1;
    
    
    signal = signal(:, PILOT_SEARCH_CH_IDXS);
    con = abs(convn(signal, pilot(end:-1:1), 'same'));
    %con = abs(convn(signal, pilot(end:-1:1)));
    
    % TODO: normalization?
    
    conMeans = mean(con);
    conStds = std(con);
    %thres = conMeans + 10*conStds; % work well for note4
    
    %thres = conMeans + 12*conStds; % *** for iphone ***
    %thres = conMeans + 16*conStds; % **** only for note 4 ***
    
    
    % good setting for note4/nexus6p/and iphone
    thres = conMeans + 14*conStds; % *** for iphone 50% volume placed at table, ex: noise test ***
    

    % search peaks
    pilotMatches = 1;
    pilotDiffers = cell(PILOT_SEARCH_CH_CNT);
    for chUsedIdx = 1:PILOT_SEARCH_CH_CNT,
        validPeakIdxs{chUsedIdx} = LibGetValidPeaks( con(:,chUsedIdx), thres(:,chUsedIdx),  PILOT_SEARCH_PEAK_WINDOW, 0);
        
        pilotDiffers = validPeakIdxs{chUsedIdx}(2:end) - validPeakIdxs{chUsedIdx}(1:end-1);
        
        % check pilot length
        if length(validPeakIdxs{chUsedIdx})~=PILOT_REPEAT_CNT,
            fprintf('[WARN]: pilot repeat cnt not matches\n');
            pilotMatches = 0;
        end
        
        % check if pilot diff matchs // stric mode
        %{
        if ~all(pilotDiffers == PILOT_REPEAT_DIFF),
            pilotDiffers
            fprintf('[WARN]: pilot repeat diff not matches\n');
            pilotMatches = 0;
        end
        %}
        
        fprintf('[WARN]: loss mode to find pilot is used, only looking for mode diff \n');
        pilotDiffers
        if ~sum(pilotDiffers == PILOT_REPEAT_DIFF)>5, % lose mode
            pilotDiffers
            fprintf('[WARN]: pilot repeat diff not matches\n');
            pilotMatches = 0;
        end
        
        % dump debug figures if necessary
        if pilotMatches ~= 1 || DEBUG_SHOW,
            figure;
            chIdx = PILOT_SEARCH_CH_IDXS(chUsedIdx);
            conPlot = con(:,chUsedIdx);
            title(sprintf('Pilot search at ch %d', chIdx)); hold on;

            plot(conPlot,'b');
            plot([0,length(conPlot)], [thres(chUsedIdx), thres(chUsedIdx)], '-r', 'linewidth', 2);
            plot([0,length(conPlot)], [conMeans(chUsedIdx), conMeans(chUsedIdx)], '-g', 'linewidth', 2);
            plot([0,length(conPlot)], [conMeans(chUsedIdx)+conStds(chUsedIdx), conMeans(chUsedIdx)+conStds(chUsedIdx)], '-c', 'linewidth', 2); 
            plot(validPeakIdxs{chUsedIdx}, conPlot(validPeakIdxs{chUsedIdx}), 'o', 'linewidth', 2);
            legend('con','thres','mean','mean+std','peaks');
        end
        
    end
    
    
    % make up return results
    if pilotMatches
       pilotEndOffset = validPeakIdxs{chUsedIdx}(end) - floor(length(pilot)/2) + PILOT_REPEAT_DIFF;
    else
       pilotEndOffset = -1;
    end
    
    
    
    % dump pilot info if necessay
    %{
    if DEBUG_SHOW,
        figure;
        for chPlotIdx = 1: PILOT_SEARCH_CH_CNT,
            chIdx = PILOT_SEARCH_CH_IDXS(chPlotIdx);
            conPlot = con(:, chPlotIdx);
            
            subplot(PILOT_SEARCH_CH_CNT, 1, chPlotIdx); title(sprintf('Pilot search at ch %d', chIdx)); hold on;
            
            plot(conPlot,'b');
            plot([0,length(conPlot)], [thres(chPlotIdx), thres(chPlotIdx)], '-r', 'linewidth', 2);
            plot([0,length(conPlot)], [conMeans(chPlotIdx), conMeans(chPlotIdx)], '-g', 'linewidth', 2);
            plot([0,length(conPlot)], [conMeans(chPlotIdx)+conStds(chPlotIdx), conMeans(chPlotIdx)+conStds(chPlotIdx)], '-c', 'linewidth', 2);
            
            if chPlotIdx == 1,
                legend('con','thres','mean','mean+std');
            end
        end
        
    end
    %}
    

end

