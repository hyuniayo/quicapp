function [ fSensor ] = CurrentToExForce( currents ) % input should be in amper
    if ~exist('currents','var'),
        %currents = [8:100:5000]*10^-6; % uA level
        currents = [500:500:5000]*10^-6; % for vibration test
        DEBUG_SHOW = 1;
        %currents = [0.03, 0.22, 0.45, 0.64, 1, 1.22, 1.33, 1.56, 1.64]*10^-3;% apple touch data (0.1:0.1:1.0)
    else
        DEBUG_SHOW = 0;
    end

    R_FIX = 330; % omu
    V_IN = 3.7; % V
    
    rSensor = (V_IN./currents) - R_FIX

    R_Y = [30, 10, 6, 3.5, 2, 1.1, 0.8, 0.45, 0.3, 0.2]; % kOmu
    % NOTE: this needs additoanl calibration
    F_X = [20, 50, 100, 250, 500, 1000, 2000, 4000, 7000, 10000].*0.9 % g
    
    ftor = regress(log10(R_Y)',[ones(length(F_X),1),log10(F_X)']);
    rtof = regress(log10(F_X)',[ones(length(R_Y),1),log10(R_Y)']);
    
    %{
    figure;
    loglog(F_X, R_Y);
    grid on;
    figure;
    loglog(F_X, 10.^(log10(F_X)'.*ftor(2)+ftor(1)),'ro');
    grid on;
    figure;
    loglog(10.^(log10(R_Y)'.*rtof(2)+rtof(1)), R_Y,'bo');
    grid on;
    %}
    
    fSensor = 10.^(log10(rSensor./1000).*rtof(2)+rtof(1));
    if DEBUG_SHOW,
        figure;
        plot(currents, fSensor,'-o');
        %appleForce = [0.2:0.1:1.0];
        %plot(appleForce, fSensor);
        xlabel('A'); ylabel('g');
    end

end

