function [ fig ] = DrawAudioEstForce(SampledDataOri, SampledDataChange, SampledDataRef, SampledIndxes, SampledExtForces , LOAD_DATA_SAMPLE_PRE_OFFSET, FIG_TITLE, SAVE_TO_FILE_PATH )
% 2016/10/22: draw result of estiamted force for tuning parameter

    

    fig = figure; 
    ha(1) = subplot(4,1,1); hold on; title(FIG_TITLE);
    for codeIdx = 1:max(SampledIndxes),
        mask = (SampledIndxes==codeIdx);
        dataNow = SampledDataOri(mask);
        plot(find(mask), dataNow);
    end

    for codeIdx = 1:max(SampledIndxes),
        mask = find(SampledIndxes==codeIdx);
        start = mask(LOAD_DATA_SAMPLE_PRE_OFFSET);
        plot([start, start], [min(SampledDataOri), max(SampledDataOri)],'k--');
    end

    for codeIdx = 1:max(SampledIndxes),
        mask = find(SampledIndxes==codeIdx);
        plot(mask, SampledDataRef(mask),'k--');
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
        plot(find(mask), dataNow);
    end



    ha(4) = subplot(4,1,4); hold on;
    for codeIdx = 1:max(SampledIndxes),
        mask = (SampledIndxes==codeIdx);
        dataNow = SampledExtForces(mask);
        plot(find(mask), dataNow);
    end
    estCorr = corr(abs(SampledDataChange(:)),SampledExtForces(:));
    xlabel(sprintf('corr = %.3f', estCorr));

    % ref: http://stackoverflow.com/questions/5023085/matlab-how-to-zoom-subplots-together
    linkaxes(ha, 'x');      % Link all axes in x

    saveas(fig, SAVE_TO_FILE_PATH);

end

