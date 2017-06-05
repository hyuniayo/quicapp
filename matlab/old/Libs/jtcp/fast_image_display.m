function M=fast_image_display(M)

if nargin==0
  M=rand(256,256,30);
end

ind=1;
first_time_through=1;
f=figure;
sz_a=size(M);
tic;
for ind=1:sz_a(end)
  if ind==1,
        set(f,'doublebuffer','on');
        him = imagesc('cdata', M(:,:,ind));
        colormap('gray');
        set(gca,'drawmode','fast');
        set(him,'erasemode','none');
        first_time_through=0;
        axis image; axis tight; axis ij; % Small framerate losses
   else
      set(him,'cdata', M(:,:,ind));
   end
  drawnow;
end
tm=toc;
fprintf(['Effective frame rate: ',num2str(sz_a(end)/tm)]);

return