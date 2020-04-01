%function updateSubStructAndFormulaString(obj, str, delay, depth, modalDepth, FPIstruct, type, component, setLogSignalName)
function updateSubStructAndFormulaString(obj, inputStruct)
%UPDATESUBSTRUCT Updates the subStruct variable in testronSTL object
%   Appends information in the substruct variable, containing:
%   - startDelay
%   - endDelay (previously "delay")
%   - depth
%   - modalDepth
%   - FPIstruct
%   - type
%   - component
%   - setLogSignalName (optional)
%   Also sets the name of the signal at outportCounter to the correct
%   subName, and increases the subCounter variable.

startDelay = inputStruct.startDelay;
endDelay = inputStruct.endDelay;
depth = inputStruct.depth;
modalDepth = inputStruct.modalDepth;
FPIstruct = inputStruct.FPIstruct;
type = inputStruct.type;
component = inputStruct.component;
if isfield(inputStruct, 'setLogSignalName')
    setLogSignalName = inputStruct.setLogSignalName;
else
    setLogSignalName = 1; % Standard value is 1
end

% Check that the FPIstruct formulas are reasonable
% Each formula should have an equal amount of left and right parentheses
for k = 1:length(FPIstruct)
    thisFormula = FPIstruct(k).formula;
    nLeftPar = length(strfind(thisFormula, '('));
    nRightPar = length(strfind(thisFormula, ')'));
    assert(nLeftPar == nRightPar);
end

% Eliminate the entries in FPIstruct where the prereq is FALSE
% e.g. if prereqSignals are {'sub1==0', 'sub1~=0'}
FPIstruct = checkSatOfPrereqs(FPIstruct);

if setLogSignalName
    ph = get_param(component,'PortHandles');
    outportHandle = ph.Outport;
    set(outportHandle,'Name',['sub' num2str(obj.subCounter)]);
end

blkType = get(component,'BlockType');

poundString = repmat('#', 1, length(blkType) + 4);
poundString = [poundString '\n'];

% Create the string
thisString = [];
for kk = 1:length(FPIstruct)-1
    thisString = [thisString '(' FPIstruct(kk).prereqFormula ' and ' FPIstruct(kk).formula ') or'];
end
if length(FPIstruct) == 1
    thisString = [thisString FPIstruct(end).formula];
else
    thisString = [thisString '(' FPIstruct(end).prereqFormula ' and ' FPIstruct(end).formula ')'];
end

% Update the formulaString
obj.formulaString = [obj.formulaString repmat('\t', 1, obj.subSystemLevel) poundString];
obj.formulaString = [obj.formulaString repmat('\t', 1, obj.subSystemLevel) '# ' blkType ' #\n'];
obj.formulaString = [obj.formulaString repmat('\t', 1, obj.subSystemLevel) poundString];

% Write the formula
obj.formulaString = [obj.formulaString repmat('\t', 1, obj.subSystemLevel)];
if strcmp(type, 'signal_exp') || numel(FPIstruct)>1 || obj.createSubRequirements==0
    obj.formulaString = [obj.formulaString '# '];
end
obj.formulaString = [obj.formulaString obj.requirement '_sub' num2str(obj.subCounter) ' := ' thisString '\n'];

obj.formulaString = [obj.formulaString repmat('\t', 1, obj.subSystemLevel) '# Depth: \t\t' num2str(depth) '\n'];
obj.formulaString = [obj.formulaString repmat('\t', 1, obj.subSystemLevel) '# Modal depth: \t' num2str(modalDepth) '\n'];
obj.formulaString = [obj.formulaString repmat('\t', 1, obj.subSystemLevel) '# Start delay: \t' num2str(startDelay) '\n'];
obj.formulaString = [obj.formulaString repmat('\t', 1, obj.subSystemLevel) '# End delay: \t' num2str(endDelay) '\n'];
obj.formulaString = [obj.formulaString repmat('\t', 1, obj.subSystemLevel) '# Type: \t\t' type '\n\n'];

% TODO: Generalize this!
% If the formula is a phi_exp and it has no prerequisites, change the
% formula name to be defined by a subformula instead. 
if strcmp(type, 'phi_exp') && numel(FPIstruct)==1 && obj.createSubRequirements==1
    for k = 1:numel(FPIstruct)
        FPIstruct(k).formula = [obj.requirement '_sub' num2str(obj.subCounter)];
    end
end

obj.subStruct(obj.subCounter).startDelay = startDelay;
obj.subStruct(obj.subCounter).endDelay = endDelay;
obj.subStruct(obj.subCounter).depth = depth;
obj.subStruct(obj.subCounter).modalDepth = modalDepth;
obj.subStruct(obj.subCounter).FPIstruct = FPIstruct;
obj.subStruct(obj.subCounter).type = type;

obj.subCounter = obj.subCounter + 1;
end

function newFPIstruct = checkSatOfPrereqs(FPIstruct)

newFPIstruct = [];

for k = 1:numel(FPIstruct)
    thisPrereqSignals = FPIstruct(k).prereqSignals;
    sat = checkSatOfPrereq(thisPrereqSignals);
    
    if sat
        % The current entry in FPIstruct is feasible
        % We add it to the new FPIstruct
        if isempty(newFPIstruct)
            newFPIstruct = FPIstruct(k);
        else
            newFPIstruct(end+1) = FPIstruct(k); %#ok<*AGROW>
        end
    end
end

end

function sat = checkSatOfPrereq(prereqSignals)

sat = 1;
for k = 1:numel(prereqSignals)
    thisPrereqSignal = prereqSignals{k};
    [startIdx, endIdx] = regexp(thisPrereqSignal, 'sub\d+');
    
    thisSubSignal = thisPrereqSignal(startIdx:endIdx);
    
    if ~exist(thisSubSignal, 'var')
        % Assign variable value since it has not been assigned yet
        if strfind(thisPrereqSignal, '~=') %#ok<*STRIFCND>
            eval([thisSubSignal ' = 1;']);
        elseif strfind(thisPrereqSignal, '==')
            eval([strrep(thisPrereqSignal, '==', '=') ';']);
        else
            error('This should not be possible!');
        end
    end
    
    % Check if the variable corresponds to the sign
    result = eval(thisPrereqSignal);
    
    if ~result
        sat = 0;
        return
    end
        
end

end