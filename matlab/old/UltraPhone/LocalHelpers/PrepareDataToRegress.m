function [ dataPrepared ] = PrepareDataToRegress( data, orders )
% 2015/12/06: this function converts single-colume vec to regress ordered
    assert(size(data,2) == 1, '[ERORR]: only suppport single-colume vector as data\n');
    
    DATA_CNT = size(data,1);
    ORDER_CNT = length(orders);
    
    dataPrepared = zeros(DATA_CNT, ORDER_CNT);
    
    for orderIdx = 1:ORDER_CNT,
        dataPrepared(:, orderIdx) = data.^orders(orderIdx);
    end

end

