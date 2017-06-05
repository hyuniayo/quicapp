function [ SampledDataOri, SampledDataChange, SampledDataRef, SampledDataRefFixed, estCorr, estCorrFixed ] = AudioForceEstimateForAndroid(SampledDataAll, SampledIndxes, LOAD_DATA_SAMPLE_PRE_OFFSET, EST_DETECT_SAMPLE_RANGE, EST_CH_IDX, EST_REF_RANGE, SampledExtForces, figTitle, figSavePath)
% 2016/10/16: This one is used to estimate forces
    if ~exist('SampledDataAll','var'),
        LOAD_DETECT_SAMPLE_RANGE = [595-5:605+5];
        LOAD_CH_IDXS = [1:2];
        LOAD_DATA_SAMPLE_PRE_OFFSET = 10;
        %TRACE_PATH = 'Traces/Nexus6pForceCalib/AudioAna_p1_inhand_1_2_0/DebugOutput/'
        TRACE_PATH = 'Traces/Nexus6pForceCalib/AudioAna_p1_onpaper_3_4_0/DebugOutput/'
        
        [SampledDataAll, SampledExtForces, SampledIndxes, SampledDataStamps, SampledOffsets] = AudioParseForAndroidPressureCorrectWithExternalSensors(TRACE_PATH, [], LOAD_DETECT_SAMPLE_RANGE, LOAD_CH_IDXS, LOAD_DATA_SAMPLE_PRE_OFFSET);
        
        EST_DETECT_SAMPLE_RANGE = [8:18]; % this setting need to be based on LOAD_DETECT_SAMPLE_RANGE -> real selected range is LOAD_DETECT_SAMPLE_RANGE(EST_DETECT_SAMPLE_RANGE)
        %EST_DETECT_SAMPLE_RANGE = [13:20]; % this setting need to be based on LOAD_DETECT_SAMPLE_RANGE -> real selected range is LOAD_DETECT_SAMPLE_RANGE(EST_DETECT_SAMPLE_RANGE)
        EST_CH_IDX = 2;
        %EST_REF_RANGE = [-5:20]; % this seeting need to be based on LOAD_DATA_SAMPLE_PRE_OFFSET -> min(EST_REF_RANGE) <= LOAD_DATA_SAMPLE_PRE_OFFSET
        %EST_REF_RANGE = [15:20]; % this seeting need to be based on LOAD_DATA_SAMPLE_PRE_OFFSET -> min(EST_REF_RANGE) <= LOAD_DATA_SAMPLE_PRE_OFFSET
        EST_REF_RANGE = [-5:0]; % this seeting need to be based on LOAD_DATA_SAMPLE_PRE_OFFSET -> min(EST_REF_RANGE) <= LOAD_DATA_SAMPLE_PRE_OFFSET
        
        figTitle = 'debug';
        
        DEBUG_SHOW = 1;
    end
    if exist('figTitle', 'var'),
        DEBUG_SHOW = 1; % means to plot figure in the end
    end

    SampledDataOri = squeeze(sum(SampledDataAll(EST_DETECT_SAMPLE_RANGE,:,EST_CH_IDX), 1));
    SampledDataRef = zeros(size(SampledDataOri));
    SampledDataRefFixed = zeros(size(SampledDataOri));
    SampledDataChange = zeros(size(SampledDataOri));
    SampledDataGodown = zeros(size(SampledDataOri));
    SampledDataBigchange = zeros(size(SampledDataOri));
    for codeIdx = 1:max(SampledIndxes),
        mask = find(SampledIndxes==codeIdx);
        
        dataNow = SampledDataOri(mask);
        refRange = LOAD_DATA_SAMPLE_PRE_OFFSET+EST_REF_RANGE;
        %ref = mean(dataNow(LOAD_DATA_SAMPLE_PRE_OFFSET+EST_REF_RANGE));
        %{
        
        ref = max(dataNow(refRange(refRange<length(dataNow))));
        if isempty(ref),
            ref = dataNow(1); % dummy point for too short period touch
        end
        %}
        [ref] = AudioEstimateRef(dataNow, refRange);
        
        %DEBUG_GODOWN_SEARCH_RANGE = LOAD_DATA_SAMPLE_PRE_OFFSET+[1:10];
        %[~, godown] = AudioEstimateRef(dataNow, DEBUG_GODOWN_SEARCH_RANGE); fprintf('[WARN]: DEBUG_GODOWN_SEARCH_RANGE is used\n');
        
        
        DEBUG_BIGCHANGE_SEARCH_RANGE = LOAD_DATA_SAMPLE_PRE_OFFSET+[1:9];
        DEBUG_BIGCHANGE_THRES = 0.2;
        [bigchange, godown] = AudioForceBigChangeDetector(dataNow, ref, DEBUG_BIGCHANGE_SEARCH_RANGE, DEBUG_BIGCHANGE_THRES);
        
        if bigchange == 1,
            DEBUG_REFFIXED_SEARCH_RANGE = LOAD_DATA_SAMPLE_PRE_OFFSET+[3:10];
            refFixed = AudioEstimateRef(dataNow, DEBUG_REFFIXED_SEARCH_RANGE, godown);
        else
            refFixed = ref;
        end
        
        SampledDataBigchange(mask) = bigchange;
        SampledDataGodown(mask) = godown;
        SampledDataRef(mask) = ref;
        SampledDataRefFixed(mask) = refFixed;
        %SampledDataChange(mask(LOAD_DATA_SAMPLE_PRE_OFFSET:end)) = SampledDataOri(mask(LOAD_DATA_SAMPLE_PRE_OFFSET:end))-ref;
        SampledDataChange(mask) = SampledDataOri(mask)-ref;
    end
    
    if exist('SampledExtForces', 'var'),
        estCorr = corr(abs(SampledDataChange(:)),SampledExtForces(:));
        estCorrFixed = corr(abs(SampledDataOri(:)-SampledDataRefFixed(:)),SampledExtForces(:));
    else
        estCorr = -1;
        estCorrFixed = -1;
    end
    
    
    if exist('DEBUG_SHOW','var') && DEBUG_SHOW == 1,
        fig = figure; 
        ha(1) = subplot(4,1,1); hold on; title(figTitle); 
        for codeIdx = 1:max(SampledIndxes),
            mask = find(SampledIndxes==codeIdx);
            dataNow = SampledDataOri(mask);
            
            
            xlabel('yellow = godown, cyan = goup, no color = no big change');
            godown = SampledDataGodown(mask);
            fillx = [mask(1), mask(1), mask(end), mask(end)];
            filly = [min(SampledDataOri), max(SampledDataOri), max(SampledDataOri), min(SampledDataOri)];
            if all(godown == 1),    
                fill(fillx, filly, 'y');
            elseif all(godown == -1),
                fill(fillx, filly, 'c');
            else
                %fprintf('[ERROR]: undefined godown tag = %d\n'+godown(1));
            end
            
            
            %{
            xlabel('yellow = bigchange');
            bigchange = SampledDataBigchange(mask);
            fillx = [mask(1), mask(1), mask(end), mask(end)];
            filly = [min(SampledDataOri), max(SampledDataOri), max(SampledDataOri), min(SampledDataOri)];
            if all(bigchange == 1),    
                fill(fillx, filly, 'y');
            end
            %}
            
            plot(mask, dataNow);
        end
        
        
        for codeIdx = 1:max(SampledIndxes),
            mask = find(SampledIndxes==codeIdx);
            start = mask(LOAD_DATA_SAMPLE_PRE_OFFSET);
            plot([start, start], [min(SampledDataOri), max(SampledDataOri)],'k--');
        end
        
        for codeIdx = 1:max(SampledIndxes),
            mask = find(SampledIndxes==codeIdx);
            plot(mask, SampledDataRef(mask),'k--');
            
            plot(mask, SampledDataRefFixed(mask),'r--');
        end
        
        
        ha(2) = subplot(4,1,2); hold on; grid on;
        for codeIdx = 1:max(SampledIndxes),
            mask = find(SampledIndxes==codeIdx);
            dataNow = SampledDataOri(mask);
            d1 = diff(dataNow);
            d2 = diff(d1);
            plot(mask(1+1:end), d1, 'b-');
            plot(mask(1+2:end), d2, 'r--');
            legend('d1','d2');
        end
        
        ha(3) = subplot(4,1,3); hold on;
        for codeIdx = 1:max(SampledIndxes),
            mask = (SampledIndxes==codeIdx);
            dataNow = abs(SampledDataChange(mask));
            refNow = SampledDataRef(mask);
            plot(find(mask), dataNow./refNow);
        end
        
        plot(abs(SampledDataOri-SampledDataRefFixed)./SampledDataRef, 'k.');
        
        
        
        
        ha(4) = subplot(4,1,4); hold on;
        for codeIdx = 1:max(SampledIndxes),
            mask = (SampledIndxes==codeIdx);
            dataNow = SampledExtForces(mask);
            plot(find(mask), dataNow);
        end
        
        xlabel(sprintf('corr = %.3f, corrFixed = %.3f', estCorr, estCorrFixed));
        
        % ref: http://stackoverflow.com/questions/5023085/matlab-how-to-zoom-subplots-together
        linkaxes(ha, 'x');      % Link all axes in x
        
        if exist('figSavePath','var'),
            saveas(fig, figSavePath);
        end
    end
    
    
    
    
end

