function [ buf ] = MyWaitAndRead( jTcpObj, byteToRead)
% 2015/08/26 implement the wait and read behavior
% WARN: *** need to set up the correct java helper path before use it ***
    xCnt = 0;
    byteReadNow = jTcpObj.socketInputStream.available
    while byteReadNow < byteToRead, % busy wait until enough byte is avaialble
        byteReadNow = jTcpObj.socketInputStream.available;
        pause(0.01);

        fprintf('x'); % plot x for user interface
        xCnt = xCnt + 1;
        if xCnt >= 80, % switch dot to a new line
            fprintf('\n');
            xCnt = 0;
        end
    end
    
    % Read incoming message using efficient single function call.
    data_reader = DataReader(jTcpObj.inputStream);
    temp = data_reader.readBuffer(byteToRead);
    temp = temp(:);

    buf = temp;
end

