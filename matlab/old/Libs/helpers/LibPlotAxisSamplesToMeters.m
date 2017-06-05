function [  ] = LibPlotAxisSamplesToMeters( ax, SOUND_SPEED, FS, opt )
    % WARN: this is deprecated -> plot result is hard to read!

    if ~exist('opt','var'),
        opt = 'x'; % defaut operation is changing x-axis label
    end
       
    
    if strcmp(opt, 'x'),
        tickSamples = get(ax,'xtick');
        tickLabelMeters = LibSamplesToMeters(tickSamples, SOUND_SPEED, FS);
        set(ax,'xticklabel', tickLabelMeters);
    else
        fprintf('[ERROR]: unsupport opt = %s', opt);
    end

end

