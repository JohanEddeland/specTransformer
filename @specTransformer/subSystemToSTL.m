function subSystemToSTL(obj, subSystem)
%UNTITLED3 Summary of this function goes here
%   Detailed explanation goes here

obj.subSystemLevel = obj.subSystemLevel + 1;

if strcmp(get(subSystem,'Mask'),'on')
    tmpName = get(subSystem,'MaskType');
else
    tmpName = get(subSystem,'Name');
end

thisParent = get(subSystem, 'Parent');
disp(['Diving into ' thisParent '/' tmpName]);
obj.formulaString = [obj.formulaString '# Start of SubSystem (' tmpName ') #\n'];
thisSubsystem = [thisParent '/' get(subSystem,'Name')];
inputNames = get(subSystem, 'InputSignalNames');

% First, clear all the line names in the system
lh=find_system(subSystem, 'FindAll', 'on', 'LookUnderMasks','On','FollowLinks','On','type', 'line');
for i_lh=1:length(lh)
    tmpHan = get_param(lh(i_lh),'Handle');
    currentName = get_param(lh(i_lh),'Name');
    if get(tmpHan,'DataLogging')
        5;
    end
    if isempty(strfind(currentName,'<')) && ~get(tmpHan,'DataLogging')
        % The signal is not a bus signal and it is not being logged -
        % we should clear the signal name
        set_param(lh(i_lh),'Name','');
    end
end

% Find all the outports in the current requirement
outports = find_system(subSystem,'SearchDepth',1,'LookUnderMasks','On','FollowLinks','On','BlockType','Outport');

inputHandles = find_system(subSystem,'SearchDepth',1,'LookUnderMasks','On','FollowLinks','On','BlockType','Inport');
initializeInputValues(inputHandles, inputNames);

ph = get_param(subSystem,'PortHandles');
outportHandle = ph.Outport;

for outportCounter = 1:length(outports)

    component = outports(outportCounter);
    
    obj.parseOutputToSTL(component);
    
    % Find the name of the signal leading to the outport
    portHandles = get(component, 'PortHandles');
    lineHandle = portHandles.Inport;
    signalName = get(lineHandle, 'Name');
    assert(~isempty(regexp(signalName, 'sub\d+', 'once')), 'The outport should be a sub-signal for us to set it outside the subsystem');
    
    set(outportHandle(outportCounter),'Name', signalName);
end

obj.formulaString = [obj.formulaString '# End of SubSystem (' tmpName ') #\n\n'];
obj.subSystemLevel = obj.subSystemLevel - 1;

end

function initializeInputValues(inputHandles, inputNames)

% Initialize values for the inputs
for inpts = 1:length(inputHandles)
    component = inputHandles(inpts);
    portHandles = get(component, 'PortHandles');
    outputLine = portHandles.Outport;
    set(outputLine, 'Name', inputNames{inpts});
end
end