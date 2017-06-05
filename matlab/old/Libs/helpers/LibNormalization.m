function [ sNormalized ] = LibNormalization( s , opt, dim)
% 2015/10/05: colume-based normalization
    DEFAULT_OPT = 'max';
    DEFAULT_DIM = 1; % means "along" dimension 2
    
    if ~exist('opt','var'),
        opt = DEFAULT_OPT;
    end
    
    if ~exist('dim','var'),
        dim = DEFAULT_DIM;
    end
    assert(length(size(s)) <=2 && dim<=2, '[ERROR]: only support colume or row-based normalization')
    if size(s,1)==1 || size(s,2) == 1,
        s = s(:); % turn to colume-based vector
    end
    
    
    if strcmp(opt, 'max'), % Normalized by the max value
        %ws = max(s, [], abs(3-dim));
        ws = max(s, [], dim);        
    elseif strcmp(opt, 'norm2'), % normalized by energy
        ws = sqrt(sum(s.^2, dim))
    else
        fprintf('[ERROR]: unsupported opt = %s\n', opt);
    end
   
    if dim == 1,
        ws = repmat(ws, [size(s, 1), 1]);
    else
        ws = repmat(ws, [1, size(s,2)]);
    end
    
    sNormalized = s./ws;
    
end

