function [ m ] = LibCellToMatrix( c, elementDim )
% 2015/10/14: this function convert "1-D" cell array to matrix
%           : padding zeros if need (each cell element has different size)
    assert(size(c,1)==1 || size(c,2)==1, '[ERROR]: LibCellToMatrix only support 1d cell array');
    
    cCnt = length(c);
    % find max size of element
    elementSizes = zeros([elementDim, cCnt]);
    
    for cIdx = 1:cCnt,
        %idxs = repmat({':'}, [elementDim, 1]);
        
        elementSizes(:, cIdx) = size(c{cIdx}); 
    end
    maxSize = max(elementSizes, [], 2);
    
    m = zeros([maxSize', cCnt]);
    for cIdx = 1:cCnt,
        
        idxs = cell(elementDim, 1);
        for i = 1:elementDim,
            idxs{i} = 1:elementSizes(i, cIdx);
        end
        
        m(idxs{:}, cIdx) = c{cIdx};
    end
    
end

