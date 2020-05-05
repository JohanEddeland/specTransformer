function evChangesToSTL(obj, component)
%FUNCTION   Description goes here.
%

inputNames = obj.getInputNames(component);
[~, ~, ~, ~, FPIstruct1, ~] = obj.getSubStructInfo(inputNames{1});
[~, ~, ~, ~, FPIstruct2, ~] = obj.getSubStructInfo(inputNames{2});
[startDelay3, endDelay3, depth3, modalDepth3, FPIstruct, inputType] = obj.getSubStructInfo(inputNames{3});

duration = evalin('base',FPIstruct1(1).formula);
assert(numel(FPIstruct1) == 1, 'We expect a constant as the duration to evChangesToSTL');

steptime = evalin('base',FPIstruct2(1).formula);
assert(numel(FPIstruct2) == 1, 'We expect a constant as the steptime to evChangesToSTL');

assert(duration >= steptime, 'duration must be larger than tstep. Are the inputs in the wrong order?');

% Calculate the time tolerance
timeToHold = duration/steptime;

% In case the time tolerance is not an integer, it should be rounded down to
% be equivalent to semantics of evChanges block.
timeToHold = floor(timeToHold);

newFPIstruct = struct;
newFPIstruct(1).prereqSignals = {};
newFPIstruct(1).prereqFormula = '';
newFormula = ['(once_[0, ' num2str(timeToHold) '*dt]('];

for tmpIndex=1:length(FPIstruct)-1
    inp3 = FPIstruct(tmpIndex).formula;
    shifted_inp3_one_dt = obj.shiftTimeBackwards(inp3, '1'); 
    
    if strcmp(inputType,'signal_exp')
        formulaToAdd = ['not(' inp3 ' == ' shifted_inp3_one_dt ')'];
    else
        formulaToAdd = ['(' inp3 ' and not(' shifted_inp3_one_dt ')) or (not(' inp3 ') and ' shifted_inp3_one_dt ')'];
    end
    
    newFormula = [newFormula '(' FPIstruct(tmpIndex).prereqFormula ' and ' formulaToAdd ') or']; %#ok<*AGROW>
end

inp3 = FPIstruct(end).formula;
shifted_inp3_one_dt = obj.shiftTimeBackwards(inp3, '1'); 
if strcmp(inputType,'signal_exp')
    lastFormulaToAdd = ['not(' inp3 ' == ' shifted_inp3_one_dt ')'];
else
    lastFormulaToAdd = ['(' inp3 ' and not(' shifted_inp3_one_dt ')) or (not(' inp3 ') and ' shifted_inp3_one_dt ')'];
end

if length(FPIstruct) == 1
    newFormula = [newFormula lastFormulaToAdd];
else
    newFormula = [newFormula '(' FPIstruct(end).prereqFormula ' and ' lastFormulaToAdd ')'];
end
newFormula = [newFormula '))'];
newFPIstruct(1).formula = newFormula;

updateStruct = struct();
updateStruct.startDelay = startDelay3 + timeToHold;
updateStruct.endDelay = endDelay3;
updateStruct.depth = depth3 + 2;
updateStruct.modalDepth = modalDepth3 + 1;
updateStruct.FPIstruct = newFPIstruct;
updateStruct.type = 'phi_exp';
updateStruct.component = component;

obj.updateSubStructAndFormulaString(updateStruct)

end

