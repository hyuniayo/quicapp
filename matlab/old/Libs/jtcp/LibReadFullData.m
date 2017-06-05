function [ data ] = LibReadFullData(jTcpObj, DEBUG_SHOW)
% 2015/10/18: This is the helper function to read my customized packet
%       NOTE: Pakcet format = | # of bytes to send (int) | byte[] | -1 
    if ~exist('DEBUG_SHOW'),
        DEBUG_SHOW = 1;
    end

    % a. check how many byte should read
    byteToRead = jTcpObj.inputStream.readInt;
    
    % wait until enough pkacket is received
    xCnt = 0;
    byteReadNow = jTcpObj.socketInputStream.available;
    while byteReadNow < byteToRead, % busy wait until enough byte is avaialble
        byteReadNow = jTcpObj.socketInputStream.available;
        pause(0.0001);
        
        % update some GUI if necessary
        if DEBUG_SHOW,
            fprintf('x'); % plot x for user interface
            xCnt = xCnt + 1;    
            if xCnt >= 80, % switch dot to a new line
                fprintf('\n');
                xCnt = 0;
            end
        end
    end

    % read incoming message using efficient helper
    data_reader = DataReader(jTcpObj.inputStream);
    temp = data_reader.readBuffer(byteToRead);
    temp = temp(:)';
    data = zeros(1, byteToRead, 'int8');
    data = temp;

    
    % check if data format is correct -> end with -1
    check = jTcpObj.inputStream.readByte;
    assert(check == -1, '[ERROR]: wrong represetation of message send (size inconsistence?)');
    
end

