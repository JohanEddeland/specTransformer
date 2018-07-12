%function updateSubStructAndFormulaString(obj, str, delay, depth, modalDepth, FPIstruct, type, component, setLogSignalName)
function updateSubStructAndFormulaString(obj, inputStruct)
%UPDATESUBSTRUCT Updates the subStruct variable in testronSTL object
%   Appends information in the substruct variable, containing:
%   - string
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

str = inputStruct.str;
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

% Check that str is reasonable
% It should have an equal amount of left and right parenthese
nLeftPar = length(strfind(str, '('));
nRightPar = length(strfind(str, ')'));
assert(nLeftPar == nRightPar);

% Check that there are no duplicate FPI strings
[startStrings, endStrings] = obj.getFPIStrings(str);
assert(length(startStrings) == length(unique(startStrings)));
assert(length(endStrings) == length(unique(endStrings)));

obj.subStruct(obj.subCounter).string = str;
obj.subStruct(obj.subCounter).startDelay = startDelay;
obj.subStruct(obj.subCounter).endDelay = endDelay;
obj.subStruct(obj.subCounter).depth = depth;
obj.subStruct(obj.subCounter).modalDepth = modalDepth;
obj.subStruct(obj.subCounter).FPIstruct = FPIstruct;
obj.subStruct(obj.subCounter).type = type;

if setLogSignalName
    ph = get_param(component,'PortHandles');
    outportHandle = ph.Outport;
    set(outportHandle,'Name',['sub' num2str(obj.subCounter)]);
end

blkType = get(component,'BlockType');

poundString = repmat('#', 1, length(blkType) + 4);
poundString = [poundString '\n'];

% Update the formulaString
obj.formulaString = [obj.formulaString repmat('\t', 1, obj.subSystemLevel) poundString];
obj.formulaString = [obj.formulaString repmat('\t', 1, obj.subSystemLevel) '# ' blkType ' #\n'];
obj.formulaString = [obj.formulaString repmat('\t', 1, obj.subSystemLevel) poundString];
obj.formulaString = [obj.formulaString repmat('\t', 1, obj.subSystemLevel) '# sub' num2str(obj.subCounter) ' := ' str '\n'];
obj.formulaString = [obj.formulaString repmat('\t', 1, obj.subSystemLevel) '# Depth: \t\t' num2str(depth) '\n'];
obj.formulaString = [obj.formulaString repmat('\t', 1, obj.subSystemLevel) '# Modal depth: \t' num2str(modalDepth) '\n'];
obj.formulaString = [obj.formulaString repmat('\t', 1, obj.subSystemLevel) '# Start delay: \t' num2str(startDelay) '\n'];
obj.formulaString = [obj.formulaString repmat('\t', 1, obj.subSystemLevel) '# End delay: \t' num2str(endDelay) '\n'];
obj.formulaString = [obj.formulaString repmat('\t', 1, obj.subSystemLevel) '# Type: \t\t' type '\n\n'];

obj.subCounter = obj.subCounter + 1;
end