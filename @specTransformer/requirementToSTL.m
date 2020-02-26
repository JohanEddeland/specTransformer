function requirementToSTL(obj)
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here

reqVisited = {};

disp(['*** Starting ' obj.requirement '.stl ***']);

% Prepare the requirement subsystem for parsing
outports = prepareSystemForParsing(obj, obj.requirement);
nOutports = length(outports);

for outportCounter = 1:nOutports
    component = get_param(outports(outportCounter),'Handle');
    component = component{1};
    
    IndexC = strfind(reqVisited, get(component,'Name'));
    if find(not(cellfun('isempty', IndexC)))
        % The requirement has already been created!
        break;
    else
        % Now, we have visited it!
        reqVisited{end+1} = get(component,'Name');
    end
    
    obj.initSTLFile();
    obj.parseOutputToSTL(component);

end

formulaLength = obj.getTotalFormulaLength();
disp(['*** Finished ' obj.requirement '.stl (' num2str(formulaLength) ' chars) ***']);

% For the last outport of the requirement, log ALL signals
%logAllSignals(obj, component);

% Save the model to the slx-directory
save_system([obj.model '.slx']);

close_system([obj.model '.slx']);

end

function outports = prepareSystemForParsing(obj, requirement)
%FINDREQUIREMENTSSUBSYSTEM Finds the subsystem for given requirement
%   Detailed explanation goes here

% Find Requirements SubSystem

mdl = load_system(obj.model);
thisOutport = find_system(mdl, 'SearchDepth', 1, 'BlockType', 'Outport', 'Name', requirement);
thisParent = get_param(thisOutport, 'Parent');

% First, clear all the line names in the system
lh=find_system(thisParent, 'FindAll', 'on', 'LookUnderMasks','On','FollowLinks','On','type', 'line');
for i_lh=1:length(lh)
    tmpHan = get_param(lh(i_lh),'Handle');
    currentName = get_param(lh(i_lh),'Name');
    if (isempty(strfind(currentName,'<')) && ~get(tmpHan,'DataLogging')) || ...
            ~isempty(strfind(currentName, 'sub'))
        % The signal is not a bus signal and it is not being logged -
        % we should clear the signal name
        set_param(lh(i_lh),'Name','');
    end
end

% Skip some systems and place loggers on their signals instead
allBlocks = find_system(thisParent,'LookUnderMasks','On','FollowLinks','On');
obj.fpiCounter = 1;
obj.skippedString = '# The following systems have been skipped and logged:\n';

obj.logManyBlocks(allBlocks);

% Only use outports that contain obj.requirement!
% Find all the outports in the current requirement
outports = find_system(thisParent,'SearchDepth',1,'LookUnderMasks','On','FollowLinks','On','BlockType','Outport', 'Name', requirement);

end

function logAllSignals(obj, component)
% Log all the "sub"-signals for debugging
thisParent = get(component, 'Parent');
lh=find_system(thisParent, 'FindAll', 'on', 'LookUnderMasks','On','FollowLinks','On','type', 'line');
for i_lh=1:length(lh)
    tmpHandle = get_param(lh(i_lh),'Handle');
    currentName = get_param(lh(i_lh),'Name');
    sourcePort = get(tmpHandle, 'SrcPortHandle');
    
    if sourcePort == -1
        % There is no source port - this component is not connected!
        % Do nothing
        continue
    end
    tmpParent = get(sourcePort, 'Parent');
    tmpParent = get_param(tmpParent, 'Handle');
    sourceType = get(tmpParent, 'BlockType');
    % Criteria to log the signal:
    % - It has not been logged before
    % - It does not contain "<" in signal
    %   name
    % - It is not an inport (inports that
    %   need to be logged are already logged
    %   in testron_prepare_mdl_for_breach.m)
    if ~isempty(currentName) && ...
            ~get(tmpHandle, 'DataLogging') && ...
            isempty(strfind(currentName,'<')) && ...
            ~strcmp(sourceType, 'Inport')
        % Log the block
        set(tmpHandle,'DataLogging',1)
        
    end
end
end




