function [ result ] = FuncSoundToShortForC(sound, name)
% 2016/05/20: This function turns the -1, +1 to a short based string
    if ~exist('name','var'),
        name = 'temp';
    end

    result = sprintf('short %s[] = {', name);
    for i = 1:length(sound),
        result = sprintf('%s%d', result, sound(i));
        if i<length(sound),
            result = strcat(result,',');
        end
    end
    result = strcat(result,'};');
end

