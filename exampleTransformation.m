% This script generates an .stl file for the requirement model example1.slx

% The model has one output (specification): req

% The model has two constants that we need to set
omega_bar = 4500;
v_bar = 120;

% Create the specTransformer object
modelName = 'example1';
reqName = 'req';
directoryToSaveIn = pwd;
dt = 0.1; % Step time needs to be included in case of delay blocks

obj = specTransformer(modelName, reqName, directoryToSaveIn, dt);

% Before transforming, we need to define start time and end time for the
% requirement
% For example, if we want alw_[0, 10](req), startTime is 0 and endTime is
% 10. 
obj.startTime = 0;
obj.endTime = 10;

% We also need to say what requirement TYPE it is
% This can be either "safety" or "none"
% "safety" will simply add an "always" around the whole formula afterwards
obj.specType = 'safety';

% Transform the requirement into STL
obj.requirementToSTL();