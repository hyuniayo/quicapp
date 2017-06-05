function [  ] = ShowHeat( data, xLabels, labelY, showTitle)
% This is the function to show freq heat maps
    figure;
    colormap('hot');
    imagesc(data);
    colorbar;
    title(showTitle);
    
    xToShow = 5;
    
    set(gca,'YDir','normal'); % make y starts from bottom
    
    
    xticks = linspace(1, length(xLabels), xToShow);
    
    set(gca, 'XTick', xticks, 'XTickLabel', linspace(floor(xLabels(1)), floor(xLabels(end)), xToShow));
    
    set(gca, 'YTick', labelY);
    %set(gca, 'YTickLabel', linspace(min(rangeY),max(rangeY),TICK_SHOW))

end

