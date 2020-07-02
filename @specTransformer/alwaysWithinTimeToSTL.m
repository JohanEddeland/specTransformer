function alwaysWithinTimeToSTL(obj, component)
%FUNCTION   Description goes here.
%

inputNames = obj.getInputNames(component);
[startDelay, endDelay, depth, modalDepth, FPIstruct, ~] = obj.getSubStructInfo(inputNames{1});
[~, ~, ~, ~, FPIstruct2, ~] = obj.getSubStructInfo(inputNames{2});
[~, ~, ~, ~, FPIstruct3, ~] = obj.getSubStructInfo(inputNames{3});

inp2 = FPIstruct2(1).formula;
startTimeIsVar = evalin('base', ['exist(''' inp2 ''', ''var'');']);
if startTimeIsVar
    startTime = evalin('base', inp2);
    % If the parameter does not already exist in the parameter string, add
    % it!
    if ~contains(obj.paramString, [inp2 ' ='])
        obj.paramString = [obj.paramString inp2 ' = ' num2str(startTime) ', '];
    end
else
    startTime = eval(inp2);
end
assert(numel(FPIstruct2) == 1, 'We expect a constant as the startTime to alwaysWithinTimeToSTL');

inp3 = FPIstruct3(1).formula;
endTimeIsVar = evalin('base', ['exist(''' inp3 ''', ''var'');']);
if endTimeIsVar
    endTime = evalin('base', inp3);
    % If the parameter does not already exist in the parameter string, add
    % it!
    if ~contains(obj.paramString, [inp3 ' ='])
        obj.paramString = [obj.paramString inp3 ' = ' num2str(endTime) ', '];
    end
else
    endTime = eval(inp3);
end
assert(numel(FPIstruct3) == 1, 'We expect a constant as the endTime to alwaysWithinTimeToSTL');

assert(endTime > startTime, 'endTime must be larger than startTime. Are the inputs in the wrong order?');

for tmpIndex=1:length(FPIstruct)
    inp1 = FPIstruct(tmpIndex).formula;
    % Future version (alw_[startTime, endTime](input))
    FPIstruct(tmpIndex).formula = ['(alw_[' inp2 ', ' inp3 '](' inp1 '))']; %#ok<*AGROW>
    
    % Past version (hist_[obj.endTime - endTime, obj.endTime - startTime](input)
    % FPIstruct(tmpIndex).formula = ['(hist_[' num2str(obj.endTime - endTime) ', ' num2str(obj.endTime - startTime) '](' inp1 '))']; %#ok<*AGROW>
end

updateStruct = struct();
updateStruct.startDelay = startDelay + endTime;
updateStruct.endDelay = endDelay;
updateStruct.depth = depth + 1;
updateStruct.modalDepth = modalDepth + 1;
updateStruct.FPIstruct = FPIstruct;
updateStruct.type = 'phi_exp';
updateStruct.component = component;

obj.updateSubStructAndFormulaString(updateStruct)

end

