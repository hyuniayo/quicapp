function mat2libsvm(X, y, fname) 
%MAT2LIBSVM write matlab variables X and y to LIBSVM training data file
%
% usage: mat2libsvm(X, y, fname)

% Copyleft 2003 Thomas Philip Runarsson (26/3)

[ell n] = size(X);
if (ell ~= length(y(:)))
  error('fault the length of y must be the same as the number of rows in X');
end
fid = fopen(fname,'wt');
if fid == -1,
  error(sprintf('fault: could not write to file %s',fname));
end
disp(sprintf('writing file %s, please wait ...', fname));
for i = 1:ell,
  string = num2str(y(i)) ; % sprintf('%f', double(y(i)));
  for j = 1:n,
    if X(i,j)~=0,
      string = [string ' ' num2str(j) ':' num2str(double(X(i,j)))];
    end
  end
  fprintf(fid,'%s\n',string);
end
disp('done writing file!');
fclose(fid);
