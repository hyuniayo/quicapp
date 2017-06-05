function [ vString ] = LibVectorToCppFormat( v, filePath )
    % 2015/11/11: this fucntions make ad-hoc transfer from matlab vector to
    %             c++ vector format

    vString = '{';
    for i = 1:length(v),
        vString = sprintf('%s%E',vString,v(i));
        
        if i == length(v),
            vString = strcat(vString,'};');
        else
            vString = strcat(vString,',');
        end
    end
end

