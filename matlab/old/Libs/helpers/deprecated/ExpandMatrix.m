function [ B ] = ExpandMatrix( A, n )
% 2014/11/25: function to expand matrix by block
%A=[1 2 3;4 5 6]; % sample data
    B=num2cell(A);
    B=cellfun(@(x) repmat(x,n,n), B, 'UniformOutput', false); 
    % note: arguments to repmat determine block size
    B=cell2mat(B);
end

