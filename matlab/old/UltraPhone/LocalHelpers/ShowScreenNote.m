function [ output_args ] = ShowScreenNote( screenSize, points, notes, belowNotes, title )
% 2016/03/31: This plots the screen of phone with proper annotation
    figure; 
    h1 = axes;
    
    PLOT_MARGIN = 20;
    %set(h1, 'YAxisLocation', 'Right');
    %box off;
    % plot frames
    
    
    plot(points(:,1), points(:,2),'o','linewidth',2); hold on;
    for i = 1:length(points),
        str = sprintf('%d:(%d,%d)', i, points(i,1), points(i,2));
        text(points(i,1), points(i,2)-15 ,str,'Color','red','FontSize',14,'Horizontalalignment','center');
        text(points(i,1), points(i,2)+15 ,notes{i},'Color','black','FontSize',14,'Horizontalalignment','center');
    end
    
    hold off;
    
    % adjust back to screen axis dimension
    set(h1, 'Ydir', 'reverse');
    
    xlim([0-PLOT_MARGIN,screenSize(1)+PLOT_MARGIN]);
    ylim([0-PLOT_MARGIN,screenSize(2)+PLOT_MARGIN]);
    
    x0=10;
    y0=10;
    width=screenSize(1);
    height=screenSize(2);
    set(gcf,'units','points','position',[x0,y0,width,height]);
    
end

