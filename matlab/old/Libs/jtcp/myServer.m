%==========================================================================
% 2015/08/25: server to received data from phones
%==========================================================================
%cleanupObj = onCleanup(@cleanMeUp);

%--------------------------------------------------------------------------
% SHOW_ANIMATION = 1 : update the received byte array to a figure
%--------------------------------------------------------------------------
SHOW_ANIMATION = 1;
FIG_Y_RANGE = [0,255];
FIG_X_SIZE = 1000; % *** need to meet the setting in remote app


if SHOW_ANIMATION == 1,
    h_f = figure;
    h_p = plot(zeros(FIG_X_SIZE,1),zeros(FIG_X_SIZE,1),'-ro');
    ylim(FIG_Y_RANGE);
end


%ACTION_INIT format: | ACTION_INIT | xxx parater setting 
ACTION_INIT = 1;	
%ACTION_SEND format: | ACTION_SEND | # of bytes to send | byte[] | -1 
ACTION_SEND = 2;
% ACTION_CLOSE format: | ACTION_CLOSE |
ACTION_CLOSE = -1;


% add helper java class path if need
HELPER_CLASS_PATH = '/Users/eddyxd/Downloads/jtcp/jtcp/tcp_helper' % just for MAC
USE_HELPER_CLASS = 1;
if USE_HELPER_CLASS,
    % Use of the helper class has been specified, but the class has
    % to be on the java class path to be useable.
    dynamicJavaClassPath = javaclasspath('-dynamic');

    % Add the helper class path if it isn't already there.
    if ~ismember(HELPER_CLASS_PATH,dynamicJavaClassPath)
        javaaddpath(HELPER_CLASS_PATH);

        % javaaddpath issues a warning rather than an error if it
        % fails, so can't use try/catch here. Test again to see if
        % helper path added.
        dynamicJavaClassPath = javaclasspath('-dynamic');

        if ~ismember(HELPER_CLASS_PATH,dynamicJavaClassPath)
            warning('jtcp:helperClassNotFound',[mfilename '.m--Unable to add Java helper class; reverting to byte-by-byte (slow) algorithm.']);
            USE_HELPER_CLASS = false;
        end % if
    end % if
end % if


action = zeros(1, 1, 'int8'); % init valuegoogle


% show network interface
[status,result]=system('ifconfig en0 inet')
SERVER_PORT = 50006

% wait for the first connection
jTcpObj = jtcp('accept',SERVER_PORT,'timeout',5000,'serialize',false);


%gBuf = zeros(1000000,1); % global buffer
%gBufEndIdx = -1;
%gBufStartIdx = -1;

dotCnt = 0;
for i = 1:100000,
    numBytesAvailable = jTcpObj.socketInputStream.available;
    fprintf('.'); % plot dot for user interface
    dotCnt = dotCnt + 1;
    if dotCnt >= 80, % switch dot to a new line
        fprintf('\n');
        dotCnt = 0;
    end
    
    if numBytesAvailable > 0,
        fprintf('\n');
        action = jTcpObj.inputStream.readByte

        if action == ACTION_INIT,
            fprintf('Socket is initilized and system setting is read from app\n');
        elseif action == ACTION_SEND,
            fprintf('Going to read xxx data\n');
            
            temp = jTcpObj.socketInputStream.available
            byteToRead = jTcpObj.inputStream.readInt
            
            buf = zeros(1, byteToRead, 'int8');
            
            
            if USE_HELPER_CLASS,
                % good raeding method (using helper class)
                
                xCnt = 0;
                byteReadNow = jTcpObj.socketInputStream.available
                while byteReadNow < byteToRead, % busy wait until enough byte is avaialble
                    byteReadNow = jTcpObj.socketInputStream.available;
                    pause(0.01);
                    
                    fprintf('x'); % plot x for user interface
                    xCnt = dotCnt + 1;
                    if xCnt >= 80, % switch dot to a new line
                        fprintf('\n');
                        xCnt = 0;
                    end
                end
                
                

                % Read incoming message using efficient single function call.
                data_reader = DataReader(jTcpObj.inputStream);
                temp = data_reader.readBuffer(byteToRead);
                temp = temp(:)';
                
                buf = temp;

            else
                % bad reading method
                for i = 1:byteToRead,
                    buf(i) = jTcpObj.inputStream.readByte;
                end
            end
            
            check = jTcpObj.inputStream.readByte
            assert(check == -1, '[ERROR]: wrong represetation of message send (size inconsistence?)');
            
            % update figure if necessary
            if SHOW_ANIMATION == 1,
                y = buf;
                x = 1:length(y);
                set(h_p, 'XData', x, 'YData', y);
            end
            
            %mssg = jtcp('read',jTcpObj); disp(mssg);
        elseif action == ACTION_CLOSE,
            fprintf('[WARN]: socket is closed remotely\n');
            break;
        else
            fprintf('[ERROR]: undefined action=%d\n',action);
            break;
        end
    end
    
    %mssg = jtcp('read',jTcpObj); disp(mssg);
    pause(0.1);
end

jtcp('close',jTcpObj);
