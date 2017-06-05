function [ fig ] = ShowScreenHeat(screenSize, points, values)
% 2016/03/31: This script shows the screen of phones as a heat map
    X_MAX = screenSize(1);
    Y_MAX = screenSize(2);
    POINT_CNT = size(points,1);
    REF_POINT_CNT = POINT_CNT; % number of point to be referenced
    REF_WEIGTH_ORDER = 2;
    
    data = zeros(Y_MAX,X_MAX); % colume-based value

    % process the data to plot (interpolate the points)
    for y = 1:Y_MAX,
        for x = 1:X_MAX,
            dis = sqrt(sum((points - repmat([x,y], [POINT_CNT,1])).^2, 2));
            [disSorted, disSortedIdxs] = sort(dis);
            
            if disSorted(1) <= 0, % same point
                data(y,x) = values(disSortedIdxs(1));
            else
                refValues = values(disSortedIdxs(1:REF_POINT_CNT));
                refDises = disSorted(1:REF_POINT_CNT);
                
                refWeights = (1./refDises).^REF_WEIGTH_ORDER;
                refWeights = refWeights./sum(refWeights);
                
                data(y,x) = refValues'*refWeights;
            end
        end
    end
    
    % plot results
    fig = figure;
    imagesc(data);
    colormap('gray');
    colorbar;
    
end

