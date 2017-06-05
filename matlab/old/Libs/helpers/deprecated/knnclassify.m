function [ Class ] = knnclassify( Sample, Training, Group, k )
% 2015/02/23: my own version of knnclassify
[trainRow, trainCol] = size(Training);
[sampleRow, sampleCol] = size(Sample);

Class = zeros(sampleRow, 1);

for i = 1:sampleRow, 
    dis = sum((Training - repmat(Sample(i, :), trainRow, 1)).^2, 2);
    [sortValue, sortIdx] = sort(dis);
    
    Class(i) = mode(Group(sortIdx(1:k))); 
end


end

