function [ h_f ] = PlotConfusionMatrix( confuseMatrix, xticksToShow, yticksToShow, xLabelEnd, yLabelEnd, rotateDegree )
% 2014/11/23: this is a helper function to plot confusion matrix
    %xticksToShow = {'0cm','1cm','2cm','3cm','4cm','5cm','6cm','7cm','8cm','9cm','10cm'};

    [N_Y, N_X] = size(confuseMatrix);

    SCALE_UP_SIZE = 100;

    confuseMatrixExpanded = ExpandMatrix(confuseMatrix, SCALE_UP_SIZE);

    h_f = figure;
    plot_config;
    f = 1.1;
    set(gcf, 'PaperPosition', [0 0 6*f 5*f],'PaperSize', [6*f 5*f]); 
    %set(0,'DefaultAxesFontSize',16,'DefaultTextFontSize',16);
    colormap(flipud(gray));
    %colormap(flipud(hot));
    imagesc(confuseMatrixExpanded);

    offset = SCALE_UP_SIZE/2;
    set(gca, 'XTick', 1+offset:SCALE_UP_SIZE:(N_X)*SCALE_UP_SIZE+offset);
    set(gca, 'XTickLabel', xticksToShow);
    set(gca, 'YTick', 1+offset:SCALE_UP_SIZE:(N_Y)*SCALE_UP_SIZE+offset);
    set(gca, 'YTickLabel', yticksToShow);
    
    xlabel(sprintf('Predict locations %s', xLabelEnd));
    ylabel(sprintf('Actual locations %s', yLabelEnd));
    set(gca,'YDir','normal');
    colorbar;
    
    rotateXLabels(gca, rotateDegree);
    
    
    
    
    %print(h_f,'temp2.pdf','-dpdf','-painters','-r1500'); %<-- a high quality pdf
    print(h_f,'result_heat.pdf','-dpdf','-painters','-r600'); %<-- a high quality pdf
end

