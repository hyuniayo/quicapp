function [ name, value, evalString ] = LibReadSetAction(jTcpObj)
% 2015/10/16: This reads the set commands details
    % Supported type for ACTION_SET
    SET_TYPE_BYTE_ARRAY = 1;
    SET_TYPE_STRING = 2;
    SET_TYPE_DOUBLE = 3;
    SET_TYPE_INT = 4;
    SET_TYPE_VALUE_STRING = 5;


    % read data from socket
    
    % just for debug
    setType = jTcpObj.inputStream.readInt;
    nameBytes = LibReadFullData(jTcpObj);
    valueBytes = LibReadFullData(jTcpObj);

    
    % convert format 
    name = native2unicode(nameBytes);
    
    
    
    switch setType,
        case SET_TYPE_STRING,
            value = native2unicode(valueBytes);
            evalString = sprintf('%s = ''%s'';', name, value);
        case SET_TYPE_INT, %int 32
            value = valueBytes(end:-1:1);
            value = typecast(value, 'INT32');
            evalString = sprintf('%s = %d;', name, value);
        case SET_TYPE_VALUE_STRING,
            value = str2double(native2unicode(valueBytes));
            evalString = sprintf('%s = %s;', name, native2unicode(valueBytes));
        otherwise
            fprintf('[ERROR]: undefined setType = %s', setType);
    end
    %fprintf('LibReadSetAction: (name, setType, value) = (%s, %d, %s) ')

end

