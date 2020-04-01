% This script generates .stl files for the specifications in the folder
% 'examples'

% Get all the requirements to generate STL formulas for
allSimulinkSpecifications = dir('examples/*.slx');
addpath('examples');

% Parameter for the specification
ARCH_AT51_timeHorizon = 2.5;

% Create the specTransformer object
modelName = 'ARCH_AT51_example';
reqName = 'ARCH_AT51_example';
directoryToSaveIn = 'examples';
fixedStepSize; % Step time needs to be included in case of delay blocks

% Create the specTransformer object
obj = specTransformer(modelName, reqName, directoryToSaveIn, fixedStepSize);

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


