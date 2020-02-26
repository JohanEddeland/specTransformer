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

% Load all the input values to the subSystem
inputValues = struct();
for nNames = 1:length(inputNames)
    try
        [startDelay, endDelay, depth, modalDepth, FPIstruct, type] = ...
            obj.getSubStructInfo(inputNames{nNames});
        inputValues(nNames).startDelay = startDelay;
        inputValues(nNames).endDelay = endDelay;
        inputValues(nNames).depth = depth;
        inputValues(nNames).modaldepth = modalDepth;
        inputValues(nNames).FPIstruct = FPIstruct;
        inputValues(nNames).type = type;
    catch
        % The input name is not a 'sub'-variable
        % It is probably a logged signal (e.g.
        % 'SR_FF43'
        obj.fpiCounter = obj.fpiCounter + 1;
        inputValues(nNames).startDelay = 0;
        inputValues(nNames).endDelay = 0;
        inputValues(nNames).depth = 0;
        inputValues(nNames).modaldepth = 0;
        inputValues(nNames).type = 'signal_exp';
        FPIstruct = struct();
        FPIstruct.prereq = {};
        FPIstruct.formula = [inputNames{nNames} '[t]'];
        inputValues(nNames).FPIstruct = FPIstruct;
    end
end

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
initializeInputValues(obj, inputHandles, inputValues);

ph = get_param(subSystem,'PortHandles');
outportHandle = ph.Outport;

for outportCounter = 1:length(outports)
    
    
    component = outports(outportCounter);
    
    obj.parseOutputToSTL(component);
    
    set(outportHandle(outportCounter),'Name',['sub' num2str(obj.subCounter - 1)]);
end

obj.formulaString = [obj.formulaString '# End of SubSystem (' tmpName ') #\n\n'];
obj.subSystemLevel = obj.subSystemLevel - 1;

end

function initializeInputValues(obj, inputHandles, inputValues)

% Initialize values for the inputs
for inpts = 1:length(inputValues)
    inputStartDelay = inputValues(inpts).startDelay;
    inputEndDelay = inputValues(inpts).endDelay;
    inputDepth = inputValues(inpts).depth;
    inputModalDepth = inputValues(inpts).modaldepth;
    inputFPIstruct = inputValues(inpts).FPIstruct;
    inputType = inputValues(inpts).type;
    
    component = inputHandles(inpts);
    
    updateStruct = struct();
    updateStruct.startDelay = inputStartDelay;
    updateStruct.endDelay = inputEndDelay;
    updateStruct.depth = inputDepth;
    updateStruct.modalDepth = inputModalDepth;
    updateStruct.FPIstruct = inputFPIstruct;
    updateStruct.type = inputType;
    updateStruct.component = component;
    
    obj.updateSubStructAndFormulaString(updateStruct);
end
end