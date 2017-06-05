h = plot(NaN,NaN); %// initiallize plot. Get a handle to graphic object
x = 0:0.01:2;
DATASET1 = sin(x);
DATASET2 = cos(x);
axis([min(DATASET1) max(DATASET1) min(DATASET2) max(DATASET2)]); %// freeze axes
%// to their final size, to prevent Matlab from rescaling them dynamically 
for ii = 1:length(DATASET1)
    pause(0.01)
    set(h, 'XData', DATASET1(1:ii), 'YData', DATASET2(1:ii));
    drawnow %// you can probably remove this line, as pause already calls drawnow
end