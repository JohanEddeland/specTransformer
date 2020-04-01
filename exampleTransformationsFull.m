% This script generates .stl files for the specifications in the folder
% 'examples'


% The models has two constants that we need to set
% omega_bar = 4500;
% v_bar = 120;

% Get all the requirements to generate STL formulas for
allSimulinkSpecifications = dir('examples/*.slx');
addpath('examples');

for specCounter = 1:numel(allSimulinkSpecifications)
    % Get the current specification name (remove .slx from the file name)
    thisSpec = strrep(allSimulinkSpecifications(specCounter).name, '.slx', '');
    
    % Create the specTransformer object
    modelName = thisSpec;
    reqName = thisSpec;
    directoryToSaveIn = 'examples';
    dt = 0.001; % Step time needs to be included in case of delay blocks
    
    obj = specTransformer(modelName, reqName, directoryToSaveIn, dt);
    
    % Before transforming, we need to define start time and end time for the
    % requirement
    % For example, if we want alw_[0, 10](req), startTime is 0 and endTime is
    % 10.
    obj.startTime = 0;
    obj.endTime = 10;
    obj.createSubRequirements = 0;
    
    % We also need to say what requirement TYPE it is
    % This can be either "safety" or "none"
    % "safety" will simply add an "always" around the whole formula afterwards
    obj.specType = 'safety';
    
    % Transform the requirement into STL
    obj.requirementToSTL();
end


