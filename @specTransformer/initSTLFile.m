function initSTLFile(obj)

% Init .stl-file
obj.fileName = [obj.resultsFolder '/' obj.requirement '.stl'];
obj.fileID = fopen(obj.fileName,'wt');

% Write top information about file
fprintf(obj.fileID, '# Automatically generated STL formula\n');
fprintf(obj.fileID, ['# Model: ' obj.model '\n']);
fprintf(obj.fileID, ['# Requirement: ' obj.requirement '\n']);
fprintf(obj.fileID, '# Author: Johan Lidén Eddeland\n\n');

% Initialize other parts of the file
% The .stl-file has 3 main parts: Parameters, skipped systems, and formulas

obj.paramString = ['# Parameters\nparam t_init = ' ...
    num2str(obj.startTime) ', t_final = ' ...
    num2str(obj.endTime) ', '];
obj.formulaString = [];

obj.paramString = [obj.paramString 'dt = ' num2str(obj.compiledSampleTime) ', '];
end