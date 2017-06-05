function model = libsvm2mat(fname)
%LIBSVM2MAT LibSVM to MATLAB conversion
% usage:
%        model = libsvm2mat(model_file_name)
% or if you have a data file you would like to load
%        model = libsvm2mat(data_file_name)

% Copyleft 2003 Thomas Philip Runarsson (26/3)
model.Parameters = zeros(5,1);
model.nr_class = -1;
model.totalSV = -1;
model.rho = -1;
model.Label = -1;
model.sv_indices = -1;
model.ProbA = -1;
model.ProbB = -1;
model.nSV = -1;
model.sv_coef = -1;
model.SVs = -1;


fid = fopen(fname,'r');
if (fid == -1), error(sprintf('%s not found!',fname')); end
while 1,
  tline = fgetl(fid);
  if ~ischar(tline), break, end
  I = [findstr(tline,' ') length(tline)+1];  
  switch tline(1:I(1)-1),
    case 'svm_type',
      %model.svm_type = tline((I(1)+1):(I(2)-1));
      model.Parameters(1) = 0;
    case 'kernel_type', 
      %model.kernel_type = tline((I(1)+1):(I(2)-1));
      model.Parameters(2) = 0; 
    case 'degree'
      %model.degree = sscanf(tline(I(1):end),'%f');
      model.Parameters(3) = sscanf(tline(I(1):end),'%f'); 
    case 'gamma'
      %model.gamma = sscanf(tline(I(1):end),'%f');
      model.Parameters(4) = sscanf(tline(I(1):end),'%f');
    case 'probA'
      model.ProbA = sscanf(tline(I(1):end),'%f');
    case 'probB'
      model.ProbB = sscanf(tline(I(1):end),'%f');
    case 'coef0'
      %model.coef0 = sscanf(tline(I(1):end),'%f');
      model.Parameters(5) = sscanf(tline(I(1):end),'%f');
    case 'nr_class',
      model.nr_class = sscanf(tline(I(1):end),'%f');
    case 'nr_sv',
      model.nSV = sscanf(tline(I(1):end),'%f');
    case 'rho',
      model.rho = sscanf(tline(I(1):end),'%f');
      bias = model.rho;
    case 'total_sv',
      model.totalSV = sscanf(tline(I(1):end),'%f');
    case 'label',
      model.Label = sscanf(tline(I(1):end),'%f');
    case 'SV',
      k = 0;
      while 1,
        k = k + 1;
        tline = fgetl(fid);
        if ~ischar(tline), break, end
        tline(find(tline == ':')) = ' ';
        values = sscanf(tline, '%f')';
        model.sv_indices(k,1) = k;
        model.sv_coef(k,:) = values(1:model.nr_class-1);
        model.SVs(k, values(model.nr_class:2:end)) = values((model.nr_class+1):2:end);
      end
      model.SVs = sparse(model.SVs);
      model.sv_coef = sparse(model.sv_coef);
      model.sv_indices = sparse(model.sv_indices);
    otherwise, % assume this to be a data file, double check if its true:
      if isempty(str2num(tline(1:I(1)-1))), 
        disp([tline(1:I(1)-1) ' ignored!']);
      else
        k = 0;
        while 1,
          k = k + 1;
          if ~ischar(tline), break, end
          tline(find(tline == ':')) = ' ';
          values = sscanf(tline, '%f')';
          model.y(k,1) = values(1);
          model.X(k, values(2:2:end)) = values(3:2:end);
          tline = fgetl(fid);    
        end  
      end
  end
end
fclose(fid);
